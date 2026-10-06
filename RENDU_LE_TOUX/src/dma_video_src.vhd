----------------------------------------------------------------------------------
-- Module Name: dma_video_src - Behavioral
-- Habillage de l'IP Vitis HLS DMA24bUnit_mm2s (DMA_RGB24b__720__0/DMA_RGB24b) :
-- lit une image RGB888 640x480 en DDR par un port AXI4 maitre 128 bits et la
-- debite en flux video sur une interface simplifiee (t_valid/t_ready/t_data),
-- meme esprit que tpg.vhd, pour pouvoir la mixer avec le TPG dans top.vhd
-- (PL-IP-000 / futur mux PL-IP-002/003).
--
-- ap_start est cable a '1' en permanence : l'IP redemarre une nouvelle image
-- des que ap_idle repasse haut -> flux video continu, sans intervention du PS.
-- image_w/image_h/image_in (adresse de base) sont fixes en dur (constantes
-- ci-dessous), pas de registre AXI4-Lite pour l'instant.
--
-- Les signaux AXI4 "USER" (AWUSER/WUSER/ARUSER/RUSER/BUSER), ignores par le
-- SmartConnect/PS7 s'ils ne sont pas connectes, sont termines ici et ne
-- remontent pas vers top.vhd.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dma_video_src is
    port (
        clk       : in  std_logic;
        reset     : in  std_logic;  -- actif haut (converti en ap_rst_n en interne)
        t_ready   : in  std_logic;  -- vient du recepteur (mux -> vga_controller_rgb)
        t_valid   : out std_logic;
        t_data    : out std_logic_vector(23 downto 0);
        t_last    : out std_logic;  -- fin de ligne (debug/ILA, PL-IP-000)
        t_user    : out std_logic;  -- debut d'image (debug/ILA, PL-IP-000)

        -- port AXI4 maitre (m_axi_gmem de l'IP HLS), a router vers l'AXI SmartConnect
        -- ajoute dans design_1 (cf. scripts/add_hp0_smartconnect.tcl)
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
end dma_video_src;

architecture Behavioral of dma_video_src is

    component DMA24bUnit_mm2s is
        generic (
            C_M_AXI_GMEM_ADDR_WIDTH   : integer := 64;
            C_M_AXI_GMEM_ID_WIDTH     : integer := 1;
            C_M_AXI_GMEM_AWUSER_WIDTH : integer := 1;
            C_M_AXI_GMEM_DATA_WIDTH   : integer := 128;
            C_M_AXI_GMEM_WUSER_WIDTH  : integer := 1;
            C_M_AXI_GMEM_ARUSER_WIDTH : integer := 1;
            C_M_AXI_GMEM_RUSER_WIDTH  : integer := 1;
            C_M_AXI_GMEM_BUSER_WIDTH  : integer := 1;
            C_M_AXI_GMEM_USER_VALUE   : integer := 0;
            C_M_AXI_GMEM_PROT_VALUE   : integer := 0;
            C_M_AXI_GMEM_CACHE_VALUE  : integer := 3
            );
        port (
            ap_clk    : in  std_logic;
            ap_rst_n  : in  std_logic;
            ap_start  : in  std_logic;
            ap_done   : out std_logic;
            ap_idle   : out std_logic;
            ap_ready  : out std_logic;

            m_axi_gmem_AWVALID  : out std_logic;
            m_axi_gmem_AWREADY  : in  std_logic;
            m_axi_gmem_AWADDR   : out std_logic_vector(63 downto 0);
            m_axi_gmem_AWID     : out std_logic_vector(0 downto 0);
            m_axi_gmem_AWLEN    : out std_logic_vector(7 downto 0);
            m_axi_gmem_AWSIZE   : out std_logic_vector(2 downto 0);
            m_axi_gmem_AWBURST  : out std_logic_vector(1 downto 0);
            m_axi_gmem_AWLOCK   : out std_logic_vector(1 downto 0);
            m_axi_gmem_AWCACHE  : out std_logic_vector(3 downto 0);
            m_axi_gmem_AWPROT   : out std_logic_vector(2 downto 0);
            m_axi_gmem_AWQOS    : out std_logic_vector(3 downto 0);
            m_axi_gmem_AWREGION : out std_logic_vector(3 downto 0);
            m_axi_gmem_AWUSER   : out std_logic_vector(0 downto 0);

            m_axi_gmem_WVALID   : out std_logic;
            m_axi_gmem_WREADY   : in  std_logic;
            m_axi_gmem_WDATA    : out std_logic_vector(127 downto 0);
            m_axi_gmem_WSTRB    : out std_logic_vector(15 downto 0);
            m_axi_gmem_WLAST    : out std_logic;
            m_axi_gmem_WID      : out std_logic_vector(0 downto 0);
            m_axi_gmem_WUSER    : out std_logic_vector(0 downto 0);

            m_axi_gmem_ARVALID  : out std_logic;
            m_axi_gmem_ARREADY  : in  std_logic;
            m_axi_gmem_ARADDR   : out std_logic_vector(63 downto 0);
            m_axi_gmem_ARID     : out std_logic_vector(0 downto 0);
            m_axi_gmem_ARLEN    : out std_logic_vector(7 downto 0);
            m_axi_gmem_ARSIZE   : out std_logic_vector(2 downto 0);
            m_axi_gmem_ARBURST  : out std_logic_vector(1 downto 0);
            m_axi_gmem_ARLOCK   : out std_logic_vector(1 downto 0);
            m_axi_gmem_ARCACHE  : out std_logic_vector(3 downto 0);
            m_axi_gmem_ARPROT   : out std_logic_vector(2 downto 0);
            m_axi_gmem_ARQOS    : out std_logic_vector(3 downto 0);
            m_axi_gmem_ARREGION : out std_logic_vector(3 downto 0);
            m_axi_gmem_ARUSER   : out std_logic_vector(0 downto 0);

            m_axi_gmem_RVALID   : in  std_logic;
            m_axi_gmem_RREADY   : out std_logic;
            m_axi_gmem_RDATA    : in  std_logic_vector(127 downto 0);
            m_axi_gmem_RLAST    : in  std_logic;
            m_axi_gmem_RID      : in  std_logic_vector(0 downto 0);
            m_axi_gmem_RUSER    : in  std_logic_vector(0 downto 0);
            m_axi_gmem_RRESP    : in  std_logic_vector(1 downto 0);

            m_axi_gmem_BVALID   : in  std_logic;
            m_axi_gmem_BREADY   : out std_logic;
            m_axi_gmem_BRESP    : in  std_logic_vector(1 downto 0);
            m_axi_gmem_BID      : in  std_logic_vector(0 downto 0);
            m_axi_gmem_BUSER    : in  std_logic_vector(0 downto 0);

            STR_video_out_TDATA  : out std_logic_vector(23 downto 0);
            STR_video_out_TVALID : out std_logic;
            STR_video_out_TREADY : in  std_logic;
            STR_video_out_TKEEP  : out std_logic_vector(2 downto 0);
            STR_video_out_TSTRB  : out std_logic_vector(2 downto 0);
            STR_video_out_TUSER  : out std_logic_vector(0 downto 0);
            STR_video_out_TLAST  : out std_logic_vector(0 downto 0);

            image_w  : in std_logic_vector(11 downto 0);
            image_h  : in std_logic_vector(11 downto 0);
            image_in : in std_logic_vector(63 downto 0)
            );
    end component;

    -- Resolution fixe 640x480 (generics_n_options.h) et adresse de base de
    -- l'image en DDR : 1 MiB, zone libre tant qu'aucun OS/FSBL ne tourne.
    -- Image 640x480 RGB888 packee = 921 600 octets (0xE1000), tient largement
    -- avant le prochain MiB.
    constant IMAGE_W_c    : std_logic_vector(11 downto 0) := std_logic_vector(to_unsigned(640, 12));
    constant IMAGE_H_c    : std_logic_vector(11 downto 0) := std_logic_vector(to_unsigned(480, 12));
    -- 0x01000000 (16 MiB) plutot que 0x00100000 (1 MiB) : cette derniere est
    -- l'adresse de chargement par defaut des executables bare-metal Zynq et
    -- serait ecrasee par une appli chargee normalement en DDR.
    constant IMAGE_BASE_c : std_logic_vector(63 downto 0) := x"0000000001000000";

    signal ap_rst_n_i : std_logic;
    signal tlast_v    : std_logic_vector(0 downto 0);
    signal tuser_v    : std_logic_vector(0 downto 0);

    -- ap_ctrl_hs de l'IP HLS (etaient laisses "open" avant, donc invisibles
    -- pour le debug) : ap_idle='1' veut dire l'IP est prete/en attente de
    -- ap_start, ap_done pulse a la fin de chaque image.
    signal ap_done_i  : std_logic;
    signal ap_idle_i  : std_logic;
    signal ap_ready_i : std_logic;

    -- signaux AXI4 "USER", termines localement (non exposes vers top.vhd)
    signal awuser_i, wuser_i, aruser_i : std_logic_vector(0 downto 0);
    signal ruser_i, buser_i            : std_logic_vector(0 downto 0) := (others => '0');

    attribute mark_debug : string;
    attribute mark_debug of t_valid : signal is "true";
    attribute mark_debug of t_ready : signal is "true";
    attribute mark_debug of t_last  : signal is "true";
    attribute mark_debug of t_user  : signal is "true";

    -- Port AXI4 maitre (lecture DDR) : pour voir si le DMA emet une demande
    -- de lecture (ARVALID) et si elle obtient une reponse (ARREADY/RVALID).
    attribute mark_debug of m_axi_arvalid : signal is "true";
    attribute mark_debug of m_axi_arready : signal is "true";
    attribute mark_debug of m_axi_rvalid  : signal is "true";
    attribute mark_debug of m_axi_rready  : signal is "true";

    -- ap_ctrl_hs : est-ce que l'IP demarre seulement, ou reste bloquee avant
    -- meme de passer en non-idle ?
    attribute mark_debug of ap_done_i  : signal is "true";
    attribute mark_debug of ap_idle_i  : signal is "true";
    attribute mark_debug of ap_ready_i : signal is "true";
    attribute mark_debug of ap_rst_n_i : signal is "true";

begin

    ap_rst_n_i <= not reset;

    dma_inst : DMA24bUnit_mm2s
        port map (
            ap_clk   => clk,
            ap_rst_n => ap_rst_n_i,
            ap_start => '1',
            ap_done  => ap_done_i,
            ap_idle  => ap_idle_i,
            ap_ready => ap_ready_i,

            m_axi_gmem_AWVALID  => m_axi_awvalid,
            m_axi_gmem_AWREADY  => m_axi_awready,
            m_axi_gmem_AWADDR   => m_axi_awaddr,
            m_axi_gmem_AWID     => m_axi_awid,
            m_axi_gmem_AWLEN    => m_axi_awlen,
            m_axi_gmem_AWSIZE   => m_axi_awsize,
            m_axi_gmem_AWBURST  => m_axi_awburst,
            m_axi_gmem_AWLOCK   => m_axi_awlock,
            m_axi_gmem_AWCACHE  => m_axi_awcache,
            m_axi_gmem_AWPROT   => m_axi_awprot,
            m_axi_gmem_AWQOS    => m_axi_awqos,
            m_axi_gmem_AWREGION => m_axi_awregion,
            m_axi_gmem_AWUSER   => awuser_i,

            m_axi_gmem_WVALID   => m_axi_wvalid,
            m_axi_gmem_WREADY   => m_axi_wready,
            m_axi_gmem_WDATA    => m_axi_wdata,
            m_axi_gmem_WSTRB    => m_axi_wstrb,
            m_axi_gmem_WLAST    => m_axi_wlast,
            m_axi_gmem_WID      => m_axi_wid,
            m_axi_gmem_WUSER    => wuser_i,

            m_axi_gmem_ARVALID  => m_axi_arvalid,
            m_axi_gmem_ARREADY  => m_axi_arready,
            m_axi_gmem_ARADDR   => m_axi_araddr,
            m_axi_gmem_ARID     => m_axi_arid,
            m_axi_gmem_ARLEN    => m_axi_arlen,
            m_axi_gmem_ARSIZE   => m_axi_arsize,
            m_axi_gmem_ARBURST  => m_axi_arburst,
            m_axi_gmem_ARLOCK   => m_axi_arlock,
            m_axi_gmem_ARCACHE  => m_axi_arcache,
            m_axi_gmem_ARPROT   => m_axi_arprot,
            m_axi_gmem_ARQOS    => m_axi_arqos,
            m_axi_gmem_ARREGION => m_axi_arregion,
            m_axi_gmem_ARUSER   => aruser_i,

            m_axi_gmem_RVALID   => m_axi_rvalid,
            m_axi_gmem_RREADY   => m_axi_rready,
            m_axi_gmem_RDATA    => m_axi_rdata,
            m_axi_gmem_RLAST    => m_axi_rlast,
            m_axi_gmem_RID      => m_axi_rid,
            m_axi_gmem_RUSER    => ruser_i,
            m_axi_gmem_RRESP    => m_axi_rresp,

            m_axi_gmem_BVALID   => m_axi_bvalid,
            m_axi_gmem_BREADY   => m_axi_bready,
            m_axi_gmem_BRESP    => m_axi_bresp,
            m_axi_gmem_BID      => m_axi_bid,
            m_axi_gmem_BUSER    => buser_i,

            STR_video_out_TDATA  => t_data,
            STR_video_out_TVALID => t_valid,
            STR_video_out_TREADY => t_ready,
            STR_video_out_TKEEP  => open,
            STR_video_out_TSTRB  => open,
            STR_video_out_TUSER  => tuser_v,
            STR_video_out_TLAST  => tlast_v,

            image_w  => IMAGE_W_c,
            image_h  => IMAGE_H_c,
            image_in => IMAGE_BASE_c
            );

    t_last <= tlast_v(0);
    t_user <= tuser_v(0);

end Behavioral;
