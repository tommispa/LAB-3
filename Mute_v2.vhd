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

begin

    -- Faccio diventare il blocco del mute un blocco trasparente
    m_axis_tlast <= s_axis_tlast;
    s_axis_tready <= m_axis_tready;
    m_axis_tvalid <= s_axis_tvalid;

    -- Quando il segnale di mute è attivo assegno al master un vettore di zeri per mutare
    m_axis_tdata <= (others => '0') when mute_enable = '1' else s_axis_tdata; 
        
end architecture;
