----------------------------------------------------------------------------------
-- Module Name: vga_controller_rgb - Behavioral
-- Variante 24 bits (RGB888) de vga_controller.vhd : meme logique de comptage
-- h_count/v_count/sync, mais t_data/video_out portent les 3 composantes
-- couleur au lieu d'un simple niveau de gris. Fichier separe pour ne pas
-- toucher a vga_controller.vhd (deja valide pour le TPG, PL-DISP-002).
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity vga_controller_rgb is
    generic (
        h_max : integer := 799;
        v_max : integer := 524
        );
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        t_valid     : in std_logic;
        t_data      : in std_logic_vector(23 downto 0);
        hsync       : out std_logic;
        vsync       : out std_logic;
        t_ready     : out std_logic;
        video_out   : out std_logic_vector(23 downto 0);
        t_user      : in std_logic := '0'   -- ajout d'un port pour stabiliser l image venant du dma
        );

end vga_controller_rgb;

architecture Behavioral of vga_controller_rgb is

    signal h_count      : std_logic_vector(9 downto 0) := (others => '0');  -- compteur de colonne
    signal v_count      : std_logic_vector(9 downto 0) := (others => '0');  -- compteur de ligne
    signal video_active : std_logic;

    attribute mark_debug : string;
    attribute mark_debug of h_count      : signal is "true";
    attribute mark_debug of v_count      : signal is "true";
    attribute mark_debug of video_active : signal is "true";

begin

    process(clk, reset)
    begin
        -- je met les compteur a 0 apres un reset
        if (reset = '1') then
            h_count <= (others => '0');
            v_count <= (others => '0');
        
        -- sur un front montant
        elsif rising_edge(clk) then
            -- recalage sur le debut de trame de la source
            if (t_user = '1' and t_valid = '1' and video_active = '1') then
                h_count <= (others => '0');
                v_count <= (others => '0');
                
            elsif h_count = h_max then  -- si le compteur de colonne est a son max
                h_count <= (others => '0'); -- je le remet a 0

                if v_count = v_max then         -- et si le compteur de ligne est a son max
                    v_count <= (others => '0'); -- je le remet a 0 aussi

                else
                    v_count <= v_count + 1; -- sinon je l'incremente de 1
                end if;
            else
                h_count <= h_count + 1; -- sinon je l'incremente de 1

            end if;
        end if;

    end process;

    -- video_active verifie que nous somme dans la zone visible
    video_active <= '1' when h_count < 640 and v_count < 480 else '0';
    
    -- hsync & vsync sont en actif bas
    -- impuslion negative a la fin de chaque ligne pendant 92 cycle d horloge
    hsync <= '0' when (h_count > 655 and h_count < 752) else '1';
    -- impuslion negative de 2 ligne a la fin de chaque image
    vsync <= '0' when (v_count > 489 and v_count < 492) else '1';
    
    -- le t_ready s active lorsqu on est dans la zone visible
    t_ready <= '1' when video_active ='1' else '0';
    
    -- video_out sort un pixel de t_data si t_valid est à 1 et qu on est dans la zone visible
    video_out <= t_data when (video_active = '1' and t_valid = '1') else (others => '0');

end Behavioral;
