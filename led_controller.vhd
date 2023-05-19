library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity led_controller is
    Port (
            mute_enable : in STD_LOGIC;
            filter_enable : in STD_LOGIC;

            led_r : out STD_LOGIC_VECTOR (7 downto 0);
            led_g : out STD_LOGIC_VECTOR (7 downto 0);
            led_b : out STD_LOGIC_VECTOR (7 downto 0)
        
          );
end led_controller;

architecture Behavioral of led_controller   is

    -- Segnale intermedio per mute eneable: essendo quest'ultimo un impulso utilizziamo questo
	-- registro per capire se dobbiamo applicare il filtro o meno
	signal mute_enable_reg : STD_LOGIC := '0';

    -- Segnale intermedio per filter eneable: essendo quest'ultimo un impulso utilizziamo questo
    -- registro per capire se dobbiamo applicare il filtro o meno
    signal filter_enable_reg : STD_LOGIC := '0';

    -- Vettore dove salvo i colori da assegnare alle tre uscite
    signal color_vect : std_logic_vector(23 downto 0) := (others => '0') ;
    
    begin

        led_r <= color_vect(7 downto 0);
        led_b <= color_vect(15 downto 8);
        led_g <= color_vect(23 downto 16);
        

    
        process (mute_enable, filter_enable)

            begin

                -- Con filter_enable_reg capisco quando devo applicare il filtro, in quanto in  
	            -- uscita dall'edge_detector ho un impulso e non un segnale costante
	            if filter_enable = '1' then
                filter_enable_reg <= (not filter_enable_reg);
                end if;
    
                -- Con mute_enable_reg capisco quando devo applicare il filtro, in quanto in  
                -- uscita dall'edge_detector ho un impulso e non un segnale costante
                if mute_enable = '1' then
                mute_enable_reg <= not mute_enable_reg;
                end if;

                if mute_enable_reg = '1' then
                    color_vect <= X"FF0000"; 
                
                elsif filter_enable_reg = '1' and mute_enable = '0' then
                    color_vect <= X"0000FF"; 

                else
                    color_vect <= X"00FF00"; 
                end if; 
        
        end process; 

end Behavioral;
