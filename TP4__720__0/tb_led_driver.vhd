library ieee;
use ieee.std_logic_1164.all;

entity tb_led_driver is
end tb_led_driver;

architecture behavioral of tb_led_driver is

    signal clk        : std_logic := '0';
    signal resetn     : std_logic := '0';
    signal color_code : std_logic_vector(1 downto 0) := "00"; -- color_code instancié à 0
    signal update     : std_logic := '0';
    signal led0_r     : std_logic;
    signal led0_g     : std_logic;
    signal led0_b     : std_logic;

    -- Horloge
    constant hp     : time := 5 ns;
    constant period : time := 2*hp;

    
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
            led0_b     : out std_logic
        );
    end component;

begin

    dut : LED_driver
        generic map (
            counter_max => 3
        )
        port map (
            clk        => clk,
            resetn     => resetn,
            color_code => color_code,
            update     => update,
            led0_r     => led0_r,
            led0_g     => led0_g,
            led0_b     => led0_b
        );

    -- horloge signal carré
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
        wait for period;
        assert (led0_r = '0' and led0_g = '0' and led0_b = '0')
            report "Erreur resetn : les LED ne sont pas eteintes apres reset"
            severity error;

        -- Scénario 1 : color_code = rouge mais update = 0
        color_code <= "01";
        wait for period*2;
        assert (led0_r = '0' and led0_g = '0' and led0_b = '0')
            report "Erreur scenario 1 : la couleur a change sans que update soit passe a 1"
            severity error;

        -- update = 1 : la couleur doit passer au rouge
        wait for period*2;
        update <= '1';
        wait for period;
        update <= '0';
        wait for period*8; -- je cale la vérification sur un clignotement de la led rouge
        assert (led0_r = '1' and led0_g = '0' and led0_b = '0')
            report "Erreur scenario 1 : led0_g ou led0_b active et/ou led_r est éteinte"
            severity error;

        -- Scénario 2 : color_code = vert mais update = 0, la couleur doit rester rouge
        wait for period*8;
        color_code <= "10";
        wait for period*7; -- je cale la vérification sur un clignotement de la led rouge
        assert (led0_r = '1' and led0_g = '0' and led0_b = '0')
            report "Erreur scenario 2 : la couleur a change sans que update soit passe a 1"
            severity error;

        -- update = 1 : la couleur doit passer au vert
        wait for period*10;
        update <= '1';
        wait for period;
        update <= '0';
        wait for period*4; -- je cale la vérification sur un clignotement de la led verte
        assert (led0_r = '0' and led0_g = '1' and led0_b = '0')
            report "Erreur scenario 2 : led0_r ou led0_b active et/ou led_g est éteinte"
            severity error;
            

        -- Scénario 3 : color_code = bleu & update = 1
        wait for period*10;
        color_code <= "11";
        update <= '1';
        wait for period;
        update <= '0';
        wait for period*8; -- je cale la vérification sur un clignotement de la led bleue
        assert (led0_r = '0' and led0_g = '0' and led0_b = '1')
            report "Erreur scenario 3 : led0_r ou led0_g active et/ou led_b est éteinte"
            severity error;

        -- Scénario 4 : color_code = eteint & update = 1
        wait for period*10;
        color_code <= "00";
        update <= '1';
        wait for period;
        update <= '0';
        wait for period*4; -- je cale la vérification sur un clignotement pour vérifié qu'aucune n'est allumée
        assert (led0_r = '0' and led0_g = '0' and led0_b = '0')
            report "Erreur scenario 4 : une LED reste allumee alors que color_code = 00"
            severity error;

        wait;
    end process;

end behavioral;
