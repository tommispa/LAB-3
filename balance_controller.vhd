library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


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


	signal 		jstk_pos 	: signed(9 downto 0) := (others => '0');
	signal		data_out 	: signed(23 downto 0) := (others => '0');
	signal		num_of_step	: signed(9 downto 0) := (others => '0');
	constant 	step_div 	: integer := 2**division_step;
	constant	max_step_sx	: integer := 512/step_div;					-- da migliorare e verificare
	constant	max_step_dx : integer := -512/step_div;



begin

	jstk_pos <= signed(balance);
	data_sig <= signed(s_axis_tdata);

	if aresetn = '0' then

		jstk_pos <= (others => '0');
		data_sig <= (others => '0');


		-- Resetto i segnali con cui gestisco la comunicazione fra i blocchi
		s_axis_tready <= '0';

		m_axis_tlast <= '0';
		m_axis_tvalid <= '0';
		m_axis_tdata <= (others => '0'); 
		

	elsif rising_edge(aclk) then

		s_axis_tready = '1';

		if s_axis_tvalid = '1' then

			-------------- dato sx --------------
			if s_axis_tlast = '0' then

				if jstk_pos >= step_div then			-- se il joystick si muove verso dx devo abbassare il volume a sx

					for i in 0 to division_step-1 loop
						num_of_step <= 0 & jstk_pos(9-i downto 0);
					end loop;
				
					for j in 1 to max_step_sx loop
					
						if j = to_integer(signed(num_of_step)) then			-- da capire se serva realmente l'if, visto da chatGPT
							data_sig <= 0 & data_sig(23-j downto 0);
						end if;

					end loop;

					if m_axis_tready = '1' then

						m_axis_tvalid <= '1';
						m_axis_tlast <= '0';
						m_axis_tdata <= std_logic_vector(data_sig(23 downto 0));
					
					end if;

				elsif (jstk_pos >= 0) & (jstk_pos < step_div) then
					if m_axis_tready = '1' then
						
						m_axis_tvalid <= '1';
						m_axis_tlast <= '0';
						m_axis_tdata <= s_axis_tdata;
					end if;
				end if;
				end if;

				
				
			end if;

			-------------- dato dx --------------
			if s_axis_tlast = '1' then

				if jstk_pos <= -step_div then

					for i in 0 to division_step loop
						num_of_step <= 1 & jstk_pos(9-i downto 0);
					end loop;

					for j in 1 to max_step_dx loop
					
						if j = to_integer(signed(num_of_step)) then			-- da capire se serva realmente l'if, visto da chatGPT
							data_sig <= 0 & data_sig(23-j downto 0);
						end if;
					end loop;

					if m_axis_tready = '1' then

						m_axis_tvalid <= '1';
						m_axis_tlast <= '1';
						m_axis_tdata <= std_logic_vector(data_sig(23 downto 0));
					
					end if;

				elsif (jstk_pos <= 0) & (jstk_pos > -step_div) then
					if m_axis_tready = '1' then
						
						m_axis_tvalid <= '1';
						m_axis_tlast <= '1';
						m_axis_tdata <= s_axis_tdata;
					end if;
				end if;

			end if;

		end if;

				

end Behavioral;