library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

    -- creation d'une nouvelle entite compteur pour compter le nombre de end_cycle
    -- et ainsi piloter le code couleur et le signal update
entity update_stretcher is
    generic ( 
            period_clkB : positive :=6 -- le compteur compte 5 cycles de clkA
            );    
    Port ( 
        clk              : in STD_LOGIC;
        resetn           : in STD_LOGIC;
        trigger          : in STD_LOGIC;    -- ancien signal update
        stretched_update : out std_logic    -- signal update etire
        );
        
end update_stretcher;

architecture Behavioral of update_stretcher is    
  
    -- un signal pour rester � 1 tant que la periode clkB n est pas finit
    signal hold : std_logic;
    -- compteur
    signal counter : std_logic_vector(2 downto 0);
    
begin
   
            
    process(clk, resetn)
        begin
            if resetn = '1' then
                hold    <= '0';
                counter <= (others => '0');  
             
            -- quand trigger passe a 1, hold passe a 1 et le compteur est remis a 0
            -- hold reste a 1 le temps que le compteur atteigne son but   
            elsif rising_edge(clk) then     
                if trigger = '1' then
                    hold    <= '1';
                    counter <= (others => '0');  
                    
                elsif hold = '1' then
                    if counter = period_clkB then
                        hold <= '0';
                        counter <= (others => '0');
                    else
                        counter <= counter + 1;   
                    
                    end if;        
                 end if;
            end if;
        end process;
    
    -- de cette maniere, on a un signal strectched_update qui commence quand un cycle 
    -- de 10 clignotements est realise et qui s arrete apres 5 periodes de clkA
    stretched_update <= hold or trigger;
    
   
end behavioral;   
