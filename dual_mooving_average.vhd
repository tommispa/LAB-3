library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

entity dual_mooving_average is
	generic (
		AVERAGE 			:     INTEGER RANGE 0 TO 32 := 32 -- Numero di campioni con cui fare la media
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

           
           filter_enable    : in  STD_LOGIC); -- E' stato modificato l'edge_detector
end dual_mooving_average;

architecture rtl of dual_mooving_average is

-- Macchina a stati con quattro stati
-- Fetch: Prendo e il dato e, se il filtro e' attivo svolgo tutti i passaggi computazionali, altrimenti lo
-- mando direttamente in uscita 
-- Shift: viene eseguito lo shift delle memorie
-- Write: Salvo il dato modificato sul bus dati del master
-- Send: periodo di clock in cui avviene la trasmissione
type state_filter_type is (fetch, shift, write, send);
signal state_filter : state_filter_type := fetch;

-- Questa costante mi serve per decidere di quanti bit fare il padding per fare la media.
-- La funzione CEIL non servirebbe in quanto AVERAGE puo' essere solamente una potenza
-- di due
constant bit_avarage : POSITIVE := POSITIVE(CEIL(log2(REAL(AVERAGE))));
    
-- Matrice per definire una memoria bidimensionale
type matrix is array (AVERAGE - 1 downto 0) of SIGNED(23 downto 0);

-- Memoria bidimensionale in cui inserisco gli ultimi AVERAGE campioni del canale di sinistra
signal mem_sx       : matrix := (others => (others => '0'));
-- Memoria bidimensionale in cui inserisco gli ultimi AVERAGE campioni del canale di destra
signal mem_dx       : matrix := (others => (others => '0'));

-- Vettore intermedio per fare la somma dei campione del canale di sinistra
signal sum_vec_sx	: SIGNED(23 + bit_avarage downto 0) := (others => '0'); 
-- Vettore intermedio per fare la somma dei campione del canale di destra
signal sum_vec_dx	: SIGNED(23 + bit_avarage downto 0) := (others => '0'); 

-- Registro che mi tiene traccia del valore di s_axis_tlast
signal t_last_reg 	: STD_LOGIC;	

begin

    -- Alzo il segnale s_axis_tready solamente quando devo prendere il dato dall'IS_2,
    -- mentre rendo il blocco trasparente quando il filtro non e' attivo
    with state_filter select s_axis_tready <=
        '1' when fetch,
        '0' when shift,
        '0' when write,
        '0' when send;

    -- Alzo il segnale m_axis_tvalid solamente quando devo mandare il dato al blocco 
    -- successivo, mentre rendo il blocco trasparente quando il filtro non e' attivo
    with state_filter select m_axis_tvalid <=
        '0' when fetch,
        '0' when shift,
        '0' when write,
        '1' when send;

    process (aclk, aresetn)
    
    begin
        
        -- Se si abbassa il segnale di reset inizializzo tutti i registri
        if aresetn = '0' then
            
            mem_sx <= (others => (others => '0'));
            mem_dx <= (others => (others => '0'));

            sum_vec_sx <= (others => '0');
            sum_vec_dx <= (others => '0');

            state_filter <= fetch;

        elsif rising_edge(aclk) then
            
            case state_filter is

                when fetch =>
                
                    if s_axis_tvalid = '1' then

                        if filter_enable = '1' then

                            -- Assegno al primo elemento della memoria sinistra il dato e aggiorno la somma sinistra
                            if s_axis_tlast = '0' then
                                
                                t_last_reg <= s_axis_tlast;
                                mem_sx(0) <= SIGNED(s_axis_tdata);
                                sum_vec_sx <= sum_vec_sx + SIGNED(s_axis_tdata) - mem_sx(AVERAGE - 1);
                            
                            end if;

                            -- Assegno al primo elemento della memoria destra il dato e aggiorno la somma destra
                            if s_axis_tlast = '1' then
                                
                                t_last_reg <= s_axis_tlast;
                                mem_dx(0)<= SIGNED(s_axis_tdata);
                                sum_vec_dx <= sum_vec_dx + SIGNED(s_axis_tdata) - mem_dx(AVERAGE - 1);
                            
                            end if;

                            state_filter <= shift;
                        
                        else
                            
                            -- Faccio passare direttamente il tlast e il tdata
					        m_axis_tlast <= s_axis_tlast;
					        m_axis_tdata <= s_axis_tdata;

                            state_filter <= send;
                        end if;

                    end if;
                
                when shift =>
                    
                    if t_last_reg = '0' then
                        
                        -- Faccio lo shift della memoria di sinistra
					    for i in 1 to AVERAGE - 1 loop

                        mem_sx(i) <= mem_sx(i-1);
                        
                        end loop;
                    
                    end if;

                    if t_last_reg = '1' then
                        
                        -- Faccio lo shift della memoria di destra
				        for j in 1 to AVERAGE - 1 loop
					
					    mem_dx(j) <= mem_dx(j-1);

				        end loop;				

                    end if;
                    
                    state_filter <= write;

                when write =>

                    if t_last_reg = '0' then
                                
                        -- Mando in uscita solamente i 24 bit piu' significativi, ed in questo modo faccio la media
                        m_axis_tlast <= t_last_reg;
                        m_axis_tdata <= std_logic_vector(sum_vec_sx(23 + bit_avarage downto bit_avarage));

                    end if;
                    
                    if t_last_reg = '1' then
                        
                        -- Mando in uscita solamente i 24 bit piu' significativi, ed in questo modo faccio la media
                        m_axis_tlast <= t_last_reg;
                        m_axis_tdata <= std_logic_vector(sum_vec_dx(23 + bit_avarage downto bit_avarage)); 

                    end if;
					
					state_filter <= send;
                
                when send =>
                    
                    if m_axis_tready = '1' then
                            
                        state_filter <= fetch;

                    end if;
        
            end case;

        end if;
    end process;

end architecture;