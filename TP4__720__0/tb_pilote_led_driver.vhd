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

        -- Scenario 1 : btn0 = 1, btn1 = 0 -> la led bleu doit s'allumer
        btn0 <= '1';
        wait for period;
        btn0 <= '0';
        wait for period; -- je cale la verification sur un clignotement de la led bleue
        assert (led0_r = '0' and led0_g = '0' and led0_b = '1')
            report "Erreur scenario 1 : la led bleu de clignote pas"
            severity error;

        -- scenario 2 : btn0 = 0, btn1 = 1 -> rien ne doit changer
        btn1 <= '1';
        wait for period; -- je cale la verification sur un clignotement de la led bleue
        assert (led0_r = '0' and led0_g = '0' and led0_b = '1')
            report "Erreur scenario 2 : la led bleu ne clignote plus"
            severity error;

        -- scenario 3 : btn0 = 1, btn1 est reste a 1 -> changement de couleur
        btn0 <= '1';
        wait for period;
        btn0 <= '0';
        wait for period*4; -- je cale la verification sur un clignotement du vert
        assert (led0_r = '0' and led0_g = '1' and led0_b = '0')
            report "Erreur scenario 3 : la led verte ne clignote pas et/ou la led bleu clignote"
            severity error;

        -- scenario 4 : btn1 relache puis nouvel appui sur btn0 -< doit repasser au bleu
        btn1 <= '0';
        wait for period*2;
        btn0 <= '1';
        wait for period;
        btn0 <= '0';
        -- je verifie directement car le bouton0 est appuye au milieu d'un cycle de clignotement
        assert (led0_r = '0' and led0_g = '0' and led0_b = '1')
            report "Erreur scenario 4 : la led n'est pas repassé au bleu"
            severity error;

        -- scenario 5 : btn1 seul, sans btn0 : ne doit rien declencher
        wait for period*4;
        btn1 <= '1';
        wait for period; -- je cale la verification sur un clignotement (doit rester bleu)
        assert (led0_r = '0' and led0_g = '0' and led0_b = '1')
            report "Erreur scenario 5 : la led n'est pas reste bleue"
            severity error;

        wait;
    end process;

end behavioral;
