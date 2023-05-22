library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

entity balance_controller is

	generic (
		division_step	: integer RANGE 0 to 9 := 6				-- Numero n, l'amplification factor deve essere diviso per 2 ogni 2^n joystick units		
	);

    Port ( 
         aclk           : in STD_LOGIC;
         aresetn        : in STD_LOGIC;
        
		 m_axis_tlast	: out STD_LOGIC; 						-- Segnale che mi dice se sto ricevendo da canale di destra o di sinistra
		 m_axis_tvalid	: out STD_LOGIC;
		 m_axis_tdata	: out STD_LOGIC_VECTOR(23 downto 0);
		 m_axis_tready	: in STD_LOGIC;
		 
		 s_axis_tlast 	: in STD_LOGIC; 						-- Segnale che arriva dall'IS_2, che mi dice se sto ricevendo left channel o rigth channel
		 s_axis_tvalid	: in STD_LOGIC;
		 s_axis_tdata	: in STD_LOGIC_VECTOR(23 downto 0);
		 s_axis_tready	: out STD_LOGIC;
         
		 balance        : in STD_LOGIC_VECTOR (9 downto 0));

end balance_controller;


architecture Behavioral of balance_controller is
	-- Registro in cui salvo quante volte devo shiftare il vettore per moltiplicare o dividere
	signal		num_of_step_x	: integer := 0;

	signal      zero            : signed(9 downto 0)  := (others => '0');
	signal      one             : signed(9 downto 0) := (others => '1');
    signal      data_sig        : signed(23 downto 0) := signed(s_axis_tdata);
    signal      balance_int     : signed(9 downto 0) := signed(balance);
	constant 	step_div 	    : integer := 2**division_step;
	constant    step_div2       : integer := 2**(division_step-1) + 512;
	constant	shift			: integer := 512/step_div;
	constant	max_step        : integer := (512/step_div) - 1;

	type state_balance_type is (fetch, control, left_channel, right_channel, send);
	signal state_balance : state_balance_type;
	
	-- Registro in cui salvo il valore del tlast associato al segnale in ingresso
	signal		t_last_reg			:	std_logic;

	-- Registro in cui salvo il valore del dato in ingresso tramite s_axis_tdata nella sua forma corretta, ovvero SIGNED
	signal		mem_data			:	signed(23 downto 0) := (others => '0');
	-- Regsitro in cui salvo il valore del dato in ingresso tramite balance nella sua forma corretta, ovvero UNSIGNED
	signal		mem_balance			:	unsigned(9 downto 0) := (others => '0');

begin

	with state_balance select s_axis_tready <=
		'1' when fetch,
		'0' when control,
		'0' when left_channel,
		'0' when right_channel,
		'0' when send;

	with state_balance select m_axis_tvalid <=
		'0' when fetch,
		'0' when control,
		'0' when left_channel,
		'0' when right_channel,
		'1' when send;


	process (aclk, aresetn)
	
	
		begin

			if aresetn = '0' then
               
                mem_balance <= (others => '0');
				mem_data <= (others => '0');
				t_last_reg <= '0';
				num_of_step_x <= 0;
				
				state_balance <= fetch;

            elsif rising_edge(aclk) then
                
				case state_balance is
					
					when fetch =>
						
						if s_axis_tvalid = '1' then
							
							mem_data <= SIGNED(s_axis_tdata);
							t_last_reg <= s_axis_tlast;
							mem_balance <= UNSIGNED(balance);

						end if;
					
					when control =>

						if mem_balance >= step_div2 then
							state_balance <= left_channel;
						

						elsif mem_balance < step_div2-step_div then
							state_balance <= right_channel;
						
						else
							state_balance <= send;
						
						end if;

					when left_channel =>
						
						num_of_step_x <= to_integer(shift_right(mem_balance,division_step)) - shift;
					
						-- Bisogna implementare lo shift

						state_balance <= send;

					when right_channel =>
						
						num_of_step_x <= to_integer(shift_right(mem_balance,division_step)) - shift;					
						-- Bisogna implmentare lo shift

						state_balance <= send;

					when send =>
						
						if m_axis_tready = '1' then
							
							m_axis_tlast <= t_last_reg;
							m_axis_tdata <= std_logic_vector(mem_data(23 downto 0));
							
							state_balance <= fetch;
						end if;

				end case;
----------------------------------------------------------------------------------------------------------------------------------				
				s_axis_tready <= '1';

                if s_axis_tvalid = '1' then
		
					-------------- dato sx --------------
					if s_axis_tlast = '0' then
		
						if balance_int >= step_div2 then			-- se il joystick si muove verso dx devo abbassare il volume a sx
		
							
							num_of_step_x <= zero(division_step downto 1) & (balance_int(balance_int'high downto division_step));
							
							if data_sig < 0 then
								gen_loop: for i in 1 to max_step loop

									if i <= to_integer(signed(num_of_step_x)) then

										data_sig <= '1' & (data_sig(data_sig'high downto 1));

									end if;
								end loop gen_loop;

							else
							 
							    gen_loop2: for i in 1 to max_step loop

								    if i <= to_integer(signed(num_of_step_x)) then

									    data_sig <= '0' & (data_sig(data_sig'high downto 1));

								    end if;
							    end loop gen_loop2;

                            end if;

                            if m_axis_tready = '1' then

                                m_axis_tvalid <= '1';
                                m_axis_tlast <= '0';
                                m_axis_tdata <= std_logic_vector(data_sig(23 downto 0));
                            
                            end if;
   

                        else

                            if m_axis_tready = '1' then

                                m_axis_tvalid <= '1';
                                m_axis_tlast <= '0';
                                m_axis_tdata <= s_axis_tdata;

                            end if;
						
								
						end if;
		
					-------------- dato dx --------------
					if s_axis_tlast = '1' then
		
						if balance_int <= -step_div2 then
							
							num_of_step_x <= one(division_step downto 1) & (balance_int(balance_int'high downto division_step));
		
							if data_sig < 0 then
								
								gen_loop3: for i in 1 to max_step loop

									if i <= to_integer(signed(num_of_step_x)) then

										data_sig <= '1' & (data_sig(data_sig'high downto 1));

									end if;
								end loop gen_loop3;
								
							else

							gen_loop4: for i in 1 to max_step loop

								if i <= to_integer(signed(num_of_step_x)) then

									data_sig <= '0' & (data_sig(data_sig'high downto 1));

								end if;
							end loop gen_loop4;

                            end if;

                            if m_axis_tready = '1' then

                                m_axis_tvalid <= '1';
                                m_axis_tlast <= '0';
                                m_axis_tdata <= std_logic_vector(data_sig(23 downto 0));
                            
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
			end if;
			end if;
	end process;
end Behavioral;