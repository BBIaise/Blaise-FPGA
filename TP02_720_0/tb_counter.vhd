library ieee;
use ieee.std_logic_1164.all;

-- l'entity d'un test bench ne contient aucun port, il sert juste à simuler
entity tb_counter is
end tb_counter;

architecture behavioral of tb_counter is

    signal reset_btn   : std_logic := '1'; -- le reset commence à 1 pour forcer un rest dès le début
    signal clk         : std_logic := '0';
    signal restart     : std_logic := '0';
    signal counter_end : std_logic;

    constant hp : time := 5 ns;
    constant period : time := 2*hp;

    -- correspond aux ports du fichier source
    component counter_unit
        port (
            clk         : in std_logic;
            reset_btn   : in std_logic;
            restart     : in std_logic;
            counter_end : out std_logic
        );
    end component;

-- on instancie le composant uut(unit under test) et on relie chaque port à son signal sur le test bench
begin
    uut: counter_unit
        port map (
            clk => clk,
            reset_btn => reset_btn,
            restart => restart,
            counter_end => counter_end
        );

    -- horloge
    clk <= not clk after hp; -- l'horloge s'inverse toute les demies période, ce qui crée un signal carré

    process
    begin
        -- scénario de test
        reset_btn <= '1';
        wait for 20 ns;

        reset_btn <= '0';
        wait for 45 ns;
        
        restart <= '1';
        wait for period;
        
        restart <= '0';
        wait for 2 us;

        wait;  -- wait à la fin de la série de test afin que les test ne tournent pas en boucle
    end process;

end behavioral;