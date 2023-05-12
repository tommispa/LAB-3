library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity led_controller is
    Port ( mute_enable : in STD_LOGIC;
           filter_enable : in STD_LOGIC;
           led_r : out STD_LOGIC_VECTOR (7 downto 0);
           led_g : out STD_LOGIC_VECTOR (7 downto 0);
           led_b : out STD_LOGIC_VECTOR (7 downto 0));
end led_controller;

architecture Behavioral of led_controller is

begin


end Behavioral;
