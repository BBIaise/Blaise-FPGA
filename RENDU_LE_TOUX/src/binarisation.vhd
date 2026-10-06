----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.10.2026 12:14:28
-- Design Name: 
-- Module Name: binarisation - Behavioral
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity binarisation is
    Generic (
            seuil : integer := 8   -- valeur de comparaison, reglable
            );
    Port ( 
            s_t_valid : in STD_LOGIC;
            s_t_data : in STD_LOGIC_VECTOR (7 downto 0);
            m_t_ready : in STD_LOGIC;
            s_t_ready : out STD_LOGIC;
            m_t_valid : out STD_LOGIC;
            m_t_data : out STD_LOGIC_VECTOR (7 downto 0)
            );
end binarisation;

architecture Behavioral of binarisation is

begin

    -- handshake
    m_t_valid <= s_t_valid;
    s_t_ready <= m_t_ready;

    -- la specification demande 0 en dessous du seuil, 1 au dessus ou egal
    -- je sors 0xFF plutot que 1 pour rester sur 8 bits et obtenir du blanc a l ecran
    m_t_data <= (others => '1') when unsigned(s_t_data) >= seuil
                else (others => '0');


end Behavioral;
