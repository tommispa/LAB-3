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


	signal		num_of_step_y	: signed(9 downto 0) := (others => '0');
	constant 	step_div 	: integer := 2**division_step;
	constant    step_div2   : integer := 2**(division_step-1);
	signal		zero_vol		: signed(9 downto 0) := (others => '0');
	signal      one_vol         : signed(9 downto 0) := (others => '1');
	constant	max_step : integer := (512/step_div) - 1;
	signal		data	: signed(23 downto 0) := (others => '0');
	signal		s_axis_tdata_int	:	signed (23 downto 0) := signed(s_axis_tdata);
	signal		volume_int		: signed (9 downto 0) := signed(volume);

begin

	
	process (aclk, aresetn)

	
		begin

			if aresetn = '0' then
		
				-- Resetto i segnali con cui gestisco la comunicazione fra i blocchi
				s_axis_tready <= '0';
		
				m_axis_tlast <= '0';
				m_axis_tvalid <= '0';
				m_axis_tdata <= (others => '0'); 
			
			elsif rising_edge(aclk) then

				s_axis_tready <= '1';
		
				if s_axis_tvalid = '1' then

					data <= shift_right(s_axis_tdata_int,6);
		
					if s_axis_tdata_int >= step_div2 then			-- se il joystick si muove verso l'alto, il volume deve aumentare
									
						num_of_step_y <= zero_vol(division_step downto 1) & signed(volume)(9 downto division_step);													
																								
						gen_loop: for i in 1 to max_step loop

							if i <= to_integer(signed(num_of_step_y)) then

								s_axis_tdata_int <= s_axis_tdata_int(s_axis_tdata_int'high-1 downto 0) & '0';

							end if;

						end loop gen_loop;
						
						end if;
	
						if m_axis_tready = '1' then
	
							m_axis_tvalid <= '1';
							m_axis_tlast <= s_axis_tlast;
							m_axis_tdata <= std_logic_vector(s_axis_tdata_int(23 downto 0));
						
						end if;
					

					elsif signed(volume) < step_div2 then			-- se il joystick si muove verso il basso, il volume deve diminuire
							
						num_of_step_y <= one_vol(division_step downto 1) & signed(volume)(9 downto division_step);
						
						if s_axis_tdata_int < 0 then

							gen_loop2: for i in 1 to max_step loop

								if i <= to_integer(signed(num_of_step_y)) then

									s_axis_tdata_int <= '1' & s_axis_tdata_int(s_axis_tdata_int'high downto 1);

								end if;

							end loop gen_loop2;
							
							
						else
							
							gen_loop3: for i in 1 to max_step loop

								if i <= to_integer(signed(num_of_step_y)) then

									s_axis_tdata_int <= '0' & s_axis_tdata_int(s_axis_tdata_int'high downto 1);

								end if;

							end loop gen_loop3;						
							end if;
		
						if m_axis_tready = '1' then
	
							m_axis_tvalid <= '1';
							m_axis_tlast <= s_axis_tlast;
							m_axis_tdata <= std_logic_vector(s_axis_tdata_int(23 downto 0));
						
						end if;
					

					else
						
						if m_axis_tready = '1' then
									
							m_axis_tvalid <= '1';
							m_axis_tlast <= s_axis_tlast;
							m_axis_tdata <= s_axis_tdata;

						end if;

					end if;
		
				end if;

	end process;

end Behavioral;