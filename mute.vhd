library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mute is
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
end mute;

architecture Behavioral of mute is

	-- Segnale intermedio per mute eneable: essendo quest'ultimo un impulso utilizziamo questo
	-- registro per capire se dobbiamo applicare il filtro o meno
	signal mute_enable_reg : STD_LOGIC := '0';


begin

	process(m_axis_tready,s_axis_tlast,s_axis_tvalid,s_axis_tdata,mute_enable)
		
		begin
			
			-- Con mute_enable_reg capisco quando devo applicare il filtro, in quanto in  
			-- uscita dall'edge_detector ho un impulso e non un segnale costante
			if mute_enable = '1' then
				mute_enable_reg <= not mute_enable_reg;
			end if;

			-- Caso in cui ho il filtro attivo
			if mute_enable_reg = '1' then
				
				s_axis_tready <= '1';

				if s_axis_tvalid = '1' then
					
					-- Muto il canale sinistro dell'audio
					if s_axis_tlast = '0' then
						
						if m_axis_tready = '1' then
							
							m_axis_tvalid <= '1';
							m_axis_tlast <= '0';
							m_axis_tdata <= (others => '0');

						end if;

					-- Muto il canale destro dell'audio
					else
						
						if m_axis_tready = '1' then
							
							m_axis_tvalid <= '1';
							m_axis_tlast <=  '1';
							m_axis_tdata <= (others => '0');

						end if;

					end if;

				end if;
			
			-- Caso in cui non ho il filtro attivo
			else
				
				s_axis_tready <= '1';

				if s_axis_tvalid = '1' then
					
					-- Faccio passare i dati sul canale sinistro dell'audio
					if s_axis_tlast = '0' then
						
						if m_axis_tready = '1' then
							
							m_axis_tvalid <= '1';
							m_axis_tlast <= '0';
							m_axis_tdata <= s_axis_tdata;

						end if;

					-- Faccio passare i dati sul canale destro dell'audio
					else
						
						if m_axis_tready = '1' then
							
							m_axis_tvalid <= '1';
							m_axis_tlast <=  '1';
							m_axis_tdata <= s_axis_tdata;

						end if;
					end if;
				end if;

			end if;
							
	end process;

end Behavioral;


