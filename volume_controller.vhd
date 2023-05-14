library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity volume_controller is
    Port ( aclk             : in STD_LOGIC;
           aresetn          : in STD_LOGIC;
           
		   m_axis_tvalid	: out STD_LOGIC;
		   m_axis_tdata	    : out STD_LOGIC_VECTOR(23 downto 0);
		   m_axis_tready	: in STD_LOGIC;

		   s_axis_tvalid	: in STD_LOGIC;
		   s_axis_tdata	    : in STD_LOGIC_VECTOR(23 downto 0);

           
           volume           : in STD_LOGIC_VECTOR (9 downto 0));
end volume_controller;

architecture Behavioral of volume_controller is

begin

	process(aclk,aresetn)

		begin
			
			if aresetn = 1 then
				volume <= (others => '0');

			elsif rising_edge(aclk) then

				if s_axis_tvalid = '1' then



			end if;

			


end Behavioral;
