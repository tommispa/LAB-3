library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

entity filter is
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
end filter;

architecture rtl of filter is

-- Macchina a stati che ci permette di fare pipelining nelle operazioni di media
type avarage_filter_fsm is (filter_choice, fetch, shift, sum, pull);

-- Matrice per definire una memoria bidimensionale
type matrix is array (AVARAGE - 1 downto 0) of SIGNED(23 downto 0);

-- Memoria bidimensionale in cui inserisco gli ultimi AVARAGE campioni del canale di sinistra
signal mem_sx : matrix := (others => (others => '0'));
-- Memoria bidimensionale in cui inserisco gli ultimi AVARAGE campioni del canale di destra
signal mem_dx : matrix := (others => (others => '0'));

-- Vettore intermedio per fare la somma dei campione del canale di sinistra
signal sum_vec_sx	: SIGNED(23 + bit_avarage downto 0) := (others => '0'); 
-- Vettore intermedio per fare la somma dei campione del canale di destra
signal sum_vec_dx	: SIGNED(23 + bit_avarage downto 0) := (others => '0'); 

-- Rendo il dato in ingresso un signed
signal data_sign	: SIGNED(23 downto 0) := (others => '0');


begin

    data_sign <= SIGNED(s_axis_tdata);

    with avarage_filter_fsm select s_axis_tready <=
        '0' when filter_choice;
        '1' when fetch;
        '0' when shift;
        '0' when sum;
        '0' when pull;
        '1' when pass;

    with avarage_filter_fsm select m_axis_tvalid <=
        '0' when filter_choice;
        '0' when fetch;
        '0' when shift;
        '0' when sum;
        '1' when pull;
        '1' when pass;

    process (aclk, aresetn)
    
    begin
        
        if aresetn = '0' then
            
        mem_sx <= (others => (others => '0'));
		mem_dx <= (others => (others => '0'));

		sum_vec_sx <= (others => '0');
		sum_vec_dx <= (others => '0');

		data_sign <= (others => '0');

        avarage_filter_fsm <= filter_choice;

        elsif rising_edge(aclk) then
            
            case avarage_filter_fsm is

                when filter_choice =>

                    if filter_enable = '1' then
                        avarage_filter_fsm <= fetch;
                    else
                        avarage_filter_fsm <= pass;
                    end if;
                        

                when fetch =>
                
                    if s_axis_tvalid = '1' then

                        -- Assegno al primo elemento della memoria sinistra il dato
                        if s_axis_tlast = '0' then
                            mem_sx(0) <= data_sign ;
                        end if;

                        -- Assegno al primo elemento della memoria destra il dato
                        if s_axis_tlast = '1' then
                            mem_dx(0)<= data_sign;
                        end if;
                        
                        -- Vado nello stato di somma
                        avarage_filter_fsm <= shift;

                    end if;
                
                when shift =>
                    
                    if s_axis_tlast = '0' then
                        
                        -- Faccio lo shift di ogni elemento con quello precedente
					    for i in 1 to AVARAGE - 1 loop

                        mem_sx(i) <= mem_sx(i-1);
                        
                        end loop;
                    
                    end if;

                    if s_axis_tlast = '1' then
                        
                        -- Faccio lo shift di ogni elemento con quello precedente
				        for j in 1 to AVARAGE - 1 loop
					
					    mem_dx(j) <= mem_dx(j-1);

				        end loop;				

                    end if;
                    
                    avarage_filter_fsm <= sum;

                when sum =>

                    if s_axis_tlast = '0' then
                        
                        -- Per aggiornare il vettore somma mi basta sommare l'ultimo
                        -- sample acquisito e sottrarre l'ultimo sample della memoria
                        sum_vec_sx <= sum_vec_sx + mem_sx(0) - mem_sx(AVARAGE - 1);

                    end if;
                        
                    if s_axis_tlast = '1' then
                            
                        -- Per aggiornare il vettore somma mi basta sommare l'ultimo
                        -- sample acquisito e sottrarre l'ultimo sample della memoria
                        sum_vec_dx <= sum_vec_dx + mem_dx(0) - mem_dx(AVARAGE - 1);

                    end if;
                
                when pull =>
                    
                    if m_axis_tready = '1' then
                            
                        if s_axis_tlast = '0' then
                                
                            m_axis_tlast <= '0';
					        m_axis_tdata <= std_logic_vector(sum_vec_sx(23 + bit_avarage downto bit_avarage));

                        end if;
                        
                        if s_axis_tlast = '1' then
                                
                            m_axis_tlast <= '1';
						    m_axis_tdata <= std_logic_vector(sum_vec_dx(23 + bit_avarage downto bit_avarage)); 

                        end if;
                            
                        avarage_filter_fsm <= filter_choice;

                    end if;
                    
                when pass =>
                    
                    if s_axis_tvalid = '1' and m_axis_tready = '1' then
                        
                        if s_axis_tlast = '0' then
                            
                            m_axis_tlast <= '0';
					        m_axis_tdata <= s_axis_tdata;

                        end if;

                        if s_axis_tlast = '1' then
                            
                            m_axis_tlast <= '1';
					        m_axis_tdata <= s_axis_tdata;

                        end if;

                        avarage_filter_fsm <= filter_choice;

                    end if;
            
            end case;

        end if;
    end process;

end architecture;