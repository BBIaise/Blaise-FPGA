library ieee;
use ieee.std_logic_1164.all;

entity tb_tp_fsm is
end tb_tp_fsm;

architecture behavioral of tb_tp_fsm is

	signal resetn      : std_logic := '0';
	signal clk         : std_logic := '0';
	signal btn0        : std_logic := '0';
	signal led0_r       : std_logic;	
	signal led1_g       : std_logic;


	-- Horloge 
	constant hp : time := 5 ns;      -- half period de 5ns
	constant period : time := 2*hp;
	
	component tp_fsm
	   generic (
	       counter_max : positive
	    );
		port ( 
			clk			 : in std_logic; 
			resetn		 : in std_logic;
			btn0 	     : in std_logic;
			led0_r       : out std_logic;
			led1_g       : out std_logic
		 );
	end component;
	
	begin
	dut: tp_fsm
	   generic map (
	       counter_max => 1
	       )
        port map (
            clk => clk, 
            resetn => resetn,
			btn0 => btn0,
            led0_r => led0_r,
            led1_g => led1_g
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
	    wait for period;
		btn0 <= '1';
		wait for period*2;
		assert (led0_r = '0' and led1_g = '1')
			report "Erreur : La leds verte n'est pas allumée"
		    severity error;
		    
		wait for period*2;
		assert (led0_r = '0' and led1_g = '0')
		  report "Erreur : la led verte ne c'est pas éteinte"
		  severity error;
		
		-- test leds rouges
		wait for period*2;
		btn0 <= '0';
		wait for period*2;
		assert (led0_r = '1' and led1_g = '0')
	       report "Erreur : la led rouge n'est pas allumée"
		   severity error;
		wait for period*2;
		assert (led0_r = '0'and led1_g = '0')
		      report "Erreur : la led rouge ne clignote pas"
		      severity error;
	   
		wait;
	    
	end process;
	
	
end behavioral;