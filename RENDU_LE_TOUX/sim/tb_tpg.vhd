-- Banc de test TPG, je cree une image de simulation et je test un pixel sur plusieurs image
-- consecutives pour verifier que le tpg est bien actif

library ieee;
use ieee.std_logic_1164.all;

entity tb_tpg is
end tb_tpg;

architecture behavioral of tb_tpg is

    -- horloge pixel 25 MHz
    constant hp     : time := 20 ns;
    constant period : time := 2*hp;

    -- taille identique d image
    constant img_w    : integer := 640;
    constant img_h    : integer := 480;
    constant square_y  : integer := 220;    -- hauteur de l element dynamique

    -- 2 constantes, pix_number contient le numero preci du pixel obsreve : colonne 0 de la ligne square_y
    -- et pix_img contient le nombre de pixel qui se trouvent dans mon image
    constant pix_number : integer := square_y * img_w;
    constant pix_img    : integer := img_w * img_h;

    -- entrees du module
    signal clk     : std_logic := '0';
    signal reset   : std_logic := '1';
    signal t_ready : std_logic := '0';

    -- sorties du module
    signal t_valid : std_logic;
    signal t_data  : std_logic_vector(23 downto 0);

    -- releves du pixel observe sur quatre images consecutives
    signal px0, px1, px2, px3 : std_logic_vector(23 downto 0) := (others => '0');

    -- permet a run -all de se terminer
    signal simulation_finish : std_logic := '0';

    component tpg
        generic (
            img_width   : integer := 640;
            img_height  : integer := 480;
            square_size : integer := 20;
            square_y    : integer := 220;
            square_step : integer := 2
        );
        port (
            clk     : in  std_logic;
            reset   : in  std_logic;
            t_ready : in  std_logic;
            t_valid : out std_logic;
            t_data  : out std_logic_vector(23 downto 0)
        );
    end component;

begin

    dut : tpg
        port map (
            clk     => clk,
            reset   => reset,
            t_ready => t_ready,
            t_valid => t_valid,
            t_data  => t_data
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

    process
    begin

        -- reset initial
        reset   <= '1';
        t_ready <= '0'; -- handshake arrete pendant le reset
        wait for period*3;
        reset <= '0';

        -- la mire debite en continu : je fixe le banc sur prêt
        t_ready <= '1';

        -- parcours de quatre images completes
        for k in 0 to (4*pix_img - 1) loop
            wait until rising_edge(clk);
            wait for 1 ns;

            -- releve du pixel observe, une fois par image
            if k = pix_number then
                px0 <= t_data;
            elsif k = pix_number + pix_img then
                px1 <= t_data;
            elsif k = pix_number + 2*pix_img then
                px2 <= t_data;
            elsif k = pix_number + 3*pix_img then
                px3 <= t_data;
            end if;
        end loop;
        
        -- test pour verifier que le tpg est actif
        assert not (px0 = px1 and px1 = px2 and px2 = px3)
            report "Erreur : le pixel observe est identique sur quatre images, la mire est figee"
            severity error;

        -- Le flux doit rester valide pendant toute la duree
        assert (t_valid = '1')
            report "Erreur : t_valid est retombe pendant l'emission"
            severity error;

        report "Fin du banc de test tpg : element dynamique confirme" severity note;

        simulation_finish <= '1';
        wait;
    end process;

end behavioral;
