----------------------------------------------------------------------------------
-- Banc de test : vga_controller_rgb
--
-- Verifie les temporisations de l'affichage VGA 640 x 480 @ 60 Hz (PL-DISP-002).
--
-- Valeurs de la norme VGA 640 x 480 @ 60 Hz :
--
--              Actif  Front porch  Synchro  Back porch  Total
--   Horizontal   640       16         96        48       800
--   Vertical     480       10          2        33       525
--
--   Frequence trame : 25 MHz / (800 x 525) = 59,52 Hz
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity tb_vga_controller_rgb is
end tb_vga_controller_rgb;

architecture behavioral of tb_vga_controller_rgb is

    -- horloge pixel 25 MHz
    constant hp     : time := 20 ns;
    constant period : time := 2*hp;

    -- valeurs attendues, en cycles d'horloge pixel
    constant h_total    : integer := 800;        -- periode ligne
    constant h_sync_len : integer := 96;         -- largeur impulsion hsync
    constant v_total    : integer := 800*525;    -- periode trame = 420 000
    constant v_sync_len : integer := 800*2;      -- largeur impulsion vsync = 2 lignes

    -- entrees du module
    signal clk     : std_logic := '0';
    signal reset   : std_logic := '1';
    signal t_valid : std_logic := '1';
    signal t_data  : std_logic_vector(23 downto 0) := x"ABCDEF";

    -- sorties du module
    signal hsync     : std_logic;
    signal vsync     : std_logic;
    signal t_ready   : std_logic;
    signal video_out : std_logic_vector(23 downto 0);

    -- compteur de cycles d'horloge
    signal cycle_count : integer := 0;

    -- permet a run -all de se terminer
    signal simulation_finish : std_logic := '0';

    component vga_controller_rgb
        generic (
            h_max : integer := 799;
            v_max : integer := 524
        );
        port (
            clk       : in  std_logic;
            reset     : in  std_logic;
            t_valid   : in  std_logic;
            t_data    : in  std_logic_vector(23 downto 0);
            hsync     : out std_logic;
            vsync     : out std_logic;
            t_ready   : out std_logic;
            video_out : out std_logic_vector(23 downto 0)
        );
    end component;

begin

    dut : vga_controller_rgb
        generic map (
            h_max => 799,
            v_max => 524
        )
        port map (
            clk       => clk,
            reset     => reset,
            t_valid   => t_valid,
            t_data    => t_data,
            hsync     => hsync,
            vsync     => vsync,
            t_ready   => t_ready,
            video_out => video_out
        );

    -- horloge signal carre
    process
    begin
        if simulation_finish = '0' then
            wait for hp;
            clk <= not clk;
        else
            wait;
        end if;
    end process;

    -- comteur de cycle d horloge
    process(clk)
    begin
        if rising_edge(clk) then
            cycle_count <= cycle_count + 1;
        end if;
    end process;

    process
        variable t1, t2 : integer;
    begin

        -- reset initial
        reset <= '1';
        wait for period*3;
        reset <= '0';

        -- Scenario 1 : periode ligne = 800 cycles
        wait until falling_edge(hsync);
        t1 := cycle_count;
        wait until falling_edge(hsync);
        t2 := cycle_count;

        assert (t2 - t1 = h_total)
            report "Erreur Scenario 1 : periode ligne incorrecte (attendu 800 cycles)"
            severity error;

        -- Scenario 2 : largeur de l'impulsion hsync = 96 cycles, active bas
        wait until falling_edge(hsync);
        t1 := cycle_count;
        wait until rising_edge(hsync);
        t2 := cycle_count;

        assert (t2 - t1 = h_sync_len)
            report "Erreur Scenario 2 : largeur hsync incorrecte (attendu 96 cycles)"
            severity error;

        -- Scenario 3 : t_ready doit etre bas pendant l'impulsion hsync,
        -- qui se situe hors de la zone d'affichage actif
        wait until falling_edge(hsync);
        wait for period*4;

        assert (t_ready = '0')
            report "Erreur Scenario 3 : t_ready actif pendant la suppression horizontale"
            severity error;

        -- Scenario 4 : largeur de l'impulsion vsync = 2 lignes = 1600 cycles
        wait until falling_edge(vsync);
        t1 := cycle_count;
        wait until rising_edge(vsync);
        t2 := cycle_count;

        assert (t2 - t1 = v_sync_len)
            report "Erreur Scenario 4 : largeur vsync incorrecte (attendu 1600 cycles)"
            severity error;

        -- Scenario 5 : periode trame = 800 x 525 = 420 000 cycles
        -- A 25 MHz cela donne 16,8 ms, soit 59,52 images par seconde.
        wait until falling_edge(vsync);
        t1 := cycle_count;
        wait until falling_edge(vsync);
        t2 := cycle_count;

        assert (t2 - t1 = v_total)
            report "Erreur Scenario 5 : periode trame incorrecte (attendu 420 000 cycles)"
            severity error;

        report "Fin du banc de test vga_controller_rgb : 5 temporisations verifiees"
            severity note;

        simulation_finish <= '1';
        wait;
    end process;

end behavioral;
