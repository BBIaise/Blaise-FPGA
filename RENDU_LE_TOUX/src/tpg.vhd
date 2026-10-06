----------------------------------------------------------------------------------
-- Module Name: tpg - Behavioral
-- Generateur de motif de test (remplace l'IP Xilinx v_tpg) : 
-- balaie une image 640x480 en barres de couleurs, avec un carre qui
-- se deplace horizontalement d'une image a l'autre en clignotant (PL-IP-001).
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tpg is
    generic (
        img_width       : integer := 640;   -- largeur de l image
        img_height      : integer := 480;   -- hauteur de l image
        square_size     : integer := 20;    -- taille du carre qui se deplace
        square_y        : integer := 220;   -- position verticale fixe du carre
        square_step     : integer := 2      -- deplacement horizontal par image
        );
    port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        t_ready   : in  std_logic;
        t_valid   : out std_logic;
        t_data    : out std_logic_vector(23 downto 0)
        );
end tpg;

architecture Behavioral of tpg is

    signal x_count   : std_logic_vector(9 downto 0) := (others => '0'); -- compteur de pixel horizontal
    signal y_count   : std_logic_vector(9 downto 0) := (others => '0'); -- compteur de pixel vertical
    signal square_x  : std_logic_vector(9 downto 0) := (others => '0'); -- memoire de la position du carre (memorise le pixel du bord gauche du carre)
    signal t_valid_i : std_logic := '0';    -- un signal t_valid_interne(i) pour pouvoir manipuler t_valid qui est un port out
    
    signal bar_color    : std_logic_vector(23 downto 0);
    signal bar_position : std_logic_vector(6 downto 0) := (others => '0');  -- position de la barre de 0 a 79
    signal bar_number   : std_logic_vector(2 downto 0) := (others => '0');  -- numero de la barre, 8 barres pour 8 couleurs
    signal frame_count  : std_logic_vector(4 downto 0) := (others => '0');  -- compteur d image pour faire clignoter le carre
    signal blink        : std_logic := '1';

    attribute mark_debug : string;
    attribute mark_debug of x_count   : signal is "true";
    attribute mark_debug of y_count   : signal is "true";
    attribute mark_debug of square_x  : signal is "true";
    attribute mark_debug of t_valid_i : signal is "true";

begin

    process(clk, reset)
    begin
    
        -- apres un reset on met tous les compteurs et les positions a 0 ainsi que le t_valid_i
        if reset = '1' then
            x_count   <= (others => '0');
            y_count   <= (others => '0');
            square_x  <= (others => '0');
            
            t_valid_i <= '0'; 
            
            bar_position    <= (others => '0');
            bar_number      <= (others => '0');
            frame_count     <= (others => '0');
            blink           <= '1'; -- blink initialise a 1 pour que le carre soit visible au debut

        elsif rising_edge(clk) then
            
            -- Sur chaque coup d horloge on verifie le handshake
            -- Cette logique permet 2 possibilitees : si t_valid_i = 0, on peut preparer la prochaine donnee
            --                                        si t_ready = 1, le controlleur vga prend deja la donnee actuelle, on peut preparer la prochaine
            if t_valid_i = '0' or t_ready = '1' then
                t_valid_i <= '1';   -- on passe le t_valid_i a 1
                
                -- Si le compteur de pixel horizontal atteint la derniere colonne de pixel elle retourne a 0
                if x_count = img_width - 1 then
                    x_count         <= (others => '0');
                    bar_position    <= (others => '0');     -- quand on est en fin de ligne les positions et numero des barres retournent a 0
                    bar_number      <= (others => '0');     -- de cette maniere les barres de couleurs sont droites

                    -- SI le compteur de pixel vertical atteint la derniere ligne de pixel elle retourne a 0
                    if y_count = img_height - 1 then
                        y_count <= (others => '0');
                        frame_count <= frame_count + 1;
                        
                        -- Les 2 compteurs de pixel arrive sur la fin d une image, les prochaines lignes s executeront 60 fois par secondes
                        
                        -- Si le compteur d image atteint 14, a 60 images/s cela fait 0.25s
                        if frame_count = 14 then
                            frame_count <= (others => '0'); -- je remet le compteur d image a 0
                            blink       <= not blink;       -- je fais clignoter le carre
                        end if;
                        
                        -- la position du carre se fait avec le cote gauche, on verifie donc qu il ne sorte pas de l image
                        -- et si il arrive au bout on remet sa position en debut de ligne
                        if square_x >= (img_width - square_size - square_step) then
                            square_x <= (others => '0');
                        else
                            square_x <= square_x + square_step; -- si le carre n est pas au bord d une image on le fait avancer d un pas
                        end if;

                    else
                        y_count <= y_count + 1; -- on avance a la ligne suivante 
                    end if;

                else
                    x_count <= x_count + 1; -- on avance a la colonne suivante
                    
                    -- la barre atteint la position 79 (640 / 8 = 80 pixel, les positions vont donc de 0 a 79)
                    if bar_position = "1001111" then            -- 79 en binaire
                        bar_position    <= (others => '0');     -- on remet la position de la barre a 0
                        bar_number      <= bar_number + 1;      -- on incremente bar_number pour changer la couleur
                    else
                        bar_position <= bar_position + 1;
                    end if;

                end if;

            end if;
            
        end if;
        
    end process;
    
    -- on associe une couleur a chaque numero de bar_number de 0 a 6 avec le dernier cas en noir
    with bar_number select bar_color <=
        x"FFFFFF" when "000",   -- blanc
        x"FFFF00" when "001",   -- jaune
        x"00FFFF" when "010",   -- cyan
        x"00FF00" when "011",   -- vert
        x"FF00FF" when "100",   -- magenta
        x"FF0000" when "101",   -- rouge
        x"0000FF" when "110",   -- bleu
        x"000000" when others;  -- noir
    
    t_valid <= t_valid_i;   -- on recopie le signal interne sur le port out

    -- Couleur du pixel courant : couleur inverse si dans la position du carre et que le carre est visible
    -- de la couleur d une barre colore sinon.
    t_data <= (not bar_color) when (blink = '1'
                                and x_count >= square_x and x_count < square_x + square_size
                                and y_count >= square_y and y_count < square_y + square_size)
          else bar_color;

end Behavioral;
