library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

entity dual_mooving_average is
	generic (
		AVARAGE 			: INTEGER RANGE 0 TO 32 := 32 -- Numero di campioni con cui fare la media
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

           
           filter_enable    : in STD_LOGIC);
end dual_mooving_average;

architecture Behavioral of dual_mooving_average is

-- Questa costante mi serve per decidere di quanti bit fare il padding per fare la media.
-- La funzione CEIL non servirebbe in quanto come integer avarage possono capitare solo
-- potenze di due
constant bit_avarage : POSITIVE := POSITIVE(CEIL(log2(REAL(AVARAGE))));

-- Matrice per definire una memoria bidimensionale
type matrix is array (AVARAGE - 1 downto 0) of SIGNED(23 downto 0);

-- Memoria bidimensionale in cui inserisco gli ultimi AVARAGE campioni del canale di sinistra
signal mem_sx : matrix := (others => (others => '0'));
-- Memoria bidimensionale in cui inserisco gli ultimi AVARAGE campioni del canale di destra
signal mem_dx : matrix := (others => (others => '0'));


-- Vettore intermedio per fare la somma dei campione del canale di sinistra
signal sum_vec_sx : SIGNED(23 + bit_avarage downto 0) := (others => '0'); 
-- Vettore intermedio per fare la somma dei campione del canale di destra
signal sum_vec_dx : SIGNED(23 + bit_avarage downto 0) := (others => '0'); 

-- Rendo il dato in ingresso un signed
signal data_sign : SIGNED(23 downto 0) := (others => '0') ;

-- Segnale intermedio per filter eneable: essendo quest'ultimo un impulso utilizziamo questo
-- registro per capire se dobbiamo applicare il filtro o meno
signal filter_enable_reg : STD_LOGIC := '0';



begin
-- Assegnazione filter enable
data_sign <= SIGNED(s_axis_tdata);

process (aclk, aresetn)

begin

	if aresetn = '0' then
		
		mem_sx <= (others => (others => '0'));
		mem_dx <= (others => (others => '0'));

		sum_vec_sx <= (others => '0');
		sum_vec_dx <= (others => '0');

		data_sign <= (others => '0');
		
		filter_enable_reg <= '0';
		-- reset s_tready

	elsif rising_edge(aclk) then
		
	-- Se ho il filtro attivo procedo con questa data flow
		if filter_enable_reg = '1' then

		s_axis_tready <= '1';
		
			if s_axis_tvalid = '1' then

----------------------------- Memoria sinistra ---------------------------------------------
				if s_axis_tlast = '0' then
				-- Assegno al primo elemento della memoria sinistra il dato
				mem_sx(0) <= data_sign ;

				-- Faccio lo shift di ogni elemento con quello precedente
					for i in 1 to AVARAGE - 1 loop

					mem_sx(i) <= mem_sx(i-1);
					
					end loop;
				
				-- Faccio la somma di tutti gli elementi della memoria sinistra
					for i in 0 to AVARAGE loop

					sum_vec_sx <= sum_vec_sx + mem_sx(i);

					end loop;
				
					if m_axis_tready = '1' then

					m_axis_tvalid <= '1';
					m_axis_tlast <= '0';
					m_axis_tdata <= std_logic_vector(sum_vec_sx(23 + bit_avarage downto bit_avarage));
				
					end if;
			
				end if;
----------------------------- Memoria destra ---------------------------------------------
				
				-- Assegno al primo elemento della memoria destra il dato
				mem_dx(0)<= data_sign;

				-- Faccio lo shift di ogni elemento con quello precedente
				for j in 1 to AVARAGE - 1 loop
					
					mem_dx(j) <= mem_dx(j-1);

				end loop;				
				
				-- Faccio la somma di tutti gli elementi della memoria
				for j in 0 to AVARAGE loop
					
					sum_vec_dx <= sum_vec_dx + mem_dx(j);

				end loop;
				
				if m_axis_tready = '1' then

						m_axis_tvalid <= '1';
						m_axis_tlast <= '1';
						m_axis_tdata <= std_logic_vector(sum_vec_dx(23 + bit_avarage downto bit_avarage));
					
				end if;
				
			end if;
	-- Se il filtro non è attivo procedo con questo data flow
		else
		
		s_axis_tready <= '1';

		if s_axis_tvalid = '1' then
			
			-- Caso in cui ricevo un dato del canale di sinistra
			if s_axis_tlast = '0' then
				
				if m_axis_tready = '1' then
					
					m_axis_tvalid <= '1';
					m_axis_tlast <= '0';
					m_axis_tdata <= s_axis_tdata;

				end if;
			
			-- Caso in cui ricevo un dato dal canale di destra
			else
				
				if m_axis_tready = '1' then
					
					m_axis_tvalid <= '1';
					m_axis_tlast <= '1';
					m_axis_tdata <= s_axis_tdata;

				end if;

			end if;

		end if;
		

	end if;

end if;
	

end process;
	


end Behavioral;
