library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mute is
    Port ( 
		m_axis_tvalid	: out STD_LOGIC;
		m_axis_tdata	: out STD_LOGIC_VECTOR(23 downto 0);
		m_axis_tready	: in STD_LOGIC;
		m_axis_tlast	: out STD_LOGIC; -- Segnale che mando all'IS_2 per dirgli se il pacchetto che mando è left channel o rigth channel

		s_axis_tvalid	: in STD_LOGIC;
		s_axis_tready   : out STD_LOGIC;
		s_axis_tdata	: in STD_LOGIC_VECTOR(23 downto 0);

        mute_enable     : in STD_LOGIC);
end mute;

architecture Behavioral of mute is

	signal data	:	STD_LOGIC_VECTOR(23 downto 0) := (others => '0');

begin

	process(all)
		begin

			if s_axis_tvalid = '1' then
				data  <= (not mute_enable) and s_axis_tdata; -- L'audio passa se mute_enable è 0
				m_axis_tvalid <= '1';
				if m_axis_tready = '1' then
					m_axis_tdata <= data;
				end if;
			end if;

	end process;

end Behavioral;


