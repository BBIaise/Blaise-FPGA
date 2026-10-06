----------------------------------------------------------------------------------
-- Module Name: top - Behavioral
-- Top-level du projet SoC Tracking
-- 
-- Fichier qui va s occuper de relier tous les bloc entre eux
-- il contient la déclaraition de tous les blocs du projets ainsi que leur instanciation
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    port (
        CLK_I       : in STD_LOGIC;  -- horloge 125 MHz, broche H16
        btn_i       : in STD_LOGIC;  -- bouton 0 : '0' =TPG, '1' =DMA, BTN0
        btn_rst_i   : in STD_LOGIC;  -- BTN1, reset manuel du chemin DMA (permet de resynchroniser lors d un test)

        -- Pmod VGA
        VGA_HS_O : out STD_LOGIC;   -- synchronisation horizontale
        VGA_VS_O : out STD_LOGIC;   -- synchronisation verticale
        
        -- j utilsie 4 bits par couleur car il n y a pas assez de port sur la carte pour en utiliser plus
        VGA_R    : out STD_LOGIC_VECTOR(3 downto 0);    -- couleur rouge
        VGA_G    : out STD_LOGIC_VECTOR(3 downto 0);    -- couleur verte
        VGA_B    : out STD_LOGIC_VECTOR(3 downto 0);    -- couleur bleu

        -- Je declare les ports du design_1_wrapper 
        DDR_addr        : inout STD_LOGIC_VECTOR(14 downto 0);  -- bus d adresse
        DDR_ba          : inout STD_LOGIC_VECTOR(2 downto 0);   -- banque d adresse
        DDR_cas_n       : inout STD_LOGIC;  -- indique une adresse de colonne
        DDR_ck_n        : inout STD_LOGIC;
        DDR_ck_p        : inout STD_LOGIC;
        DDR_cke         : inout STD_LOGIC; 
        DDR_cs_n        : inout STD_LOGIC;  -- active le composant en memoire
        DDR_dm          : inout STD_LOGIC_VECTOR(3 downto 0);
        DDR_dq          : inout STD_LOGIC_VECTOR(31 downto 0);
        DDR_dqs_n       : inout STD_LOGIC_VECTOR(3 downto 0);
        DDR_dqs_p       : inout STD_LOGIC_VECTOR(3 downto 0);
        DDR_odt         : inout STD_LOGIC;
        DDR_ras_n       : inout STD_LOGIC;  -- indique que la ddr porte une adresse
        DDR_reset_n     : inout STD_LOGIC;  -- reset de la puce memoire
        DDR_we_n        : inout STD_LOGIC;  -- ecriture
        
        -- Les entree/sorties du processeur
        FIXED_IO_ddr_vrn  : inout STD_LOGIC;
        FIXED_IO_ddr_vrp  : inout STD_LOGIC;
        FIXED_IO_mio      : inout STD_LOGIC_VECTOR(53 downto 0);
        FIXED_IO_ps_clk   : inout STD_LOGIC;
        FIXED_IO_ps_porb  : inout STD_LOGIC;
        FIXED_IO_ps_srstb : inout STD_LOGIC
        );
end top;

