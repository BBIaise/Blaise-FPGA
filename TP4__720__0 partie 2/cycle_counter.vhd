library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity cycle_counter is
    generic (
        counter_max : positive := 5
    );
    port (
        clk         : in std_logic;
        resetn      : in std_logic;
        led_blink   : out std_logic;  -- le signal qui fait basculer les leds (allumï¿½/ï¿½tteinte)
        end_cycle   : out std_logic   -- fin d'un clignotement complet
    );
end cycle_counter;

architecture behavioral of cycle_counter is

    component counter_unit
        generic (
            counter_max : positive
        );
        port (
            clk         : in std_logic;
            resetn      : in std_logic;
            end_counter : out std_logic
        );
    end component;

    signal end_counter : std_logic;
    signal blink       : std_logic;  -- blink va garder l'ï¿½tat de la led pour le transmettre ï¿½ led_blink
    signal cycle       : std_logic;
    
begin
    
    -- On instancie les signaux
    u_counter_unit : counter_unit
        generic map (
            counter_max => counter_max
        )
        port map (
            clk         => clk,
            resetn      => resetn,
            end_counter => end_counter
        );

    process(clk, resetn)
    begin
        if (resetn = '1') then  -- Si reset -> compteur a 0 et led eteinte
            blink <= '0';
            cycle <= '0';
        elsif rising_edge(clk) then -- si restart -> compteur a 0 et led eteinte
            cycle <= blink; -- cycle mémorise blink avec un front d'horloge de retard
            if (end_counter = '1') then -- si le premier compteur se termine on incremente le compteur de blink et on allume la led
                blink <= not blink;
            end if;
        end if;
    end process;

    -- On envoit l'etat de blink dans led_blink pour change l'etat de la led en sortie
    led_blink <= blink;
    end_cycle <= cycle and not blink; -- comme cycle et blink differe d'un front d'horloge on en profite pour passer end_cycle a 1 lorsqu'ils sont different
end behavioral;
