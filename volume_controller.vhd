library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;


entity volume_controller is
	generic (
		division_step	: integer RANGE 0 to 9 := 6				-- Numero n, l'amplification factor deve essere diviso per 2 ogni 2^n joystick units		
	);
    Port ( aclk             : in STD_LOGIC;
           aresetn          : in STD_LOGIC;
           
		   m_axis_tlast		: out STD_LOGIC; -- Segnale che mi dice se sto ricevendo da canale di destra o di sinistra
		   m_axis_tvalid	: out STD_LOGIC;
		   m_axis_tdata	    : out STD_LOGIC_VECTOR(23 downto 0);
		   m_axis_tready	: in STD_LOGIC;
		   
		   s_axis_tlast 	: in STD_LOGIC; -- Segnale che arriva dall'IS_2, che mi dice se sto ricevendo left channel o rigth channel
		   s_axis_tvalid	: in STD_LOGIC;
		   s_axis_tdata	    : in STD_LOGIC_VECTOR(23 downto 0);
		   s_axis_tready	: out STD_LOGIC;

           
           volume           : in STD_LOGIC_VECTOR (9 downto 0));
end volume_controller;

architecture Behavioral of volume_controller is


	signal 		jstk_pos 	: signed(9 downto 0) := (others => '0');
	signal		data_sig 	: signed(23 downto 0) := (others => '0');
	signal		num_of_step	: signed(9 downto 0) := (others => '0');
	constant 	step_div 	: integer := 2**division_step;
	signal 		init		: std_logic := '0';
	signal		discriminator :	std_logic := '0';



begin

	jstk_pos <= signed(volume);
	data_sig <= signed(s_axis_tdata);
	
	process (aclk, aresetn)
	
		begin

			if aresetn = '0' then

				jstk_pos <= (others => '0');
				data_sig <= (others => '0');
		
				-- Resetto i segnali con cui gestisco la comunicazione fra i blocchi
				s_axis_tready <= '0';
		
				m_axis_tlast <= '0';
				m_axis_tvalid <= '0';
				m_axis_tdata <= (others => '0'); 
			
			elsif rising_edge(aclk) then

				s_axis_tready <= '1';
		
				if s_axis_tvalid = '1' then
		
					if discriminator /= s_axis_tlast or init = '0' then

						init <= '1';

						discriminator <= s_axis_tlast;
		
						if jstk_pos >= step_div then			-- se il joystick si muove verso l'alto, il volume deve aumentare
									
							num_of_step <= (others => '0') & jstk_pos(9 downto division_step-1);													
						
							if data_sig < 0 then																					--questo if else puo' sicuramente essere ottimizzato (anche quello successivo)

								data_sig <= data_sig(23-to_integer(signed(num_of_step)) downto 0) & (others => '0');
								
								data_sig(23) <= '1';
							
							else

								data_sig <= data_sig(23-to_integer(signed(num_of_step)) downto 0) & (others => '0');
							
							end if;
		
							if m_axis_tready = '1' then
		
								m_axis_tvalid <= '1';
								m_axis_tlast <= '0';
								m_axis_tdata <= std_logic_vector(data_sig(23 downto 0));
							
							end if;
						end if;

						if jstk_pos < step_div then			-- se il joystick si muove verso il basso, il volume deve diminuire
								
							num_of_step <= (others => '0') & jstk_pos(9 downto division_step-1);
						
							if data_sig < 0 then

								data_sig <= (others => '0') & data_sig(23 downto to_integer(signed(num_of_step)));
								
								data_sig(23) <= '1';
								
							else
								
								data_sig <= (others => '0') & data_sig(23 downto to_integer(signed(num_of_step)));
						
							end if;
		
							if m_axis_tready = '1' then
		
								m_axis_tvalid <= '1';
								m_axis_tlast <= '0';
								m_axis_tdata <= std_logic_vector(data_sig(23 downto 0));
							
							end if;
						end if;
		
					else
						
						if m_axis_tready = '1' then
									
							m_axis_tvalid <= '1';
							m_axis_tlast <= '0';
							m_axis_tdata <= s_axis_tdata;

						end if;

					end if;
		
				end if;
			end if;

	end process;

end Behavioral;
