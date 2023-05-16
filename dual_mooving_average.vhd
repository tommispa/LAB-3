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
           
		   m_axis_tvalid	: out STD_LOGIC;
		   m_axis_tdata	    : out STD_LOGIC_VECTOR(23 downto 0);
		   m_axis_tready	: in STD_LOGIC;
		   
		   s_axis_tlast 	: in STD_LOGIC; -- Segnale che arriva dall'IS_2, che mi dice se sto ricevendo left channel o rigth channel
		   s_axis_tvalid	: in STD_LOGIC;
		   s_axis_tdata	    : in STD_LOGIC_VECTOR(23 downto 0);

           
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


type fsm_1_type is (recieve, sum, media);
signal fsm_1 : fsm_1_type;



begin

process (aclk, aresetn)

begin
	
	-- Se filter_enable è alto allora faccio la media
	if filter_enable = '1' then
		


		
	-- Se è basso allora faccio passare il segnale invariato	
	elsif m_axis_tready = '1' then
		
		m_axis_tvalid <= '1';
		m_axis_tdata <= s_axis_tdata;


	end if;

end process;
	


end Behavioral;
