----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.09.2026 10:27:56
-- Design Name: 
-- Module Name: rgb_to_gray - Behavioral
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
use IEEE.std_logic_UNSIGNED.ALL;    -- bibliothèque pour pouvoir additionner (+)

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rgb_to_gray is
    Port ( s_t_valid    : in STD_LOGIC;
           s_t_data     : in STD_LOGIC_VECTOR(23 downto 0); -- entree du signal en RGB
           m_t_ready    : in STD_LOGIC;
           s_t_ready    : out STD_LOGIC;
           m_t_valid    : out STD_LOGIC;
           m_t_data     : out STD_LOGIC_VECTOR(7 downto 0)  -- sortie du signal en ton de gris (luminance)
           );
end rgb_to_gray;

architecture Behavioral of rgb_to_gray is
    
    -- signaux contenant les couleurs du flux video
    signal r, g, b  : std_logic_vector(7 downto 0);
    signal gray     : std_logic_vector(10 downto 0);
    
begin
    
    -- handshake
    m_t_valid <= s_t_valid; -- valid descend
    s_t_ready <= m_t_ready; -- ready remonte
    
    -- affectation de chaque tranche de couleur au bon signal    
    r <= s_t_data(23 downto 16);
    g <= s_t_data(15 downto 8);
    b <= s_t_data(7 downto 0);
    
    -- pour obtenir des nuances de gris a partir de couleur RGB on va appliquer une formule pondere
    -- l'oeil humain est beaucoup plus sensible au vert qu au rouge et encore moins au bleu
    -- je vais donc mutliplier la valeur du rouge par 2 celle du vert par 5 et garder la valeur du bleu tel quel
    -- soit : gray = 2Red + 5Green + 1Blue
    -- je passe mes signaux sur 11 bits car si chaque intensite est a 255 on obtient 2040
    -- 11 bits peuvent contenir 2048 valeurs
    
    gray <=   ("00"  & r & '0')     -- en ajoutant un 0 a la fin d'un signal binaire on le multiplie par 2
            + ('0'   & g & "00")    -- deux 00 pour un x4
            + ("000" & g)           -- comme on voulait x5 on en additionne un en plus
            + ("000" & b);          -- et on additionne une fois le bleu pour finir
    
    -- je transmais ensuite la donnee dans mon signal de sortie en divisant par 8 soit decaler de 3 bits a droite
    m_t_data <= gray(10 downto 3);


end Behavioral;
