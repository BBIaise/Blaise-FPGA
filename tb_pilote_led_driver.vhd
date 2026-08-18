library ieee;
use ieee.std_logic_1164.all;

entity tb_pilote_led_driver is
end tb_pilote_led_driver;

architecture behavioral of tb_pilote_led_driver is

    signal clk    : std_logic := '0';
    signal resetn : std_logic := '0';
    signal btn0   : std_logic := '0';
    signal btn1   : std_logic := '0';
    signal led0_r : std_logic;
    signal led0_g : std_logic;
    signal led0_b : std_logic;

    -- Horloge
    constant hp     : time := 5 ns;
    constant period : time := 2*hp;

    component pilote_led_driver
        generic (
            counter_max : positive
        );
        port (
            clk    : in  std_logic;
            resetn : in  std_logic;
            btn0   : in  std_logic;
            btn1   : in  std_logic;
            led0_r : out std_logic;
            led0_g : out std_logic;
            led0_b : out std_logic
        );
    end component;

begin

    dut : pilote_led_driver
        generic map (
            counter_max => 3
        )
        port map (
            clk    => clk,
            resetn => resetn,
            btn0   => btn0,
            btn1   => btn1,
            led0_r => led0_r,
            led0_g => led0_g,
            led0_b => led0_b
        );
    
    -- Horloge signal carre
    process
    begin
        wait for hp;
        clk <= not clk;
    end process;

    process
    begin
        -- reset au début pour initialiser le système : tout doit être éteint
        resetn <= '1';
        wait for period;
        resetn <= '0';
        wait for period*4; -- j'attends quelques periodes avant de verifier qu'aucune leds ne soit allume
        assert (led0_r = '0' and led0_g = '0' and led0_b = '0')
            report "Erreur reset : les LED ne sont pas eteintes"
            severity error;
        
        --50ns
        
        -- scenario 1 : enchainement de couleur
        btn0 <= '1';        -- couleur bleu
        wait for period*2;
        
        -- Je test une premiere fois la led bleu alors que led_blink n'a pas encore finit
        -- sa periode, la couleur ne devrait donc pas changer
        assert (led0_b = '0' and led0_g = '0')
            report "Erreur : la led bleu s'allume avant la fin de la periode précédente"
            severity error;
        wait for period*6;
        -- Avec 6 periodes de plus on devrait tomber sur un front montant de led_blink
        -- et par consequent, la led bleue devrait s'allumer
        assert (led0_b = '1' and led0_g = '0')
            report "Erreur : la led bleu ne s'allume pas"
            severity error;
           
        -- 130ns
        
        -- scenario 2 : changement de couleur rapide puis ne rien toucher
        wait for period*3;
        btn0 <= '0';
        wait for period;
        btn1 <= '1';        -- demande couleur verte
        wait for period;
        btn0 <= '1';        -- couleur verte mise en attente
        wait for period;
        btn0 <= '0';
        wait for period;
        btn1 <= '0';        -- demande bleu
        wait for period;
        btn0 <= '1';        -- couleur bleu mise en attente
        wait for period;
        btn0 <= '0';
        wait for period;
        btn1 <= '1';        -- demande couleur verte
        wait for period;
        btn0 <= '1';        -- couleur verte mise en attente
        
        -- A la fin de ce cycle on peut tester la couleur qui est censé encore etre sur le bleu du scenario 1
        assert (led0_b = '1' and led0_g = '0')
            report "Erreur : la led a changer de couleur trop tot"
            severity error;
        
        -- 240ns
        
        wait for period*5; -- je me cale sur un front montant de led_blink
        -- 290ns
        assert (led0_b = '0' and led0_g = '1')
            report "Erreur : la led verte n'est pas allume"
            severity error;
        
        wait for period*8; -- j'attends une periode complete
        -- 370ns
        assert (led0_b = '1' and led0_g = '0')
            report "Erreur : la led n'est pas bleue"
            severity error;
        
        wait for period*8; -- j'attends une periode complete
        -- 450ns
        assert (led0_b = '0' and led0_g = '1')
            report "Erreur : la led n'est pas verte"
            severity error;

       
        wait;
    end process;

end behavioral;
