library ieee;
use ieee.std_logic_1164.all;

entity pilote_led_driver is
    generic (
        counter_max : positive := 49999999 -- j'ai choisie un compteur maximum assez haut afin de pouvoir voir le clignotement à l'oeil nu
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
            led0_b     : out std_logic
        );
    end component;

    signal btn0_d      : std_logic; -- btn0_d sera l'etat de btn0 au cycle precedent, il va servir a incrementer update
    signal update      : std_logic; -- sera pilote par btn0 et not btn0_d
    signal color_code  : std_logic_vector(1 downto 0);

begin

    -- detecteur de front montant sur btn0 : update ne pulse qu'1 cycle
    process(clk, resetn)
    begin
        if resetn = '1' then
            btn0_d <= '0'; -- btn0_d est reset a 0 apres un reset
        elsif rising_edge(clk) then
            btn0_d <= btn0; -- btn0_d prend la valeur de btn0 a chaque front d'horloge
        end if;
    end process;
    
    -- update passe à 1 que lorsque btn0 et not btn0_d sont à 1, soit le moment où le bouton 0 est enfonce et
    -- et le court instant où le btn0_d n'a pas encore pris la valeur de btn0 au prochain front d'horloge
    -- de cette facon, on obtient un update a 1 que lorsque le bouton 0 vient d'etre appuye et pas plus longtemps
    -- de plus cette commande n'est dans aucun process pour quelle soit verifie tous le temps
    update <= btn0 and not btn0_d;

    -- color_code suit btn1 en direct : vert si appuye, bleu sinon
    color_code <= "10" when btn1 = '1' else "11";

    u_led_driver : LED_driver
        generic map (
            counter_max => counter_max
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

end behavioral;
