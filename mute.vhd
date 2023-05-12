library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mute is
    Port ( 
		m_axis_tvalid	: out STD_LOGIC;
		m_axis_tdata	: out STD_LOGIC_VECTOR(23 downto 0);
		m_axis_tready	: in STD_LOGIC;

		s_axis_tvalid	: in STD_LOGIC;
		s_axis_tdata	: in STD_LOGIC_VECTOR(23 downto 0);

        mute_enable     : in STD_LOGIC);
end mute;

architecture Behavioral of mute is

begin


end Behavioral;
