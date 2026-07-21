library ieee;
use ieee.std_logic_1664.all;

entity LED_driver is
    generic (
        counter_max : positive := 5
    );
    Port ( clk        : in  std_logic;
           resetn     : in  std_logic;
           color_code : in  std_logic_vector(1 downto 0); -- 2 bits pour pouvoir �changer entre les 4 valeurs possible
           update     : in  std_logic; -- update va �tre notre signal de transition pour color_code
           led0_r     : out std_logic;
           led0_g     : out std_logic;
           led0_b     : out std_logic);
end LED_driver;


architecture Behavioral of LED_driver is

    component cycle_counter
        generic (
            counter_max : positive
        );
        port (
            clk       : in  std_logic;
            resetn    : in  std_logic;
            led_blink : out std_logic
        );
    end component;

    signal led_blink    : std_logic;
    signal active_color : std_logic_vector(1 downto 0); -- active_color va m�moriser la couleur de color_code

begin

    u_cycle_counter : cycle_counter
        generic map (
            counter_max => counter_max
        )
        port map (
            clk       => clk,
            resetn    => resetn,
            led_blink => led_blink
        );

    -- memorise color_code uniquement quand update = '1', sinon garde sa valeur
    process(clk, resetn)
    begin
        if resetn = '1' then
            active_color <= "00";
        elsif rising_edge(clk) then
            if update = '1' then
                active_color <= color_code;
            end if;
        end if;
    end process;

    -- aiguille led_blink vers la sortie correspondant a la couleur memorisee
    process(active_color, led_blink)
    begin
        led0_r <= '0'; -- au lieu d'appeler les 3 leds a chaque etat, je les mets toutes a 0 au debut pour le code 00
        led0_g <= '0';
        led0_b <= '0';
        case active_color is
            when "01"   => 
                led0_r <= led_blink; -- et je passe a led_blink celle dont l'etat correspond
            when "10"   => 
                led0_g <= led_blink;
            when "11"   => 
                led0_b <= led_blink;
            when others => null; -- si un code diffenrent apparait on sort de la machine a etat
        end case;
    end process;

end Behavioral;
