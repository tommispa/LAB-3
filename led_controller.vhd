library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity led_controller is
    Port (
            mute_enable : in STD_LOGIC;
            filter_enable : in STD_LOGIC;

            led_r : out STD_LOGIC_VECTOR (7 downto 0);
            led_g : out STD_LOGIC_VECTOR (7 downto 0);
            led_b : out STD_LOGIC_VECTOR (7 downto 0);

            
            s_axis_tvalid	: in STD_LOGIC;
            s_axis_tdata	: in STD_LOGIC_VECTOR(23 downto 0);
            s_axis_tready	: out STD_LOGIC;

            aclk : in STD_LOGIC          
        
          );
end led_controller;

architecture Behavioral of led_controller is

    signal color_vect : std_logic_vector(23 downto 0) := (others => '0') ;
    
    begin
    
    process (aclk)

        begin
        led_r <= color_vect(7 downto 0);
        led_b <= color_vect(15 downto 8);
        led_g <= color_vect(23 downto 16);

            if s_axis_tvalid = '1' then

                if mute_enable = '1' then
                    color_vect(7 downto 0) <= s_axis_tdata; 
                end if; 

                if filter_enable = '1' then
                    color_vect(15 downto 8) <= s_axis_tdata; 
                end if; 

                if (mute_enable = '1') and (filter_enable = '1') then
                    color_vect(7 downto 0) <= s_axis_tdata; 
                end if; 

                color_vect(23 downto 16) <= s_axis_tdata; 
            end if; 
        end process; 

end Behavioral;
