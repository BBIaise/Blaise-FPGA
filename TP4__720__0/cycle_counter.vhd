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
        led_blink   : out std_logic  -- le signal qui fait basculer les leds (allumé/étteinte)
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
    signal blink       : std_logic;  -- blink va garder l'état de la led pour le transmettre à led_blink

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
        if (resetn = '1') then  -- Si reset -> compteur à 0 et led éteinte
            blink <= '0';
            
        elsif rising_edge(clk) then -- si restart -> compteur à 0 et led éteinte
            if (end_counter = '1') then -- si le premier compteur se termine on incrémente le compteur de blink et on allume la led
                blink <= not blink;
            end if;
        end if;
    end process;
    
    -- On envoit l'état de blink dans led_blink pour changé l'état de la led en sortie
    led_blink <= blink;
end behavioral;
