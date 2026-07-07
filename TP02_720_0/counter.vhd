library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- Implémentation des 4 ports physiques : Une horloge(clk), 2 boutons (reset & restart)
-- et counter_end(la sortie vers la LED)
entity counter_unit is
    port (
        clk         : in std_logic;
        reset_btn   : in std_logic;
        restart     : in std_logic;
        counter_end : out std_logic
    );
end counter_unit;

architecture behavioral of counter_unit is

    constant counter_max        : positive := 199999999;
    signal counter              : std_logic_vector(27 downto 0); -- compteur réglé sur 28 bits
    signal counter_end_intern   : std_logic; -- un indicateur que le compteur a finit sa série
    signal led                  : std_logic; -- il mémorise l'état de la LED
    signal resetn               : std_logic; -- Un reset inversé par rapport au bouton

begin

    resetn <= not reset_btn; 

    process(clk, resetn)
    begin
        if (resetn = '0') then
            counter <= (others => '0'); -- others met tous les bits à 0 sans connaitre leur nombre

        elsif rising_edge(clk) then
            if (restart = '1') then 
                counter <= (others => '0'); -- restart met tous les bits à 0
            elsif counter = counter_max then 
                counter <= (others => '0'); -- counter_max met également tous les bits à 0
            else
                counter <= counter + 1; -- si le bouton restart n'ai pas appuyer et que le compteur n'a pas atteint son maximum, le compteur continue de s'incrémenter
            end if;

        end if;
    end process;

    counter_end_intern <= '1' when counter = counter_max else '0';
    -- équation hors process, elle est donc vérifié tous le temps et pas seulement sur les fronts d'horloges
    -- counter_end_intern permet de stocker et d'utiliser la fin du compteur
    
    
    process(clk, resetn)
    begin
        if (resetn = '0') then
            led <= '0';
        elsif rising_edge(clk) then
            if (restart = '1') then
                led <= '0'; -- si le bouton restart est à 1, la led s'éteint
            elsif (counter_end_intern = '1') then
                led <= not led; -- si le compteur se finit on inverse l'état de la LED -> clignotement
            end if;
        end if;
    end process;

    counter_end <= led;

end behavioral;