library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity tp_fsm is
    generic (
        counter_max : positive := 199999999;
        nb_cycle    : positive := 3
    );
    port ( 
		clk       : in std_logic; 
        resetn    : in std_logic;
		restart   : in std_logic;
		led0_r    : out std_logic;
		led0_b    : out std_logic;
		led0_v    : out std_logic;
		led1_r    : out std_logic;
		led1_b    : out std_logic;
		led1_v    : out std_logic
     );
end tp_fsm;


architecture behavioral of tp_fsm is
    
    component cycle_counter
        generic (
            counter_max : positive := 199999999;
            nb_cycle    : positive := 3
        );
        port (
            clk        : in std_logic;
            resetn     : in std_logic;
            restart    : in std_logic;
            cycle_done : out std_logic;
            led_blink  : out std_logic
        );
    end component;
    
    -- On définit le nom de nos état
    type state is (idle, state_red, state_blue, state_green); --a modifier avec vos etats
    
    signal cycle_done       : std_logic;
    signal current_state    : state;  --etat dans lequel on se trouve actuellement
    signal next_state       : state;  --etat dans lequel on passera au prochain coup d'horloge
    signal led_blink        : std_logic;
    
	begin
    
    
    u_counter_cycle : cycle_counter
        generic map(
            counter_max => counter_max,
            nb_cycle    => nb_cycle
        )
        port map(
            clk         => clk,
            resetn      => resetn,
            restart     => restart,
            cycle_done  => cycle_done,
            led_blink   => led_blink
            );
            
         
		process(clk, resetn, restart)
		begin
            if(resetn = '1') then   -- si reset -> on passe à l'état initial
                current_state <= idle;
                
            elsif(restart = '1') then -- si restart -> on passe à l'état initial
                current_state <= idle;  
                   
			elsif(rising_edge(clk)) then -- si un cycle est complété on passe à l'état suivant
			     if (cycle_done = '1') then
				    current_state <= next_state;
				    
				 end if;
			
            end if;
		end process;
		
		
		
		
		-- FSM
		process(current_state, led_blink) --a completer avec vos signaux
		begin		
           case current_state is
              when idle =>
                 led0_r <= led_blink;   -- On controle les états avec led_blink pour faire clignoter les leds à chaque fin de compteur de cycle
                 led0_b <= led_blink;
                 led0_v <= led_blink;
                 led1_r <= led_blink;
                 led1_b <= led_blink;
                 led1_v <= led_blink;
			     next_state <= state_red; --prochain etat
				
                --signaux pilotes par la fsm
              
              when state_red => 
				next_state <= state_blue;
				led0_r <= led_blink;
                led0_b <= '0';
                led0_v <= '0';
                led1_r <= led_blink;
                led1_b <= '0';
                led1_v <= '0';
                --signaux pilotes par la fsm
              
              when state_blue => 
				next_state <= state_green;
				led0_r <= '0';
                led0_b <= led_blink;
                led0_v <= '0';
                led1_r <= '0';
                led1_b <= led_blink;
                led1_v <= '0';
                
			  when state_green => 
				next_state <= state_red;
				led0_r <= '0';
                led0_b <= '0';
                led0_v <= led_blink;
                led1_r <= '0';
                led1_b <= '0';
                led1_v <= led_blink;
                --signaux pilotes par la fsm
              
              
              end case;
              
		end process;		

end behavioral;