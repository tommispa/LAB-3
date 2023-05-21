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

	signal		num_of_step_x	: signed(9 downto 0)  := (others => '0');
	signal      zero            : signed(9 downto 0)  := (others => '0');
	signal      one             : signed(9 downto 0) := (others => '1');
    signal      data_sig        : signed(23 downto 0) := (others => '0');
	constant 	step_div 	    : integer := 2**division_step;
	constant    step_div2       : integer := 2**(division_step-1);
	constant	max_step        : integer := (512/step_div) - 1;



begin

	
	process (aclk, aresetn)
	
	
		begin

			if aresetn = '0' then

				balance <= (others => '0');
				s_axis_tdata <= (others => '0');
                
                -- Resetto i segnali con cui gestisco la comunicazione fra i blocchi

                s_axis_ready <= '0';
                m_axis_tlast <= '0';
                m_axis_tvalid <= '0';
                m_axis_tdata <= (others => '0');


            elsif rising_edge(aclk) then

                s_axis_tready <= '1';

                if s_axis_tvalid = '1' then
		
					-------------- dato sx --------------
					if s_axis_tlast = '0' then
		
						if signed(balance) >= step_div2 then			-- se il joystick si muove verso dx devo abbassare il volume a sx
		
							
							num_of_step_x <= zero(division_step downto 1) & (signed(balance)(signed(balance)'high downto division_step));
							
							if signed(s_axis_tdata) < 0 then
								gen_loop: for i in 1 to max_step loop

									if i <= to_integer(signed(num_of_step_x)) then

										data_sig <= '1' & (signed(s_axis_tdata)(signed(s_axis_tdata)'high downto 1));

									end if;
								end loop gen_loop;

							else
							 
							    gen_loop2: for i in 1 to max_step loop

								    if i <= to_integer(signed(num_of_step_x)) then

									    data_sig <= '0' & (signed(s_axis_tdata)(signed(s_axis_tdata)'high downto 1));

								    end if;
							    end loop gen_loop2;

                            end if;

                            if m_axis tready = '1' then

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
		
						if signed(balance) <= -step_div2 then
							
							num_of_step_x <= one(division_step downto 1) & (signed(balance)(signed(balance)'high downto division_step));
		
							if signed(s_axis_tdata) < 0 then
								
								gen_loop3: for i in 1 to max_step loop

									if i <= to_integer(signed(num_of_step_x)) then

										data_sig <= '1' & (signed(s_axis_tdata)(signed(s_axis_tdata)'high downto 1));

									end if;
								end loop gen_loop3;
								
							else

							gen_loop4: for i in 1 to max_step loop

								if i <= to_integer(signed(num_of_step_x)) then

									data_sig <= '0' & (signed(s_axis_tdata)(signed(s_axis_tdata)'high downto 1));

								end if;
							end loop gen_loop4;

                            end if;

                            if m_axis tready = '1' then

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
	end process;
end Behavioral;