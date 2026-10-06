
library ieee;
use ieee.std_logic_1164.all;

entity tb_gaussian_filter is
end tb_gaussian_filter;

architecture behavioral of tb_gaussian_filter is

    -- image reduite pour la simulation
    constant tb_width  : integer := 8;
    constant tb_height : integer := 6;

    -- horloge 25 MHz
    constant hp     : time := 20 ns;
    constant period : time := 2*hp;

    -- entrees du module
    signal clk       : std_logic := '0';
    signal reset     : std_logic := '1';
    signal s_t_valid : std_logic := '0';
    signal s_t_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal m_t_ready : std_logic := '0';

    -- sorties du module
    signal s_t_ready : std_logic;
    signal m_t_valid : std_logic;
    signal m_t_data  : std_logic_vector(7 downto 0);

    -- memorisation pour le test de contre-pression
    signal data_gel  : std_logic_vector(7 downto 0) := (others => '0');

    -- permet a run -all de se terminer
    signal simulation_finish  : std_logic := '0';

    component gaussian_filter
        generic (
            img_width  : integer := 640;
            img_height : integer := 480
        );
        port (
            clk       : in  std_logic;
            reset     : in  std_logic;
            s_t_valid : in  std_logic;
            s_t_ready : out std_logic;
            s_t_data  : in  std_logic_vector(7 downto 0);
            m_t_valid : out std_logic;
            m_t_ready : in  std_logic;
            m_t_data  : out std_logic_vector(7 downto 0)
        );
    end component;

begin

    dut : gaussian_filter
        generic map (
            img_width  => tb_width, -- je change la largeur de mon image
            img_height => tb_height -- de meme pour la hauteur
        )
        port map (
            clk       => clk,
            reset     => reset,
            s_t_valid => s_t_valid,
            s_t_ready => s_t_ready,
            s_t_data  => s_t_data,
            m_t_valid => m_t_valid,
            m_t_ready => m_t_ready,
            m_t_data  => m_t_data
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
        reset <= '1';
        s_t_valid <= '0';   -- j arrete le handshake pendant le reset
        m_t_ready <= '0';
        wait for period*2;
        reset <= '0';
        wait for period;


        -- Scenario 1 et 2 : image uniforme a 0x80, sur deux images completes
        s_t_valid <= '1';
        m_t_ready <= '1';
        s_t_data  <= x"80";
        
        -- je parcours 2 images entieres
        for k in 0 to (2 * tb_width * tb_height - 1) loop
            wait until rising_edge(clk);
            wait for 1 ns;   -- laisse le temps aux sorties combinatoires se stabiliser

            -- Scenario 2 : les tout premiers pixels sont sur la premiere ligne,
            -- donc le masques noir doit etre present quelle que soit la phase exacte des compteurs.
            if k <= 5 then  -- je prends une valeur de la premiere ligne au hasard
                assert (m_t_data = x"00")
                    report "Erreur Scenario 2 : bordure haute non masquee"
                    severity error;
            end if;

            -- Scenario 1 : interieur de l'image. On prend une marge de part et
            -- d'autre de la frontiere du masque (colonnes 3 a 6) pour
            -- ne pas dependre d'un decalage d'un cycle, et k >= 20 garantit
            -- que la fenetre 3x3 est entierement remplie et donc que le filtre a commence.
            if k >= 20 and (k mod tb_width) >= 3 and (k mod tb_width) <= 6 then
                assert (m_t_data = x"80")
                    report "Erreur Scenario 1 : image uniforme 0x80 non conservee"
                    severity error;
            end if;
        end loop;

        -- Scenario 3 : test de la contrepression, aucun transfert de donnees ne doit
        -- etre realiser lorsque le handshake n est pas respecte
        m_t_ready <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        data_gel <= m_t_data;   -- je met la data en memoire
        wait for 1 ns;

        for i in 0 to 4 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            assert (m_t_data = data_gel)    -- si la data a change -> erreur
                report "Erreur Scenario 3 : la sortie change alors que le handshake n est plus respecte"
                severity error;
        end loop;

        m_t_ready <= '1';

        -- Scenario 4 : image uniforme a 0xFF, deuxieme test avec une image noir 

        s_t_data <= x"FF";

        for k in 0 to (2 * tb_width * tb_height - 1) loop
            wait until rising_edge(clk);
            wait for 1 ns;

            if k >= 20 and (k mod tb_width) >= 3 and (k mod tb_width) <= 6 then
                assert (m_t_data = x"FF")
                    report "Erreur Scenario 4 : image uniforme 0xFF non conserve"
                    severity error;
            end if;
        end loop;

        report "Fin du banc de test gaussian_filter" severity note;

        simulation_finish <= '1';
        wait;
    end process;

end behavioral;
