library ieee;
use ieee.std_logic_1164.all;

entity tb_tp_fsm is
end tb_tp_fsm;

architecture behavioral of tb_tp_fsm is

	signal resetn      : std_logic := '0';
	signal clk         : std_logic := '0';
	signal restart     : std_logic := '0';
	signal led0_r       : std_logic;
	signal led0_v       : std_logic;
	signal led0_b       : std_logic;
	signal led1_r       : std_logic;
	signal led1_v       : std_logic;
	signal led1_b       : std_logic;

	-- Horloge 
	constant hp : time := 5 ns;      -- half period de 5ns
	constant period : time := 2*hp;
	
	component tp_fsm
	   generic (
	       counter_max : positive;
	       nb_cycle : positive
	    );
		port ( 
			clk			: in std_logic; 
			resetn		: in std_logic;
			restart 	: in std_logic;
			led0_r       : out std_logic;
			led0_v       : out std_logic;
			led0_b       : out std_logic;
			led1_r       : out std_logic;
			led1_v       : out std_logic;
			led1_b       : out std_logic
		 );
	end component;
	
	begin
	dut: tp_fsm
	   generic map (
	       counter_max => 1,
	       nb_cycle => 3
	       )
        port map (
            clk => clk, 
            resetn => resetn,
			restart => restart,
            led0_r => led0_r,
            led0_b => led0_b,
            led0_v => led0_v,
            led1_r => led1_r,
            led1_b => led1_b,
            led1_v => led1_v
        );
		
	--Simulation du signal d'horloge en continue
	process
    begin
		wait for hp;
		clk <= not clk;
	end process;


	process
	begin        
	    -- test du reset, les leds doivent être blanches
		resetn <= '1';
		wait for period;
		resetn <= '0';
		wait for period*2;
		assert (led0_r = '1' and led0_b = '1' and led0_v = '1' and led1_r = '1' and led1_b = '1' and led1_v = '1')
			report "Erreur : les leds ne sont pas blanches"
		    severity error;
		wait for period*2;
		assert (led0_r = '0' and led0_b = '0' and led0_v = '0' and led1_r = '0' and led1_b = '0' and led1_v = '0')
		      report "Erreur : les leds ne clignotent pas en blanc"
		      severity error;
		
		-- test leds rouges
		wait for period*11;
		assert (led0_r = '1' and led0_b = '0' and led0_v = '0' and led1_r = '1' and led1_b = '0' and led1_v = '0')
	       report "Erreur : les leds ne sont pas rouges"
		   severity error;
		wait for period*2;
		assert (led0_r = '0' and led0_b = '0' and led0_v = '0' and led1_r = '0' and led1_b = '0' and led1_v = '0')
		      report "Erreur : les leds ne clignotent pas en rouge"
		      severity error;
		
		-- test leds bleues   
		wait for period*9;
		assert (led0_r = '0' and led0_b = '1' and led0_v ='0' and led1_r = '0' and led1_b = '1' and led1_v ='0')
	       report "Erreur : les leds ne sont pas bleues" 
		   severity error;
	   wait for period*2;
	   assert (led0_r = '0' and led0_b = '0' and led0_v = '0' and led1_r = '0' and led1_b = '0' and led1_v = '0')
		      report "Erreur : les leds ne clignotent pas en bleu"
		      severity error;
		      
	   -- test leds vertes
	   wait for period*10;
	   assert (led0_r = '0' and led0_b = '0' and led0_v = '1' and led1_r = '0' and led1_b = '0' and led1_v = '1')
	       report "Erreur : les leds ne sont pas vertes" 
		   severity error;
	   wait for period*2;
	   assert (led0_r = '0' and led0_b = '0' and led0_v = '0' and led1_r = '0' and led1_b = '0' and led1_v = '0')
		      report "Erreur : les leds ne clignotent pas en vert"
		      severity error;
		      
	   -- test btn restart
	   resetn <= '1';
	   wait for period;
	   resetn <= '0';
	   wait for period*20;
	   restart <= '1';
	   wait for period;
	   restart <= '0';
	   wait for period*2;
	   assert (led0_r = '1' and led0_b = '1' and led0_v = '1' and led1_r = '1' and led1_b = '1' and led1_v = '1')
			report "Erreur : les leds ne sont pas blanches"
		    severity error;
	   
		wait;
	    
	end process;
	
	
end behavioral;