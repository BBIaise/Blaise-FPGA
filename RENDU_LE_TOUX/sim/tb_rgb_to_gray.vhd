-- Banc de test de r(gb_to_gray
--
-- Ce Banc va tester que la luminance est bien applique sur tout type de couleur
-- et que les differente combianaison de handshake renvois les bon arguments
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity tb_rgb_to_gray is
end tb_rgb_to_gray;

architecture behavioral of tb_rgb_to_gray is

    -- entrees du module
    signal s_t_valid : std_logic := '0';
    signal s_t_data  : std_logic_vector(23 downto 0) := (others => '0');
    signal m_t_ready : std_logic := '0';

    -- sorties du module
    signal s_t_ready : std_logic;
    signal m_t_valid : std_logic;
    signal m_t_data  : std_logic_vector(7 downto 0);

    -- duree entre deux cas de test
    constant period : time := 10 ns;

    component rgb_to_gray
        port (
            s_t_valid : in  std_logic;
            s_t_data  : in  std_logic_vector(23 downto 0);
            m_t_ready : in  std_logic;
            s_t_ready : out std_logic;
            m_t_valid : out std_logic;
            m_t_data  : out std_logic_vector(7 downto 0)
        );
    end component;

begin

    dut : rgb_to_gray
        port map (
            s_t_valid => s_t_valid,
            s_t_data  => s_t_data,
            m_t_ready => m_t_ready,
            s_t_ready => s_t_ready,
            m_t_valid => m_t_valid,
            m_t_data  => m_t_data
        );

    -- pas de process d'horloge car le module ne contient aucune bascule
    process
    begin

        -- je verifie le handshake
        s_t_valid <= '1';
        m_t_ready <= '1';
        wait for period;

        -- Scenario 1 : luminance sur la couleur noir
        s_t_data <= x"000000";
        wait for period;
        assert (m_t_data = x"00")
            report "Erreur : noir, luminance attendue 0x00"
            severity error;

        -- Scenario 2 : luminance sur la couleur blanche
        s_t_data <= x"FFFFFF";
        wait for period;
        assert (m_t_data = x"FF")
            report "Erreur : blanc, luminance attendue 0xFF"
            severity error;

        -- Scenario 3 : luminance sur la couleur rouge
        s_t_data <= x"FF0000";
        wait for period;
        assert (m_t_data = x"3F")
            report "Erreur : rouge, luminance attendue 0x3F (63)"
            severity error;

        -- Scenario 4 : luminance sur la couleur verte
        s_t_data <= x"00FF00";
        wait for period;
        assert (m_t_data = x"9F")
            report "Erreur : vert, luminance attendue 0x9F (159)"
            severity error;

        -- Scenario 5 : luminance sur la couleur bleu
        s_t_data <= x"0000FF";
        wait for period;
        assert (m_t_data = x"1F")
            report "Erreur : bleu, luminance attendue 0x1F (31)"
            severity error;

        -- Scenario 6 : luminance sur la couleur grise
        s_t_data <= x"808080";
        wait for period;
        assert (m_t_data = x"80")
            report "Erreur : gris, luminance attendue 0x80 (128)"
            severity error;

        -- valid / ready : les 4 combinaisons possibles
        -- Scenario 7 : valid = 0 & ready = 0
        s_t_valid <= '0';
        m_t_ready <= '0';
        wait for period;
        assert (m_t_valid = '0' and s_t_ready = '0')
            report "Erreur : valid=0 ready=0"
            severity error;

        -- Scenario 8 : valid = 0 & ready = 1
        s_t_valid <= '0';
        m_t_ready <= '1';
        wait for period;
        assert (m_t_valid = '0' and s_t_ready = '1')
            report "Erreur : valid=0 ready=1,"
            severity error;

        -- Scenario 9 : valid = 1 & ready = 0
        s_t_valid <= '1';
        m_t_ready <= '0';
        wait for period;
        assert (m_t_valid = '1' and s_t_ready = '0')
            report "Erreur : valid=1 ready=0"
            severity error;

        -- Scenario 10 : valid = 1 & ready = 1
        s_t_valid <= '1';
        m_t_ready <= '1';
        wait for period;
        assert (m_t_valid = '1' and s_t_ready = '1')
            report "Erreur : valid=1 ready=1"
            severity error;

        report "Fin du banc de test rgb_to_gray : 10 scenarios verifies"
            severity note;

        wait;
    end process;

end behavioral;
