library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Mute_v2 is
    Port ( 
		m_axis_tlast	: out STD_LOGIC; -- Segnale che mi dice se sto ricevendo da canale di destra o di sinistra
		m_axis_tvalid	: out STD_LOGIC;
		m_axis_tdata	: out STD_LOGIC_VECTOR(23 downto 0);
		m_axis_tready	: in STD_LOGIC;
		   
		s_axis_tlast 	: in STD_LOGIC; -- Segnale che arriva dall'IS_2, che mi dice se sto ricevendo left channel o rigth channel
		s_axis_tvalid	: in STD_LOGIC;
		s_axis_tdata	: in STD_LOGIC_VECTOR(23 downto 0);
		s_axis_tready	: out STD_LOGIC;

        mute_enable     : in STD_LOGIC);
end Mute_v2;

architecture rtl of Mute_v2 is

    -- Segnale intermedio per mute eneable: essendo quest'ultimo un impulso utilizziamo questo
	-- registro per capire se dobbiamo applicare il filtro o meno
    signal mute_enable_reg : STD_LOGIC_VECTOR(23 downto 0) := (others => '0'); 

begin

    m_axis_tlast <= s_axis_tlast;
    s_axis_tready <= m_axis_tready;
    m_axis_tvalid <= s_axis_tvalid;

    process (mute_enable)

    begin
        
        if mute_enable = '1' then
            mute_enable_reg <= not mute_enable_reg;
        end if;

        m_axis_tdata <= s_axis_tdata and mute_enable_reg;

    end process;

    

end architecture;
