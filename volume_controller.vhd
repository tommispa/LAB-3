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

	-- Macchina a stati con cincque stati
	-- Fetch: prende il dato in ingresso e lo carica su una memoria
	-- Control: verifico se il dato in ingresso e' da amplificare, attenuare o lasciare invariato
	-- Amplification: amplifico il segnale di quanto necessario
	-- Attenuation: attenuo il segnale di quanto necessario
	-- Send: fa uscire il dato dal bus dati del master
	type state_volume_type is (fetch, control, amplification, attenuation, send);
	signal state_volume : state_volume_type;

	-- Registro in cui salvo quante volte devo shiftare il vettore per moltiplicare o dividere
	signal		num_of_step_y		: 	integer := 0;

	-- Costanti che servono per le varie operazioni, commentare bene
	constant 	step_div 			: 	integer := 2**division_step;
	constant    step_div2   		: 	integer := 2**(division_step-1) + 512;
	constant	shift				:	integer := 512/step_div;
	
	-- Questi segnali li dovremmo poter eliminare
	signal		zero_vol			: 	unsigned(9 downto 0) := (others => '0');
	signal      one_vol         	: 	unsigned(9 downto 0) := (others => '1');
	constant	max_step 			: 	integer := (512/step_div) - 1;

	-- Registro in cui salvo il valore del tlast associato al segnale in ingresso
	signal		t_last_reg			:	std_logic;
	-- Registro in cui salvo il valore del dato in ingresso tramite s_axis_tdata nella sua forma corretta, ovvero SIGNED
	signal		mem_data			:	signed(23 downto 0) := (others => '0');
	-- Regsitro in cui salvo il valore del dato in ingresso tramite volume nella sua forma corretta, ovvero UNSIGNED
	signal		mem_volume			:	unsigned(9 downto 0) := (others => '0');

begin

	-- Alzo il segnale s_axis_tready solamente quando devo prendere il dato
	with state_volume select s_axis_tready <=
		'1' when fetch,
		'0' when control,
		'0' when amplification,
		'0' when attenuation,
		'0' when send;

	-- Alzo il segnale m_axis_tvalid solamente quando devo mandare il dato al blocco successivo
	with state_volume select m_axis_tvalid <=
		'0' when fetch,
		'0' when control,
		'0' when amplification,
		'0' when attenuation,
		'1' when send;
		
	process (aclk, aresetn)

	
		begin
			
			-- Se si abbassa il segnale di reset inizializzo tutti i registri
			if aresetn = '0' then
		
				mem_data <= (others => '0');
				mem_volume <= (others => '0');
				t_last_reg <= '0';
				num_of_step_y <= 0; 

				state_volume <= fetch;
			
			elsif rising_edge(aclk) then

				case state_volume is

					when fetch =>

						if s_axis_tvalid = '1' then
							
							mem_data <= SIGNED(s_axis_tdata);
							t_last_reg <= s_axis_tlast;
							mem_volume <= UNSIGNED(volume);

							state_volume <= control;
						end if;		

					when control =>
						
						if mem_volume >= step_div2 then
							state_volume <= amplification;
						

						elsif mem_volume < step_div2-step_div then
							-- Costante che mi permette di calcolare di quanto devo shiftare 
							-- mem_data per avere l'attenuazione/amplificazione desiderata
							num_of_step_y <= -(to_integer(shift_right(mem_volume,division_step)) - shift); 

						state_volume <= attenuation;

						else
							state_volume <= send;
						
						end if;


					when amplification =>

						mem_data <= shift_left(mem_data, num_of_step_y); -- non si puo' implementare cosi' perche' non tiene conto dell'overflow
						
						--gen_loop: for i in 1 to max_step loop

							--if i <= num_of_step_y then

							--	mem_data <= mem_data(mem_data'high-1 downto 0) & '0';

							--end if;

						--end loop gen_loop;

						state_volume <= send;

					
					when attenuation =>
							
						mem_data <= shift_right(mem_data,num_of_step_y);

						state_volume <= send;


					when send =>
						
						if m_axis_tready = '1' then
							
							m_axis_tlast <= t_last_reg;
							m_axis_tdata <= std_logic_vector(mem_data(23 downto 0));
								
							state_volume <= fetch;
						end if;

				end case;
			end if;			
	end process;

end Behavioral;