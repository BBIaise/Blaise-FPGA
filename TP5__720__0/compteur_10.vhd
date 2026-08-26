library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

    -- creation d'une nouvelle entite compteur pour compter le nombre de end_cycle
    -- et ainsi piloter le code couleur et le signal update
entity compteur_10 is
    generic ( 
            max_10 : positive :=10 -- le compteur compte 11 cycle de end_cycle, avec un compteur jusqu'a 10 la led change de couleur avant d effectuer sont dernier clignotement, je prend donc un compteur 11
            );    
    Port ( 
        clk          : in STD_LOGIC;
        resetn       : in STD_LOGIC;
        update       : out STD_LOGIC;
        color_code   : out STD_LOGIC_VECTOR(1 DOWNTO 0);
        end_cycle    : in STD_LOGIC
        );
        
end compteur_10;

architecture Behavioral of compteur_10 is
    
    component update_stretcher 
        generic (
         period_clkB : positive := 6
            );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;
            trigger             : in std_logic;
            stretched_update    : out std_logic
            );
    end component;
    
    
    -- un signal pour compter jusqu'a 10
    signal counter_10 : std_logic_vector(3 downto 0);
    
    -- un signal pour envoyer la bonne sequence de couleur dans color_code
    signal active_color : std_logic_vector(1 downto 0);
    
    -- un signal intermediaire de trigger et de stretched_update
    signal trigger_i            : std_logic;
    signal stretched_update_i   : std_logic;
    
    -- j ajoute un signal pour maintenir le color_code a une certaine valeur
    -- car j ai remarque que souvent le premier cycle sautait une couleur
    signal color_hold : std_logic_vector(1 downto 0);
    
begin
    
    u_update_stretcher : update_stretcher
        port map(
            clk                 => clk,
            resetn              => resetn,
            trigger             => trigger_i,
            stretched_update    => stretched_update_i
            );
    
    
    process(clk, resetn)
        begin
            if resetn = '1' then
                counter_10 <= (others => '0');  -- reset a 1 -> compteur a 0
                active_color <= "01";           -- active_color est sur rouge au debut
                color_hold <= "11";             -- j initialise mon signal a la prochaine couleur
                
            elsif rising_edge(clk) then     -- chaque action ci dessous sera effectue sur le meme front d'horloge
                if (counter_10 = max_10) then
                    counter_10 <= (others => '0');  -- si le compteur atteint son max, on le remet a 0
                    
                    -- cette sequence est active que lorsque le compteur vient d'etre remis a 0
                    if active_color = "01" then     -- si la couleur etait rouge, elle passe au bleu
                        active_color <= "11";
                        color_hold <= "11";
                        
                    elsif active_color = "11" then  -- si la couleur etait bleue, elle passe au vert
                        active_color <= "10";
                        color_hold <= "10";
                        
                    elsif active_color = "10" then  -- si la couleur etait verte, elle passe au rouge
                        active_color <= "01";
                        color_hold <= "01";
                    end if;
                    
                elsif end_cycle = '1' then
                    counter_10 <= counter_10 + 1;   -- si le compteur n'etait pas a son max alors on incremente counter_10
                
                 end if;
            end if;
        end process;
    
    
    trigger_i <= '1' when counter_10 = max_10 else '0';
    update <= stretched_update_i;    
    
    -- comme tout est teste sur le meme front d'horloge, la couleur rouge durait 2 cycle avant de lancer la sequence correcte
    -- mais avec cette ligne en plus, on calcule la valeur de active_color en meme temps qu'elle change et donc
    -- color_code prend en permanence la valeur de la prochaine couleur et on a donc plus ce probleme
    color_code <= color_hold; 
    
end behavioral;   
