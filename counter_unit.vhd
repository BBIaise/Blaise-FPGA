library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- On fait le même compteur que pour le TP précédent 
entity counter_unit is
    generic (
        counter_max : positive := 199999999
    );
    port (
        clk         : in std_logic;
        resetn      : in std_logic;
        end_counter : out std_logic
    );
end counter_unit;

architecture behavioral of counter_unit is

    signal counter : std_logic_vector(27 downto 0);

begin
    
    process(clk, resetn)
    begin
        if (resetn = '1') then
            counter <= (others => '0'); -- Si resetn est à 1, on remet le compteur à 0
        elsif rising_edge(clk) then
            if (counter = counter_max) then -- sinon si sur un front d'horloge le counter est égal à son max, on le remet à 0
                counter <= (others => '0');
            else
                counter <= counter + 1; -- sinon on l'incrémente de 1
            end if;
        end if;
    end process;
    -- On passe end_counter à 1 quand le compteur est terminé
    end_counter <= '1' when counter = counter_max else '0';

end behavioral;
