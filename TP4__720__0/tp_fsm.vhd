library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity tp_fsm is
    generic (
        counter_max : positive := 199999999
    );
    port ( 
		clk       : in std_logic; 
        resetn    : in std_logic;
		btn0      : in std_logic;
		led0_r    : out std_logic;
		led1_g    : out std_logic
     );
end tp_fsm;


architecture behavioral of tp_fsm is
    
    component cycle_counter
        generic (
            counter_max : positive := 199999999
        );
        port (
            clk        : in std_logic;
            resetn     : in std_logic;
            led_blink  : out std_logic
        );
    end component;
    
    -- On definit le nom de nos etats
    type state is (idle_green, state_red); --a modifier avec vos etats
    
    signal current_state    : state;  -- etat dans lequel on se trouve actuellement
    signal next_state       : state;  -- etat dans lequel on passera au prochain coup d'horloge
    signal led_blink        : std_logic;
    signal blinker          : std_logic;
    signal has_blinked      : std_logic;
    
    
	begin
    
    u_counter_cycle : cycle_counter
        generic map(
            counter_max => counter_max
        )
        port map(
            clk         => clk,
            resetn      => resetn,
            led_blink   => led_blink
            );
            
         
		process(clk, resetn, btn0)
		begin
            if(resetn = '1') then   -- si reset -> on passe a l'etat initial
                current_state <= idle_green;
                
            elsif(btn0 = '1') then -- si restart -> on passe a l'etat initial
                current_state <= idle_green;  
                   
			elsif rising_edge(clk) then -- sinon on passe au prochain etat
                current_state <= next_state;    

            end if;
		end process;
		
		process(clk, resetn)
        begin
         if resetn = '1' then
             blinker <= '0';    -- blinker va garder l'etat precedent de led_blink
             has_blinked <= '0';    -- has_blinked va prendre pour valeur 1 lorsque blinker et led_blink auront une valeur differente
         elsif rising_edge(clk) then
             blinker <= led_blink;  -- On memorise led_blink

             if current_state = state_red then
                    has_blinked <= '0';     -- Remise de has_blinked a 0 quand l'etat retourne a rouge
             elsif current_state = idle_green and blinker = '1' and led_blink = '0' then -- si on est dans l'etat idle_green et blinker et led_blink sont different
                    has_blinked <= '1';  -- has_blinked passe a 1
                end if;
            end if;
        end process;
        
        
		-- machine a etat
		process(current_state, btn0, led_blink, has_blinked) --a completer avec vos signaux
		begin
           case current_state is
              when idle_green =>
                    led0_r <= '0';   -- On controle les etats avec led_blink pour faire clignoter les leds a chaque fin de compteur de cycle
                    if (has_blinked = '1') then -- si la led a deja clignote alors sa valeur passe a 0 sinon led_blink
                        led1_g <= '0';
                    else led1_g <= led_blink;
                    end if;

                    if (btn0 = '0') then -- si btn0 est enfonce, le prochain etat est rouge
                     next_state <= state_red;
                 else
                     next_state <= idle_green; -- sinon vert
                 end if;

              when state_red =>
                 led0_r <= led_blink; -- quand l'etat est rouge, la led0 est controle par led_blink et la led1 passe a 0
                 led1_g <= '0';
                 if (btn0 = '1') then -- l'etat change quand le btn1 est appuye
                     next_state <= idle_green;
                 else
                     next_state <= state_red;
                 end if;
              end case;
              
		end process;		

end behavioral;