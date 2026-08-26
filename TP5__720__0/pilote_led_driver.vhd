library ieee;
use ieee.std_logic_1164.all;

entity pilote_led_driver is
    generic (
        counter_max : positive := 99999999 -- j'ai choisie un compteur maximum assez haut afin de pouvoir voir le clignotement à l'oeil nu
    );
    port (
        clkA        : in  std_logic;
        clkB        : in std_logic;     -- j'ajoute une deuxieme horloge
        resetn      : in  std_logic;
        led0_r      : out std_logic;
        led0_g      : out std_logic;
        led0_b      : out std_logic;
        led1_r      : out std_logic;
        led1_g      : out std_logic;
        led1_b      : out std_logic
    );
end pilote_led_driver;

architecture behavioral of pilote_led_driver is

    component LED_driver
        generic (
            counter_max : positive
        );
        port (
            clk        : in  std_logic;
            resetn     : in  std_logic;
            color_code : in  std_logic_vector(1 downto 0);
            update     : in  std_logic;
            led0_r     : out std_logic;
            led0_g     : out std_logic;
            led0_b     : out std_logic;
            end_cycle  : out std_logic
        );
    end component;
    
    component compteur_10
        generic ( max_10 : positive := 10); -- avec un compteur jusqu'a 10 la led change de couleur avant d effectuer sont dernier clignotement, je prend donc un compteur 11
        
        port (
            clk         : in std_logic;
            resetn      : in std_logic;
            end_cycle   : in std_logic;
            update      : out std_logic;
            color_code  : out std_logic_vector(1 downto 0)
            );
    end component;
            
    
    -- ajout des signaux de compteur_10 afin d'instancier les composants
    signal end_cycle   : std_logic;
    signal update      : std_logic;
    signal color_code  : std_logic_vector(1 downto 0);
    
    -- pour la Q10 on doit poser des sondes sur certain signaux interressant a tester
    -- je test donc les signaux de LED0_driver et les sortie de LED1_driver
    attribute mark_debug : string;
    attribute mark_debug of update      : signal is "true";
    attribute mark_debug of color_code  : signal is "true";
    attribute mark_debug of end_cycle   : signal is "true";
    attribute mark_debug of led0_r : signal is "true";
    attribute mark_debug of led0_g : signal is "true";
    attribute mark_debug of led0_b : signal is "true";
    
    attribute mark_debug of led1_r : signal is "true";
    attribute mark_debug of led1_g : signal is "true";
    attribute mark_debug of led1_b : signal is "true";
        
begin

    -- Instanciation de LED0 et LED1
    LED0_driver : LED_driver
        generic map (
            counter_max => counter_max
        )
        port map (
            clk        => clkA,     -- j'instancie mes drivers avec une horloge differente
            resetn     => resetn,
            color_code => color_code,     
            update     => update,
            led0_r     => led0_r,
            led0_g     => led0_g,
            led0_b     => led0_b,
            end_cycle  => end_cycle       
        );
        
    LED1_driver : LED_driver
        generic map (
            counter_max => counter_max
        )
        port map (
            clk        => clkB,
            resetn     => resetn,
            color_code => color_code,
            update     => update,
            led0_r     => led1_r,   -- j'instancie les leds pilote par LED_driver a la led1 pour pouvoir piloter les 2 leds
            led0_g     => led1_g,
            led0_b     => led1_b,
            end_cycle  => open      -- je laisse ce port ouvert car seul le end_cycle de LED0 doit compter
        );
    
    u_compteur_10 : compteur_10
        -- je n''instancie pas max_10 car je l'ai deja defini dans le composant
        port map (
            clk         => clkA,    -- le compteur est relie a LED_driver, je lui instancie donc la meme horloge
            resetn      => resetn,
            end_cycle   => end_cycle,
            update      => update,
            color_code  => color_code
            );    
    
        
   
end behavioral;
