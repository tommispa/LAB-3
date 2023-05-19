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
    
    begin

        led_r <= (others => '1') when mute_enable = '1' else (others => '0'); 
                 
        led_b <= (others => '1') when filter_enable = '1' and mute_enable = '0' else (others => '0');
                     
        led_g <= (others => '1') when filter_enable = '0' and mute_enable = '0' else (others => '0');
            
end Behavioral;
