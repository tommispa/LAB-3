library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dual_mooving_average is
    Port ( aclk             : in STD_LOGIC;
           aresetn          : in STD_LOGIC;
           
		   m_axis_tvalid	: out STD_LOGIC;
		   m_axis_tdata	    : out STD_LOGIC_VECTOR(23 downto 0);
		   m_axis_tready	: in STD_LOGIC;

		   s_axis_tvalid	: in STD_LOGIC;
		   s_axis_tdata	    : in STD_LOGIC_VECTOR(23 downto 0);

           
           filter_enable    : in STD_LOGIC);
end dual_mooving_average;

architecture Behavioral of dual_mooving_average is

begin


end Behavioral;