architecture Behavioral of top is

    -- component du Wrapper 
    component design_1_wrapper is
        port (
            DDR_addr    : inout STD_LOGIC_VECTOR(14 downto 0);
            DDR_ba      : inout STD_LOGIC_VECTOR(2 downto 0);
            DDR_cas_n   : inout STD_LOGIC;
            DDR_ck_n    : inout STD_LOGIC;
            DDR_ck_p    : inout STD_LOGIC;
            DDR_cke     : inout STD_LOGIC;
            DDR_cs_n    : inout STD_LOGIC;
            DDR_dm      : inout STD_LOGIC_VECTOR(3 downto 0);
            DDR_dq      : inout STD_LOGIC_VECTOR(31 downto 0);
            DDR_dqs_n   : inout STD_LOGIC_VECTOR(3 downto 0);
            DDR_dqs_p   : inout STD_LOGIC_VECTOR(3 downto 0);
            DDR_odt     : inout STD_LOGIC;
            DDR_ras_n   : inout STD_LOGIC;
            DDR_reset_n : inout STD_LOGIC;
            DDR_we_n    : inout STD_LOGIC;
            FIXED_IO_ddr_vrn    : inout STD_LOGIC;
            FIXED_IO_ddr_vrp    : inout STD_LOGIC;
            FIXED_IO_mio        : inout STD_LOGIC_VECTOR(53 downto 0);
            FIXED_IO_ps_clk     : inout STD_LOGIC;
            FIXED_IO_ps_porb    : inout STD_LOGIC;
            FIXED_IO_ps_srstb   : inout STD_LOGIC;

            S_AXI_DMA_araddr  : in  STD_LOGIC_VECTOR(63 downto 0);
            S_AXI_DMA_arburst : in  STD_LOGIC_VECTOR(1 downto 0);
            S_AXI_DMA_arcache : in  STD_LOGIC_VECTOR(3 downto 0);
            S_AXI_DMA_arlen   : in  STD_LOGIC_VECTOR(7 downto 0);
            S_AXI_DMA_arlock  : in  STD_LOGIC_VECTOR(0 downto 0);
            S_AXI_DMA_arprot  : in  STD_LOGIC_VECTOR(2 downto 0);
            S_AXI_DMA_arqos   : in  STD_LOGIC_VECTOR(3 downto 0);
            S_AXI_DMA_arready : out STD_LOGIC;
            S_AXI_DMA_arsize  : in  STD_LOGIC_VECTOR(2 downto 0);
            S_AXI_DMA_arvalid : in  STD_LOGIC;
            S_AXI_DMA_awaddr  : in  STD_LOGIC_VECTOR(63 downto 0);
            S_AXI_DMA_awburst : in  STD_LOGIC_VECTOR(1 downto 0);
            S_AXI_DMA_awcache : in  STD_LOGIC_VECTOR(3 downto 0);
            S_AXI_DMA_awlen   : in  STD_LOGIC_VECTOR(7 downto 0);
            S_AXI_DMA_awlock  : in  STD_LOGIC_VECTOR(0 downto 0);
            S_AXI_DMA_awprot  : in  STD_LOGIC_VECTOR(2 downto 0);
            S_AXI_DMA_awqos   : in  STD_LOGIC_VECTOR(3 downto 0);
            S_AXI_DMA_awready : out STD_LOGIC;
            S_AXI_DMA_awsize  : in  STD_LOGIC_VECTOR(2 downto 0);
            S_AXI_DMA_awvalid : in  STD_LOGIC;
            S_AXI_DMA_bready  : in  STD_LOGIC;
            S_AXI_DMA_bresp   : out STD_LOGIC_VECTOR(1 downto 0);
            S_AXI_DMA_bvalid  : out STD_LOGIC;
            S_AXI_DMA_rdata   : out STD_LOGIC_VECTOR(127 downto 0);
            S_AXI_DMA_rlast   : out STD_LOGIC;
            S_AXI_DMA_rready  : in  STD_LOGIC;
            S_AXI_DMA_rresp   : out STD_LOGIC_VECTOR(1 downto 0);
            S_AXI_DMA_rvalid  : out STD_LOGIC;
            S_AXI_DMA_wdata   : in  STD_LOGIC_VECTOR(127 downto 0);
            S_AXI_DMA_wlast   : in  STD_LOGIC;
            S_AXI_DMA_wready  : out STD_LOGIC;
            S_AXI_DMA_wstrb   : in  STD_LOGIC_VECTOR(15 downto 0);
            S_AXI_DMA_wvalid  : in  STD_LOGIC;

           
            dma_axi_aclk        : in STD_LOGIC;
            dma_axi_aresetn     : in STD_LOGIC;
            select_gpio_tri_o   : out STD_LOGIC_VECTOR(1 downto 0)
            
            );
    end component design_1_wrapper;

    -- component Horloge
    component clk_wiz_0
        port (
            CLK_IN1  : in  std_logic;
            CLK_OUT1 : out std_logic
            );
    end component;

    -- component TPG
    component tpg
        generic (
            img_width       : integer := 640;
            img_height      : integer := 480;
            square_size     : integer := 20;
            sq_y            : integer := 220;
            sq_step         : integer := 2
            );
        port (
            clk       : in  std_logic;
            reset     : in  std_logic;
            t_ready   : in  std_logic;
            t_valid   : out std_logic;
            t_data    : out std_logic_vector(23 downto 0)
            );
    end component;

    -- component DMA24Unit_mm2s
    component dma_video_src
        port (
            clk       : in  std_logic;
            reset     : in  std_logic;
            t_ready   : in  std_logic;
            t_valid   : out std_logic;
            t_data    : out std_logic_vector(23 downto 0);
            t_last    : out std_logic;
            t_user    : out std_logic;

            m_axi_awvalid  : out std_logic;
            m_axi_awready  : in  std_logic;
            m_axi_awaddr   : out std_logic_vector(63 downto 0);
            m_axi_awid     : out std_logic_vector(0 downto 0);
            m_axi_awlen    : out std_logic_vector(7 downto 0);
            m_axi_awsize   : out std_logic_vector(2 downto 0);
            m_axi_awburst  : out std_logic_vector(1 downto 0);
            m_axi_awlock   : out std_logic_vector(1 downto 0);
            m_axi_awcache  : out std_logic_vector(3 downto 0);
            m_axi_awprot   : out std_logic_vector(2 downto 0);
            m_axi_awqos    : out std_logic_vector(3 downto 0);
            m_axi_awregion : out std_logic_vector(3 downto 0);

            m_axi_wvalid   : out std_logic;
            m_axi_wready   : in  std_logic;
            m_axi_wdata    : out std_logic_vector(127 downto 0);
            m_axi_wstrb    : out std_logic_vector(15 downto 0);
            m_axi_wlast    : out std_logic;
            m_axi_wid      : out std_logic_vector(0 downto 0);

            m_axi_arvalid  : out std_logic;
            m_axi_arready  : in  std_logic;
            m_axi_araddr   : out std_logic_vector(63 downto 0);
            m_axi_arid     : out std_logic_vector(0 downto 0);
            m_axi_arlen    : out std_logic_vector(7 downto 0);
            m_axi_arsize   : out std_logic_vector(2 downto 0);
            m_axi_arburst  : out std_logic_vector(1 downto 0);
            m_axi_arlock   : out std_logic_vector(1 downto 0);
            m_axi_arcache  : out std_logic_vector(3 downto 0);
            m_axi_arprot   : out std_logic_vector(2 downto 0);
            m_axi_arqos    : out std_logic_vector(3 downto 0);
            m_axi_arregion : out std_logic_vector(3 downto 0);

            m_axi_rvalid   : in  std_logic;
            m_axi_rready   : out std_logic;
            m_axi_rdata    : in  std_logic_vector(127 downto 0);
            m_axi_rlast    : in  std_logic;
            m_axi_rid      : in  std_logic_vector(0 downto 0);
            m_axi_rresp    : in  std_logic_vector(1 downto 0);

            m_axi_bvalid   : in  std_logic;
            m_axi_bready   : out std_logic;
            m_axi_bresp    : in  std_logic_vector(1 downto 0);
            m_axi_bid      : in  std_logic_vector(0 downto 0)
            );
    end component;
    
    -- component vga_controller_rgb
    component vga_controller_rgb
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
            t_user      : in std_logic
            );
    end component;

    --component rgb_to_gray
    component rgb_to_gray
        port (
           s_t_valid    : in STD_LOGIC;
           s_t_data     : in STD_LOGIC_VECTOR(23 downto 0);
           m_t_ready    : in STD_LOGIC;
           s_t_ready    : out STD_LOGIC;
           m_t_valid    : out STD_LOGIC;
           m_t_data     : out STD_LOGIC_VECTOR(7 downto 0)
           );
    end component;
    
    -- composant filtre gaussien
    component gaussian_filter
        Generic ( 
            img_width : integer := 640;
            img_height : integer := 480
            );
        Port ( 
           clk          : in STD_LOGIC;
           reset        : in STD_LOGIC;
           s_t_valid    : in STD_LOGIC;
           s_t_ready    : out STD_LOGIC;
           s_t_data     : in STD_LOGIC_VECTOR(7 downto 0);
           m_t_valid    : out STD_LOGIC;
           m_t_ready    : in STD_LOGIC;
           m_t_data     : out STD_LOGIC_VECTOR(7 downto 0)
           );
    end component; 
    
    -- component filtre harris
    component harris_filter
        Generic (
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
    
    -- composant binarisation
    component binarisation
        generic (
            seuil : integer := 64
            );
        port (
            s_t_valid : in  std_logic;
            s_t_ready : out std_logic;
            s_t_data  : in  std_logic_vector(7 downto 0);
            m_t_valid : out std_logic;
            m_t_ready : in  std_logic;
            m_t_data  : out std_logic_vector(7 downto 0)
            );
    end component;
    
    -- signaux de liaison harris et binarisation
    signal harris_valid, harris_ready : std_logic;
    signal harris_data                : std_logic_vector(7 downto 0);
    signal binar_valid,  binar_ready  : std_logic;
    signal binar_data                 : std_logic_vector(7 downto 0);
    
    signal pxl_clk   : std_logic;   -- horloges 25Mhz produit par clk_div_inst
    
    signal reset_i    : std_logic := '1';   -- reset actif, initialise a 1
    signal reset_n_i  : std_logic;          -- reset actif bas pour PS7 & le DMA du bloc design
    
    -- Duree du reset : ~30s pour laisse le temps d ecrire l image en ddr
    constant RESET_HOLD_CYCLES : unsigned(29 downto 0) := to_unsigned(750_000_000, 30);
    signal rst_cnt_i  : unsigned(29 downto 0) := (others => '0');
    
    -- BTN1 : le pouls de reset ci-dessus ne se declenche qu'une fois, 
    -- dans les tout premiers instants apres le telechargement
    -- du bitstream. Comme ap_start du DMA HLS est cable en
    -- dur a '1', sa premiere tentative de lecture AXI echoue dans de
    -- mauvaises conditions et le chemin DMA reste bloque pour le reste de
    -- la session. BTN1 permet de rejouer ce pouls manuellement, une fois la
    -- DDR reellement prete, pour resynchroniser le DMA sans reprogrammer le
    -- FPGA.
    signal btn_rst_sync1, btn_rst_sync2, btn_rst_prev : std_logic := '0';
    signal btn_rst_pulse    : std_logic;
    
    signal sel_gpio_raw            : std_logic_vector(1 downto 0);  -- signal sortant du gpio a 50Mhz
    
    -- synchroniseur vers 25MHz
    signal sel_sync1, sel_sync2    : std_logic_vector(1 downto 0) := (others => '0');

    -- signaux du TPG
    signal tpg_t_valid   : std_logic;
    signal tpg_t_data    : std_logic_vector(23 downto 0);

    -- signaux du DMA
    signal dma_t_valid : std_logic;
    signal dma_t_data  : std_logic_vector(23 downto 0);
    signal dma_t_last  : std_logic;
    signal dma_t_user  : std_logic;
    
    -- signaux du choix de la source
    signal mux_t_valid : std_logic;
    signal mux_t_data  : std_logic_vector(23 downto 0);

    signal vga_t_ready   : std_logic;
    signal vga_video_out : std_logic_vector(23 downto 0);

    -- Port AXI4 maitre du DMA venant de design_1_wrapper
    signal axi_awvalid  : std_logic;
    signal axi_awready  : std_logic;
    signal axi_awaddr   : std_logic_vector(63 downto 0);
    signal axi_awlen    : std_logic_vector(7 downto 0);
    signal axi_awsize   : std_logic_vector(2 downto 0);
    signal axi_awburst  : std_logic_vector(1 downto 0);
    signal axi_awlock   : std_logic_vector(1 downto 0);
    signal axi_awcache  : std_logic_vector(3 downto 0);
    signal axi_awprot   : std_logic_vector(2 downto 0);
    signal axi_awqos    : std_logic_vector(3 downto 0);

    signal axi_wvalid   : std_logic;
    signal axi_wready   : std_logic;
    signal axi_wdata    : std_logic_vector(127 downto 0);
    signal axi_wstrb    : std_logic_vector(15 downto 0);
    signal axi_wlast    : std_logic;

    signal axi_arvalid  : std_logic;
    signal axi_arready  : std_logic;
    signal axi_araddr   : std_logic_vector(63 downto 0);
    signal axi_arlen    : std_logic_vector(7 downto 0);
    signal axi_arsize   : std_logic_vector(2 downto 0);
    signal axi_arburst  : std_logic_vector(1 downto 0);
    signal axi_arlock   : std_logic_vector(1 downto 0);
    signal axi_arcache  : std_logic_vector(3 downto 0);
    signal axi_arprot   : std_logic_vector(2 downto 0);
    signal axi_arqos    : std_logic_vector(3 downto 0);

    signal axi_rvalid   : std_logic;
    signal axi_rready   : std_logic;
    signal axi_rdata    : std_logic_vector(127 downto 0);
    signal axi_rlast    : std_logic;
    signal axi_rresp    : std_logic_vector(1 downto 0);

    signal axi_bvalid   : std_logic;
    signal axi_bready   : std_logic;
    signal axi_bresp    : std_logic_vector(1 downto 0);

    -- signaux  de liaison pour l ajout de rgb_to_gray et gaussian_filter
    signal gray_valid                       : std_logic;
    signal gray_data                        : std_logic_vector(7 downto 0);
    signal gaussian_valid, gaussian_ready   : std_logic;
    signal gaussian_data                    : std_logic_vector(7 downto 0);
    signal conv_data_24                 : std_logic_vector(23 downto 0);
    
    -- flux final envoye au controleur VGA : brut ou filtre selon sel_sync2(1)
    signal vga_valid_in : std_logic;
    signal vga_data_in  : std_logic_vector(23 downto 0);
    
    signal vga_t_user   : std_logic;
-- generation du reset
begin

    reset_n_i <= not reset_i;   -- on a notre reset actif haut et bas
    
    sync_btn_rst : process(pxl_clk)
    begin
        if rising_edge(pxl_clk) then
            btn_rst_sync1 <= btn_rst_i;
            btn_rst_sync2 <= btn_rst_sync1;
            btn_rst_prev  <= btn_rst_sync2;
        end if;
    end process sync_btn_rst;
    

    -- le mux est sur l horloge pxl_clk (25 MHz)
    sync_sel : process(pxl_clk)
    begin
        if rising_edge(pxl_clk) then
            sel_sync1 <= sel_gpio_raw;
            sel_sync2 <= sel_sync1;
        end if;
    end process sync_sel;

    btn_rst_pulse <= btn_rst_sync2 and not btn_rst_prev;  -- front montant

    -- Reset : reset_i reste '1' pendant ~30s apres la configuration du FPGA , 
    -- puis repasse a '0' definitivement, sauf s'il est reamorce par un appui sur BTN1, 
    -- pendant les tests, une fois la DDR reellement prete. Vrai front
    -- observable, necessaire pour que le SmartConnect et l'IP DMA HLS 
    -- initialisent correctement leur logique de controle AXI/dataflow.
    reset_pulse_proc : process(pxl_clk)
    begin
        if rising_edge(pxl_clk) then
            if btn_rst_pulse = '1' then
                reset_i   <= '1';
                rst_cnt_i <= (others => '0');
                
            elsif reset_i = '1' then
                if rst_cnt_i = RESET_HOLD_CYCLES then
                    reset_i <= '0';
                else
                    rst_cnt_i <= rst_cnt_i + 1;
                end if;
                
            end if;
            
        end if;
        
    end process reset_pulse_proc;

    ps7_inst : design_1_wrapper
        port map (
            DDR_addr            => DDR_addr,            
            DDR_ba              => DDR_ba, 
            DDR_cas_n           => DDR_cas_n,
            DDR_ck_n            => DDR_ck_n,            
            DDR_ck_p            => DDR_ck_p, 
            DDR_cke             => DDR_cke,
            DDR_cs_n            => DDR_cs_n,            
            DDR_dm              => DDR_dm, 
            DDR_dq              => DDR_dq,
            DDR_dqs_n           => DDR_dqs_n,           
            DDR_dqs_p           => DDR_dqs_p, 
            DDR_odt             => DDR_odt,
            DDR_ras_n           => DDR_ras_n,           
            DDR_reset_n         => DDR_reset_n, 
            DDR_we_n            => DDR_we_n,
            FIXED_IO_ddr_vrn    => FIXED_IO_ddr_vrn,    
            FIXED_IO_ddr_vrp    => FIXED_IO_ddr_vrp,
            FIXED_IO_mio        => FIXED_IO_mio,        
            FIXED_IO_ps_clk     => FIXED_IO_ps_clk,
            FIXED_IO_ps_porb    => FIXED_IO_ps_porb,    
            FIXED_IO_ps_srstb   => FIXED_IO_ps_srstb,

            S_AXI_DMA_araddr  => axi_araddr,
            S_AXI_DMA_arburst => axi_arburst,
            S_AXI_DMA_arcache => axi_arcache,
            S_AXI_DMA_arlen   => axi_arlen,
            S_AXI_DMA_arlock  => axi_arlock(0 downto 0),
            S_AXI_DMA_arprot  => axi_arprot,
            S_AXI_DMA_arqos   => axi_arqos,
            S_AXI_DMA_arready => axi_arready,
            S_AXI_DMA_arsize  => axi_arsize,
            S_AXI_DMA_arvalid => axi_arvalid,
            S_AXI_DMA_awaddr  => axi_awaddr,
            S_AXI_DMA_awburst => axi_awburst,
            S_AXI_DMA_awcache => axi_awcache,
            S_AXI_DMA_awlen   => axi_awlen,
            S_AXI_DMA_awlock  => axi_awlock(0 downto 0),
            S_AXI_DMA_awprot  => axi_awprot,
            S_AXI_DMA_awqos   => axi_awqos,
            S_AXI_DMA_awready => axi_awready,
            S_AXI_DMA_awsize  => axi_awsize,
            S_AXI_DMA_awvalid => axi_awvalid,
            S_AXI_DMA_bready  => axi_bready,
            S_AXI_DMA_bresp   => axi_bresp,
            S_AXI_DMA_bvalid  => axi_bvalid,
            S_AXI_DMA_rdata   => axi_rdata,
            S_AXI_DMA_rlast   => axi_rlast,
            S_AXI_DMA_rready  => axi_rready,
            S_AXI_DMA_rresp   => axi_rresp,
            S_AXI_DMA_rvalid  => axi_rvalid,
            S_AXI_DMA_wdata   => axi_wdata,
            S_AXI_DMA_wlast   => axi_wlast,
            S_AXI_DMA_wready  => axi_wready,
            S_AXI_DMA_wstrb   => axi_wstrb,
            S_AXI_DMA_wvalid  => axi_wvalid,

            dma_axi_aclk        => pxl_clk,
            dma_axi_aresetn     => reset_n_i,
            select_gpio_tri_o   => sel_gpio_raw
            );
    
    -- horloge 125MHz => 25MHz
    clk_div_inst : clk_wiz_0
        port map (
            CLK_IN1  => CLK_I,
            CLK_OUT1 => pxl_clk
            );
    
    -- TPG
    tpg_inst : tpg
        port map (
            clk     => pxl_clk,
            reset   => reset_i,
            t_ready => vga_t_ready,
            t_valid => tpg_t_valid,
            t_data  => tpg_t_data
            );


    dma_inst : dma_video_src
        port map (
            clk     => pxl_clk,
            reset   => reset_i,
            t_ready => vga_t_ready,
            t_valid => dma_t_valid,
            t_data  => dma_t_data,
            t_last  => dma_t_last,
            t_user  => dma_t_user,

            m_axi_awvalid  => axi_awvalid,
            m_axi_awready  => axi_awready,
            m_axi_awaddr   => axi_awaddr,
            m_axi_awid     => open,
            m_axi_awlen    => axi_awlen,
            m_axi_awsize   => axi_awsize,
            m_axi_awburst  => axi_awburst,
            m_axi_awlock   => axi_awlock,
            m_axi_awcache  => axi_awcache,
            m_axi_awprot   => axi_awprot,
            m_axi_awqos    => axi_awqos,
            m_axi_awregion => open,

            m_axi_wvalid   => axi_wvalid,
            m_axi_wready   => axi_wready,
            m_axi_wdata    => axi_wdata,
            m_axi_wstrb    => axi_wstrb,
            m_axi_wlast    => axi_wlast,
            m_axi_wid      => open,

            m_axi_arvalid  => axi_arvalid,
            m_axi_arready  => axi_arready,
            m_axi_araddr   => axi_araddr,
            m_axi_arid     => open,
            m_axi_arlen    => axi_arlen,
            m_axi_arsize   => axi_arsize,
            m_axi_arburst  => axi_arburst,
            m_axi_arlock   => axi_arlock,
            m_axi_arcache  => axi_arcache,
            m_axi_arprot   => axi_arprot,
            m_axi_arqos    => axi_arqos,
            m_axi_arregion => open,

            m_axi_rvalid   => axi_rvalid,
            m_axi_rready   => axi_rready,
            m_axi_rdata    => axi_rdata,
            m_axi_rlast    => axi_rlast,
            m_axi_rid      => "0",
            m_axi_rresp    => axi_rresp,

            m_axi_bvalid   => axi_bvalid,
            m_axi_bready   => axi_bready,
            m_axi_bresp    => axi_bresp,
            m_axi_bid      => "0"
            );


    -- Selection de la source video par la PS ou le bouton carte
    mux_t_valid <= dma_t_valid when sel_sync2(0) = '1' or btn_i = '1' else tpg_t_valid;
    mux_t_data  <= dma_t_data  when sel_sync2(0) = '1' or btn_i = '1' else tpg_t_data;

    -- instanciation de gva_controller_rgb
    vga_inst : vga_controller_rgb
        port map (
            clk       => pxl_clk,
            reset     => reset_i,
            t_valid   => vga_valid_in,  -- signal final
            t_data    => vga_data_in,   -- data final
            hsync     => VGA_HS_O,
            vsync     => VGA_VS_O,
            t_ready   => vga_t_ready,
            video_out => vga_video_out,
            t_user    => vga_t_user
            );
    
    -- instanciation des modules de filtre
    gray_inst : rgb_to_gray
        port map (
            s_t_valid => mux_t_valid,       -- le slave t_valid vient du au mux_t_valid
            s_t_ready => open,              -- je laisse s_t_ready a open car il est deja traverse par vga_t_ready et les deux filtres laissent passer le ready
            s_t_data  => mux_t_data,        -- la data d entree du filtre gris est relie a la sortie du mux
            m_t_valid => gray_valid,        -- le master t_valid vient du filtre gray
            m_t_ready => gaussian_ready,    -- le master t_ready vient du filtre gaussien
            m_t_data  => gray_data          -- la data sort du filtre gray
            );
            
    gaussian_inst : gaussian_filter
    port map (
        clk       => pxl_clk,
        reset     => reset_i,
        s_t_valid => gray_valid,        -- le slave t_valid d entree vient du filtre gray
        s_t_ready => gaussian_ready,    -- le slave t_ready vient du filtre gaussien
        s_t_data  => gray_data,         -- la data d entree vient du filtre gray
        m_t_valid => gaussian_valid,    -- le master t_valid vient du filtre gaussien
        m_t_ready => vga_t_ready,       -- le master t_ready vient du controlleur vga
        m_t_data  => gaussian_data      -- la data sort du filtre gaussien
        );

    harris_inst : harris_filter
        port map (
            clk       => pxl_clk,
            reset     => reset_i,
            s_t_valid => gaussian_valid,
            s_t_ready => harris_ready,
            s_t_data  => gaussian_data,
            m_t_valid => harris_valid,
            m_t_ready => binar_ready,
            m_t_data  => harris_data
            );
            
    binar_inst : binarisation
        generic map (
            seuil => 8 -- seuil reglable
            )
        port map (
            s_t_valid => harris_valid,
            s_t_ready => binar_ready,
            s_t_data  => harris_data,
            m_t_valid => binar_valid,
            m_t_ready => vga_t_ready,
            m_t_data  => binar_data
            );
            
    -- le controlleur vga attend 24 bits, je duplique donc le signal sur R, G, et B
    -- j obtients 24 bits qui donne un gris
    conv_data_24 <= binar_data & binar_data & binar_data;
    
    -- Second multiplexeur (PL-DISP-003) : le bit 1 du registre PS choisit entre
    -- le flux brut en couleur et le flux passe dans la chaine de filtrage.
    -- Independant du bit 0, qui choisit la source (TPG ou DMA).
    vga_valid_in <= binar_valid     when sel_sync2(1) = '1' else mux_t_valid;
    vga_data_in  <= conv_data_24    when sel_sync2(1) = '1' else mux_t_data;  
    
    -- Le flux VGA n a que 4 bits par couleur, on garde les 4 bits de poids fort de chaque composante
    -- sur 8 bits les 4 bits de gauche sont le poids fort
    VGA_R <= vga_video_out(23 downto 20);
    VGA_G <= vga_video_out(15 downto 12);
    VGA_B <= vga_video_out(7 downto 4);
    
    -- routage de t_user pour stabiliser le flux dma
    vga_t_user <= dma_t_user when sel_sync2(0) = '1' or btn_i = '1' else '0';

end Behavioral;
