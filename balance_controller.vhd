library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

entity balance_controller is

	generic (
		division_step	: 	  INTEGER RANGE 0 to 9 := 6				-- Numero n, l'amplification factor deve essere diviso per 2 ogni 2^n joystick units		
	);

    Port ( 
         aclk           : in  STD_LOGIC;
         aresetn        : in  STD_LOGIC;
        
		 m_axis_tlast	: out STD_LOGIC; 						-- Segnale che mi dice se sto ricevendo da canale di destra o di sinistra
		 m_axis_tvalid	: out STD_LOGIC;
		 m_axis_tdata	: out STD_LOGIC_VECTOR(23 downto 0);
		 m_axis_tready	: in  STD_LOGIC;
		 
		 s_axis_tlast 	: in  STD_LOGIC; 						-- Segnale che arriva dall'IS_2, che mi dice se sto ricevendo left channel o rigth channel
		 s_axis_tvalid	: in  STD_LOGIC;
		 s_axis_tdata	: in  STD_LOGIC_VECTOR(23 downto 0);
		 s_axis_tready	: out STD_LOGIC;
         
		 balance        : in  STD_LOGIC_VECTOR (9 downto 0));

end balance_controller;


architecture Behavioral of balance_controller is

	-- Macchina a stati con cincque stati
	-- Fetch: prende il dato in ingresso e lo carica su una memoria
	-- Control: verifico quale dei due canali devo abbassare
	-- Left_channel: vado in questo stato se devo abbassare il canale sinistro
	-- Right_channel: vado in questo canale se devo abbassare il canale destro
	-- Send: fa uscire il dato dal bus dati del master
	type state_balance_type is (fetch, control, left_channel, right_channel, send);
	signal state_balance : state_balance_type := fetch;

	
	-- Costante che mi calcola quanto sono grandi gli step di attenuazione
	constant 	step_div 	    : INTEGER := 2**division_step;
	-- Costante che mi pone al limite tra lo step 0 e lo step +1
	constant    shift       	: INTEGER := 2**(division_step-1) + 512;
	-- Costante che mi serve per calcolare di quanto devo 
	-- shiftare il vettore per ottenere l'attenauazione desiderata
	constant	offset			: INTEGER := 512/step_div;


	-- Registro in cui salvo quante volte devo shiftare il vettore per moltiplicare o dividere
	signal		num_of_step_x	: INTEGER := 0;
	-- Registro in cui salvo il valore del tlast associato al segnale in ingresso
	signal		t_last_reg		: STD_LOGIC;
	-- Registro in cui salvo il valore del dato in ingresso tramite s_axis_tdata nella sua forma corretta, ovvero SIGNED
	signal		mem_data		: SIGNED(23 downto 0) := (others => '0');
	-- Regsitro in cui salvo il valore del dato in ingresso tramite balance nella sua forma corretta, ovvero UNSIGNED
	signal		mem_balance		: UNSIGNED(9 downto 0) := (others => '0');

begin


	-- Alzo il segnale s_axis_tready solamente quando devo prendere il dato
	with state_balance select s_axis_tready <=
		'1' when fetch,
		'0' when control,
		'0' when left_channel,
		'0' when right_channel,
		'0' when send;

	-- Alzo il segnale m_axis_tvalid solamente quando devo mandare il dato al blocco successivo
	with state_balance select m_axis_tvalid <=
		'0' when fetch,
		'0' when control,
		'0' when left_channel,
		'0' when right_channel,
		'1' when send;


	process (aclk, aresetn)
	
	
		begin

			-- Se si abbassa il segnale di reset inizializzo tutti i registri
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

							state_balance <= control;
						end if;
					
					when control =>
							
						if mem_balance >= shift then
							
							-- Costante che mi permette di calcolare di quanto devo shiftare 
							-- mem_data per avere l'attenuazione desiderata
							num_of_step_x <= to_integer(shift_right(mem_balance,division_step)) - offset;
						
							state_balance <= left_channel;
						
						elsif mem_balance < shift-step_div then
							
							-- Stessa costante, ma cambiata di segno in quanto altrimenti sarebbe negativa
							num_of_step_x <= -(to_integer(shift_right(mem_balance,division_step)) - offset);
						
							state_balance <= right_channel;
						
						else
							state_balance <= send;
						
						end if;

					when left_channel =>
						
						-- Vado ad attenuare il segnale solamente se proviene dal canale di sinistra
						if t_last_reg = '0' then
							mem_data <= shift_right(mem_data,num_of_step_x);
						end if;
						
						state_balance <= send;

					when right_channel =>
						
						-- Vado ad attenuare il segnale solamente se proviene dal canale di destra
						if t_last_reg = '1' then
							mem_data <= shift_right(mem_data,num_of_step_x);
						end if;
						
						state_balance <= send;

					when send =>
						
						if m_axis_tready = '1' then
							
							m_axis_tlast <= t_last_reg;
							m_axis_tdata <= STD_LOGIC_VECTOR(mem_data(23 downto 0));
							
							state_balance <= fetch;
						end if;

				end case;
			end if;
		end process;
end architecture;