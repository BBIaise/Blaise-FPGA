library ieee;
use ieee.std_logic_1164.all;

entity tb_cycle_counter is
end tb_cycle_counter;

architecture behavioral of tb_cycle_counter is

    signal clk        : std_logic := '0';
    signal resetn     : std_logic := '0';
    signal restart    : std_logic := '0';
    signal cycle_done : std_logic;

    -- meme horloge que dans tb_tp_fsm
    constant hp     : time := 5 ns;
    constant period : time := 2*hp;

    component cycle_counter
        generic (
            counter_max : positive;
            nb_cycle    : positive
        );
        port (
            clk         : in std_logic;
            resetn      : in std_logic;
            restart     : in std_logic;
            cycle_done  : out std_logic
        );
    end component;

begin

    -- J'ai réduit counter_max et nb_cycle pour la simulation
    -- led_update = 3*2 = 6, et il faut 6*(counter_max + 1) soit 6*2 = 12 periodes pour avoir un cycle_done
    uut: cycle_counter
        generic map (
            counter_max => 1,
            nb_cycle    => 3
        )
        port map (
            clk         => clk,
            resetn      => resetn,
            restart     => restart,
            cycle_done  => cycle_done
        );

    -- Horloge
    process
    begin
        wait for hp;
        clk <= not clk;
    end process;

    process
    begin

        -- scénario 1 : pendant le reset, le compteur doit rester à 0 donc cycle_done à 0
        resetn <= '1';
        wait for period*2;
        assert (cycle_done = '0')
            report "ERREUR : cycle_done n'est pas à 0"
            severity error;

        -- scénario 2 : après 12 periodes, cycle_done doit passer à 1
        resetn <= '0';              -- on met le reset à  0 pour que le compteur démarre
        wait for period*12;         -- attente de 12 periodes soit 120ns
        assert (cycle_done = '1')   -- avec un assert, si cycle_done est différent de 1 l'erreur apparait sinon rien 
            report "ERREUR : cycle_done aurait du passer Ã  1 ici"
            severity error;

        -- scénario 3 : On attend une periode pour vérifier que cycle_done retourne à 0
        wait for period;
        assert (cycle_done = '0')
            report "ERREUR : cycle_done aurait du retomber Ã  0"
            severity error;


        -- scénario 4 : On passe resetn à 1 en plein comptage pour vérifier qu'il recommence correctement et qu'il finit bien en 12 periodes
        wait for period*5; -- on avance un peu dans un nouveau comptage, sans attendre les 12 periodes
        resetn <= '1';
        wait for period;
        resetn <= '0';

        wait for period*5;
        assert (cycle_done = '0')
            report "ERREUR : resetn n'a pas remis le compteur a 0 correctement"
            severity error;

        wait for period*7;          -- 5 + 7 periodes font 12, le temps pour avoir un cycle_done à 1
        assert (cycle_done = '1')
            report "ERREUR : cycle_done aurait du repasser a 1, 12 periodes apres le reset en plein comptage"
            severity error;

        -- scénario 5 : On passe restart à 1 en plein comptage pour vérifier qu'il recommence correctement et qu'il finit bien en 12 periodes
        wait for period*5; -- on avance un peu dans un nouveau comptage, sans attendre les 12 periodes
        restart <= '1';
        wait for period;
        restart <= '0';

        wait for period*5;
        assert (cycle_done = '0')
            report "ERREUR : restart n'a pas remis le compteur a 0 correctement"
            severity error;

        wait for period*7;
        assert (cycle_done = '1')
            report "ERREUR : cycle_done aurait du repasser a 1, 12 periodes apres le reset en plein comptage"
            severity error;

        wait;

    end process;

end behavioral;
