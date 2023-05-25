library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;


entity volume_controller is
	generic (
		division_step		:     INTEGER RANGE 0 to 9 := 6	-- Numero n, l'amplification factor deve essere diviso per 2 ogni 2^n joystick units		
	);
    Port ( aclk             : in  STD_LOGIC;
           aresetn          : in  STD_LOGIC;
           
		   m_axis_tlast		: out STD_LOGIC; -- Segnale che mi dice se sto ricevendo da canale di destra o di sinistra
		   m_axis_tvalid	: out STD_LOGIC;
		   m_axis_tdata	    : out STD_LOGIC_VECTOR(23 downto 0);
		   m_axis_tready	: in  STD_LOGIC;
		   
		   s_axis_tlast 	: in  STD_LOGIC; -- Segnale che arriva dall'IS_2, che mi dice se sto ricevendo left channel o rigth channel
		   s_axis_tvalid	: in  STD_LOGIC;
		   s_axis_tdata	    : in  STD_LOGIC_VECTOR(23 downto 0);
		   s_axis_tready	: out STD_LOGIC;

           
           volume           : in STD_LOGIC_VECTOR (9 downto 0));
end volume_controller;

architecture Behavioral of volume_controller is

	-- Macchina a stati con cincque stati
	-- Fetch: prende il dato in ingresso e lo carica su una memoria
	-- Control: verifico se il dato in ingresso e' da amplificare, attenuare o lasciare invariato
	-- Amplification: amplifico il segnale di quanto necessario
	-- Attenuation: attenuo il segnale di quanto necessario
	-- Send: periodo di clock in cui avviene la trasmissione
	type state_volume_type is (fetch, control, amplification, attenuation, send);
	signal state_volume : state_volume_type := fetch;
	
	-- Costante che mi calcola quanto sono grandi gli step di attenuazione
	constant 	step_div 			: 	INTEGER RANGE 0 TO 512   := 2**division_step;
	-- Costante che mi pone al limite tra lo step 0 e lo step +1
	-- Il range di questo integer e' stato leggermente sovrastimato approssimandolo alla potenza di due piu' vicina
	constant    shift   			: 	INTEGER RANGE 0 TO 1024  := 2**(division_step-1) + 512;
	-- Costante che mi serve per calcolare di quanto devo shiftare il
	-- vettore per ottenere l'attenauazione/amplificazione desiderata
	constant	offset				:	INTEGER RANGE 0 TO 512   := 512/step_div;
	
	-- Registro che serve a contare il numero di shift quando vado nello stato dell'amplificazione per evitare overflow
	-- Il range di questo integer e' stato leggermente sovrastimato approssimandolo alla potenza di due piu' vicina
	signal		counter				:	INTEGER RANGE 0 TO 1024 := 0;
	-- Registro in cui salvo quante volte devo shiftare il vettore per moltiplicare o dividere
	-- Il range di questo integer e' stato leggermente sovrastimato approssimandolo alla potenza di due piu' vicina
	signal		num_of_step_y		: 	INTEGER RANGE 0 TO 1024 := 0;
	-- Registro in cui salvo il valore del tlast associato al segnale in ingresso
	signal		t_last_reg			:	STD_LOGIC;
	-- Registro in cui salvo il valore del dato in ingresso tramite s_axis_tdata nella sua forma corretta, ovvero SIGNED
	signal		mem_data			:	SIGNED(23 downto 0) 	:= (others => '0');
	-- Regsitro in cui salvo il valore del dato in ingresso tramite volume nella sua forma corretta, ovvero UNSIGNED
	signal		mem_volume			:	UNSIGNED(9 downto 0) 	:= (others => '0');

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
						
						if mem_volume >= shift then
							
							-- Costante che mi permette di calcolare di quanto devo shiftare 
							-- mem_data per avere l'attenuazione/amplificazione desiderata
							num_of_step_y <= to_integer(shift_right(mem_volume,division_step)) - offset; 
							
							state_volume <= amplification;

						elsif mem_volume < shift-step_div then
							
							-- Costante che mi permette di calcolare di quanto devo shiftare 
							-- mem_data per avere l'attenuazione/amplificazione desiderata
							num_of_step_y <= -(to_integer(shift_right(mem_volume,division_step)) - offset); 

							state_volume <= attenuation;

						else

							-- Se il joystick non si e' mosso mando direttamente in uscita i dati
							m_axis_tdata <= s_axis_tdata;
							m_axis_tlast <= t_last_reg;		

							state_volume <= send;
						
						end if;

					-- L'operazione di amplificazione e' stata gestita in maniera differente 
					-- dall'attenuazione per poter gestire piu' facilmente il clipping
					when amplification =>

							-- Se il counter arriva al numero di shift che devo eseguire mando il segnale e resetto il counter
							if counter = num_of_step_y then
								
								-- Assegno in questo stato m_axis_tdata e m_axis_tlast in modo da rispettare l'handshake
								m_axis_tlast <= t_last_reg;
								m_axis_tdata <= std_logic_vector(mem_data(23 downto 0));
								counter <= 0;

								state_volume <= send;

							else
								
								-- Caso in cui eseguendo un ulteriore shift ho overflow
								if mem_data(mem_data'high) /= mem_data(mem_data'high-1) then

									-- Se il dato e' negativo clippo m_axis_tdata al massimo numero negativo
									if mem_data(mem_data'high) = '1' then
										
										-- Assegno in questo stato m_axis_tdata e m_axis_tlast in modo da rispettare l'handshake
										m_axis_tdata <= (m_axis_tdata'high => '1', others => '0');
										m_axis_tlast <= t_last_reg;
										counter <= 0;

										state_volume <= send;
									
									-- Se il dato e' positivo clippo m_axis_tdata al massimo numero positivo
									else
										
										-- Assegno in questo stato m_axis_tdata e m_axis_tlast in modo da rispettare l'handshake
										m_axis_tdata <= (m_axis_tdata'high => '0', others => '1'); 
										m_axis_tlast <= t_last_reg;
										counter <= 0;

										state_volume <= send;
									end if;
									
								-- Caso in cui posso continuare a moltiplicare, shifto di una sola posizione alla volta
								-- Non e' possibile shiftare direttamente di un num_of_step_y volte perche' la funzione
								-- shift_left(right) non tiene conto del possibile overflow del vettore
								else
									
									mem_data <= shift_left(mem_data,1);
									counter <= counter + 1;
							
								end if;
							end if;

					when attenuation =>
						
						-- Assegno in questo stato m_axis_tdata e m_axis_tlast in modo da rispettare l'handshake
						m_axis_tdata <= std_logic_vector(shift_right(mem_data,num_of_step_y));
						m_axis_tlast <= t_last_reg;

						state_volume <= send;


					when send =>
										
						if m_axis_tready = '1' then
								
							state_volume <= fetch;
						end if;

				end case;
			end if;			
	end process;

end Behavioral;