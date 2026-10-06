----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.09.2026 12:31:42
-- Design Name: 
-- Module Name: harris filter
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
--
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
-- library UNISIM;
-- use UNISIM.VComponents.all;

-- je reprends l architecture de gaussian_filter
entity harris_filter is
    Generic ( 
            img_width : integer := 640;
            img_height : integer := 480
            );
    Port ( 
            clk         : in STD_LOGIC;
            reset       : in STD_LOGIC;
            s_t_valid   : in STD_LOGIC;
            s_t_ready   : out STD_LOGIC;
            s_t_data    : in STD_LOGIC_VECTOR(7 downto 0);
            m_t_valid   : out STD_LOGIC;
            m_t_ready   : in STD_LOGIC;
            m_t_data    : out STD_LOGIC_VECTOR(7 downto 0)
           );
end harris_filter;

architecture Behavioral of harris_filter is
    
    -- je cree un tableau de la largeur de mon image avec un octet dans chaque case
    type tab_img is array (0 to img_width - 1) of std_logic_vector(7 downto 0);
    
    -- je declare les 2 line buffer (objets du tableau)
    -- line_buffer1 contiendra le pixel de la ligne precedente
    -- et line_buffer2 contiendra le pixel d il y a 2 ligne
    -- de cette maniere on aura line_buffer1 qui contiendra le pixel de la ligne precedente
    -- line_buffer2 qui contiendra le pixel d il y a 2 lignes
    -- et s_t_data qui contiendra le pixel actuel
    signal line_buffer1, line_buffer2 : tab_img := (others => (others => '0'));
    
    -- fenetre de pixel 3x3
    -- j ai conserve les pixel de coin pour la clarete du code mais il ne servent a rien ici
    signal px00, px01, px02 : std_logic_vector(7 downto 0);
    signal px03, px04, px05 : std_logic_vector(7 downto 0);
    signal px06, px07, px08 : std_logic_vector(7 downto 0);
    
    -- notre signal qui possedera le calcul pour chaque pixel d une fenetre 3x3
    -- sur 12 bits car la somme du filtre de convolution vaut 0+(-1)+0 + (-1)+4+(-1) + 0+(-1)+0 = 0
    -- le minimum est -4 et le maximum est 4 on a donc une plage de 8 valeurs et 8x255 = 2040
    -- on va garder les 12 bits ils peuvent contenir notre donnee et on essayed de ne pas changer le format du filtre gaussien
    -- 12 bits -> 4096 valeur
    
    -- de plus je passe le calcul un signed
    signal sum : signed(11 downto 0);
    
    -- je declare 2 compteurs de position pour determiner si on se situe sur un bord ou non
    -- je passe les compteur en unsigned
    signal pos_dark_x, pos_dark_y : unsigned(9 downto 0) := (others => '0');
    
    -- j utilise un signal de valeur absolu pour la partie negative de mon filtre de convolution
    signal abs_sum : signed(11 downto 0);    
begin

    -- Dans un process les affectations sont differees jusqu a la fin
    -- les line_buffer recevront bien les anciennes version de l image et pas celle modifie
    process(clk, reset)
        begin
        
        if reset = '1' then
            pos_dark_x <= (others => '0');
            pos_dark_y <= (others => '0');
        elsif rising_edge(clk) then
        
            -- on verifie le handshake
            if s_t_valid = '1' and m_t_ready = '1' then
                
                -- chaque case va prendre la valeur de sa case voisine a gauche
                for i in img_width -1 downto 1 loop
                    line_buffer1(i) <= line_buffer1(i-1);                 
                    end loop;

                line_buffer1(0) <= s_t_data;    -- line_buffer1 prend la valeur de s_t_data   

                for i in img_width -1 downto 1 loop
                    line_buffer2(i) <= line_buffer2(i-1);
                    end loop;  
                    
                line_buffer2(0) <= line_buffer1(img_width -1);  -- line_buffer2 prends la valeur de line_buffer1
                -- de cette maniere on se retrouve avec s_t_data qui a le pixel de la ligne courante
                -- line_buffer1 qui a le pixel de la ligne precedente
                -- et le line_buffer2 qui aura le pixel d il y a 2 lignes                
                
                -- la fenetre : chaque pixel prend la valeur suivante avec les line buffer et le pixel courant en bout de chaine
                px00 <= px01;   px01 <= px02;   px02 <= line_buffer2(img_width-1);
                px03 <= px04;   px04 <= px05;   px05 <= line_buffer1(img_width-1);
                px06 <= px07;   px07 <= px08;   px08 <= s_t_data;
                
                -- Si pos_dark est a la limite de la ligne
                if pos_dark_x = img_width -1 then
                    pos_dark_x <= (others => '0');  -- je remet pos_dark_x a 0
                    if pos_dark_y = img_height -1 then  -- Si pos_dark_y est a la limite de l'image
                        pos_dark_y <= (others => '0');  -- je remet pos_dark_y a 0
                    else
                        pos_dark_y <= pos_dark_y +1;    -- sinon j incremente la pos_dark pour arriver au bord de l image
                    end if;
                else
                    pos_dark_x <= pos_dark_x +1;    -- sinon j incremente la pos_dark pour arriver au bord de la ligne
                end if;
                    
            end if;
        end if;
        
    end process;
    
    -- je fais en sorte d'avoir des resultats entrant dans un signal de 12 bits
    -- je rajoute des 0 a droite pour effectuer les divisions en respectant le filtre de convolution  
    -- et des 0 a gauche pour que ca rentre dans un signal de 12 bits
    -- et j ajoute des (-) pour les coefficients -1 
    -- comme sum est devenu un signed je fais de meme pour les calculs et le resize remplace l'ajout des 0 complementaires
    sum <=    signed(resize(unsigned(px04) & "00", 12))     -- centre x 4
            - signed(resize(unsigned(px01), 12))            -- voisin du dessus
            - signed(resize(unsigned(px03), 12))            -- voisin de gauche
            - signed(resize(unsigned(px05), 12))            -- voisin de droite
            - signed(resize(unsigned(px07), 12));           -- voisin du dessous
    
    -- on calcule la valeur absolue de sum pour la tansmettre a abs_sum
    abs_sum <= abs(sum);
    -- Je prends la somme des intensites de chaque pixel et je la divise par 16 en decalant le resultat de 4 bits
    -- Sur les deux premieres lignes et les deux premieres colonnes, la fenetre 3x3
    -- n'a pas de voisinage complet (fenetre a cheval sur deux lignes) : on sort du noir plutot qu'un resultat faux.
    m_t_data <= (others => '0')     when (pos_dark_x < 4 or pos_dark_y < 4)
           else (others => '1')     when abs_sum > 255
           else std_logic_vector(abs_sum(7 downto 0));
                                  
                                  
    m_t_valid <= s_t_valid;          
    s_t_ready <= m_t_ready;         
        
end Behavioral;
