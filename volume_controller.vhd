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

	type state_volume_type is (clipping, control, amplification, attenuation, send, pass);
	signal state_volume : state_volume_type;


	signal		num_of_step_y		: 	signed(9 downto 0) := (others => '0');
	constant 	step_div 			: 	integer := 2**division_step;
	constant    step_div2   		: 	integer := 2**(division_step-1);
	signal		zero_vol			: 	signed(9 downto 0) := (others => '0');
	signal      one_vol         	: 	signed(9 downto 0) := (others => '1');
	constant	max_step 			: 	integer := (512/step_div) - 1;
	signal		data				: 	signed(23 downto 0) := (others => '0');
	signal		s_axis_tdata_int	:	signed (23 downto 0) := (others => '0');
	signal		volume_int			: 	signed (9 downto 0) := (others => '0');
	signal		t_last_reg			:	std_logic;
	signal		mem_data			:	std_logic_vector (23 downto 0) := (others => '0');
	signal		mem_volume			:	std_logic_vector (9 downto 0) := (others => '0');

begin

	mem_data <= s_axis_tdata;
	s_axis_tdata_int <= signed(mem_data);
	mem_volume <= volume;
	volume_int <= signed(mem_volume);

	with state_volume select s_axis_tready <=
		'1' when clipping,
		'0' when control,
		'0' when amplification,
		'0' when attenuation,
		'0' when send,
		m_axis_tready when pass;

	with state_volume select m_axis_tvalid <=
		'0' when clipping,
		'0' when control,
		'0' when amplification,
		'0' when attenuation,
		'1' when send,
		s_axis_tvalid when pass;
		
	process (aclk, aresetn)

	
		begin

			if aresetn = '0' then
		
				-- Resetto i segnali con cui gestisco la comunicazione fra i blocchi
				s_axis_tready <= '0';
		
				m_axis_tlast <= '0';
				m_axis_tvalid <= '0';
				m_axis_tdata <= (others => '0'); 
			
			elsif rising_edge(aclk) then

				case state_volume is

					when clipping =>

						if s_axis_tvalid = '1' then

							data <= shift_right(s_axis_tdata_int,6);

							t_last_reg <= s_axis_tlast;

							state_volume <= control;
						
						end if;


					when control =>
						if volume_int >= step_div2 then
							state_volume <= amplification;
						

						elsif volume_int < step_div2 then
							state_volume <= attenuation;
						
						else
							state_volume <= pass;
						
						end if;


					when amplification =>
							
						num_of_step_y <= zero_vol(division_step downto 1) & volume_int(9 downto division_step);													
																									
						gen_loop: for i in 1 to max_step loop

							if i <= to_integer(signed(num_of_step_y)) then

								s_axis_tdata_int <= s_axis_tdata_int(s_axis_tdata_int'high-1 downto 0) & '0';

							end if;

						end loop gen_loop;

						state_volume <= send;

					
					when attenuation =>

						num_of_step_y <= one_vol(division_step downto 1) & volume_int(9 downto division_step);
							
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

						state_volume <= send;


					when send =>
						if m_axis_tready = '1' then
							
							m_axis_tlast <= t_last_reg;
							m_axis_tdata <= std_logic_vector(s_axis_tdata_int(23 downto 0));
								
						end if;
						state_volume <= clipping;


					when pass =>
						if m_axis_tready = '1' then
									
							m_axis_tlast <= s_axis_tlast;
							m_axis_tdata <= s_axis_tdata;

						end if;
						state_volume <= clipping;


				end case;
			end if;			
	end process;

end Behavioral;