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

architecture Behavioral of led_controller is

    signal color_vect : std_logic_vector(23 downto 0) := (others => '0') ;
    
    begin

        led_r <= color_vect(7 downto 0);
        led_b <= color_vect(15 downto 8);
        led_g <= color_vect(23 downto 16);       
    
        process (mute_enable,filter_enable)

            begin

                if mute_enable = '1' then
                    color_vect <= X"FF0000"; 
                
                elsif filter_enable = '1' and mute_enable = '0' then
                    color_vect <= X"0000FF"; 

                else
                    color_vect <= X"00FF00"; 
                end if; 
        
        end process; 

end Behavioral;
