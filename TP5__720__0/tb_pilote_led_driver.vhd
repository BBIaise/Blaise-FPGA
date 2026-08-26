library ieee;
use ieee.std_logic_1164.all;

entity tb_pilote_led_driver is
end tb_pilote_led_driver;

architecture behavioral of tb_pilote_led_driver is

    signal clkA   : std_logic := '0';
    signal clkB   : std_logic := '0';
    signal resetn : std_logic := '0';
    signal led0_r : std_logic;
    signal led0_g : std_logic;
    signal led0_b : std_logic;
    signal led1_r : std_logic;
    signal led1_g : std_logic;
    signal led1_b : std_logic;

    -- Horloge clkA
    constant hpA     : time := 2 ns;
    constant periodA : time := 2*hpA;
    
    -- Horloge clkB
    constant hpB     : time := 10 ns;
    constant periodB : time := 2*hpB;
    
    -- constante period, j'ai recré une periode de 10ns pour ne pas avoir à changer mes tests
    constant period  : time := 10 ns;

    component pilote_led_driver
        generic (
            counter_max : positive
        );
        port (
            clkA   : in  std_logic;
            clkB   : in std_logic;
            resetn : in  std_logic;
            led0_r : out std_logic;
            led0_g : out std_logic;
            led0_b : out std_logic;
            led1_r : out std_logic;
            led1_g : out std_logic;
            led1_b : out std_logic
        );
    end component;

begin

    dut : pilote_led_driver
        generic map (
            counter_max => 3
        )
        port map (
            clkA   => clkA,
            clkB   => clkB,
            resetn => resetn,
            led0_r => led0_r,
            led0_g => led0_g,
            led0_b => led0_b,
            led1_r => led1_r,
            led1_g => led1_g,
            led1_b => led1_b
        );
    
    -- Horloge signal carre
    -- un process par horloge 
    process
    begin
        wait for hpA;
        clkA <= not clkA;
    end process;
    
    process
    begin
        wait for hpB;
        clkB <= not clkB;
    end process;

    process
    begin
    
        -- reset au début pour initialiser le système
        resetn <= '1';
        wait for period;
        resetn <= '0';
        
        wait for period*9; -- 100ns
        -- led0 et led1 doivent être allumées en rouge
        assert( led0_r = '1' and led1_r = '1' and led0_g = '0' and led1_g = '0' and led0_b = '0' and led1_b = '0')
            report "Erreur : 90ns les leds rouges ne sont pas correctement allumées"
            severity error;
        
        wait for period*34; -- dans la simulation une sequence de counter_10 prends 800ns 
        -- 440n
        -- led0 et led1 doivent être allumées en bleu
        assert( led0_r = '0' and led1_r = '0' and led0_g = '0' and led1_g = '0' and led0_b = '1' and led1_b = '1')
            report "Erreur : 440ns les leds bleues ne sont pas correctement allumées"
            severity error;  
        
        wait for period*29; -- 730ns
        -- led0 et led1 doivent être allumées en vert
        assert( led0_r = '0' and led1_r = '0' and led0_g = '1' and led1_g = '1' and led0_b = '0' and led1_b = '0')
            report "Erreur : 730ns les leds vertes ne sont pas correctement allumées"
            severity error;  
        
        wait;
    end process;

end behavioral;
