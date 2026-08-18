library ieee;
use ieee.std_logic_1164.all;

entity pilote_led_driver is
    generic (
        counter_max : positive := 49999999 -- j'ai choisie un compteur maximum assez haut afin de pouvoir voir le clignotement à l'oeil nu
    );
    port (
        clk    : in  std_logic;
        resetn : in  std_logic;
        btn0   : in  std_logic;
        btn1   : in  std_logic;
        led0_r : out std_logic;
        led0_g : out std_logic;
        led0_b : out std_logic
    );
end pilote_led_driver;

architecture behavioral of pilote_led_driver is

    component LED_driver
        generic (
            counter_max : positive
        );
        port (
            clk        : in  std_logic;
            resetn     : in  std_logic;
            color_code : in  std_logic_vector(1 downto 0);
            update     : in  std_logic;
            led0_r     : out std_logic;
            led0_g     : out std_logic;
            led0_b     : out std_logic;
            end_cycle  : out std_logic
        );
    end component;
    
    -- implementation du composant fifo_generator
    COMPONENT fifo_generator_0
        PORT (
            clk   : IN  STD_LOGIC;
            srst  : IN  STD_LOGIC;
            din   : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
            wr_en : IN  STD_LOGIC;
            rd_en : IN  STD_LOGIC;
            dout  : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            full  : OUT STD_LOGIC;
            empty : OUT STD_LOGIC
        );
    END COMPONENT;

    signal btn0_d      : std_logic; -- btn0_d sera l'etat de btn0 au cycle precedent, il va servir a incrementer update
    signal btn0_m      : std_logic; -- sera pilote par btn0 et not btn0_d, il detectera les front montants de btn0
    signal color_code  : std_logic_vector(1 downto 0);
    
    -- ajout des signaux suivant afin d'instancier les composants
    signal end_cycle   : std_logic;
    signal dout        : std_logic_vector(1 downto 0);
    signal empty       : std_logic;
    signal read_en     : std_logic;

begin

    -- detecteur de front montant sur btn0 : btn0_m ne pulse qu'1 cycle
    process(clk, resetn)
    begin
        if resetn = '1' then
            btn0_d <= '0'; -- btn0_d est reset a 0 apres un reset
        elsif rising_edge(clk) then
            btn0_d <= btn0; -- btn0_d prend la valeur de btn0 a chaque front d'horloge
        end if;
    end process;
    
    -- btn0_m passe à 1 que lorsque btn0 et not btn0_d sont à 1, soit le moment où le bouton 0 est enfonce et
    -- et le court instant où le btn0_d n'a pas encore pris la valeur de btn0 au prochain front d'horloge
    -- de cette facon, on obtient un btn0_m a 1 que lorsque le bouton 0 vient d'etre appuye et pas plus longtemps
    -- de plus cette commande n'est dans aucun process pour quelle soit verifie tous le temps
    btn0_m <= btn0 and not btn0_d;
    -- color_code suit btn1 en direct : vert si appuye, bleu sinon
    color_code <= "10" when btn1 = '1' else "11";
    read_en <= end_cycle and not empty;

    u_led_driver : LED_driver
        generic map (
            counter_max => counter_max
        )
        port map (
            clk        => clk,
            resetn     => resetn,
            color_code => dout,     -- J'envois dout dans le port color_code de LED_driver
            update     => read_en,  -- pilotage de update avec le nouveau signal read_en, afin de ne pas udpate si la file d'attente est vide
            led0_r     => led0_r,
            led0_g     => led0_g,
            led0_b     => led0_b,
            end_cycle  => end_cycle -- ajout de end_cycle dans led_driver
        );
        
    -- Instantiation du composant FIFO
    u_fifo : fifo_generator_0
        port map (
            clk     => clk,
            srst    => resetn,      -- permet de piloter la FIFO en meme temps que le reste du code
            din     => color_code,  -- din prend la valeur du signal actuelle de color_code
            wr_en   => btn0_m,      -- on ne peut ecrire dans la fifo que lors d'un front montant de btn0
            rd_en   => read_en,     -- permet de ne pas lire la fifo lorsqu'elle est vide
            dout    => dout,
            full    => open,        -- je n'ai pas utiliser le full dans ce code, mais j'ai compris qu'il servait en cas de fifo pleine
            empty   => empty
            );
            
end behavioral;
