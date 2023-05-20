library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;
    


entity balance_controller is
    generic(
       N           : INTEGER := 6
    );
    Port ( 
        aclk             : IN STD_LOGIC;
        aresetn          : IN STD_LOGIC;
        
        s_axis_tvalid   : IN STD_LOGIC;
        s_axis_tdata    : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        s_axis_tready   : OUT STD_LOGIC;
        s_axis_tlast    : IN STD_LOGIC;
    
        m_axis_tvalid   : OUT STD_LOGIC;
        m_axis_tdata    : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        m_axis_tready   : IN STD_LOGIC;
        m_axis_tlast    : OUT STD_LOGIC;
        
        balance          : IN STD_LOGIC_VECTOR (9 DOWNTO 0)
    );

end balance_controller;



architecture Behavioral of balance_Controller is

    ----------------------------------------- SIGNALS -------------------------------------------
    
    --- Internal signals needend for the multi clock loop back --- 
	signal m_axis_tvalid_int	: std_logic;
	signal s_axis_tready_int	: std_logic;
	
	--- Balance signals ---
    constant SHIFT  :   INTEGER                                 := 2**(9-N); 
    signal BALANCE_1  :   INTEGER RANGE -SHIFT TO SHIFT           := 0;
    
    ---------------------------------------------------------------------------------------------

    
    
begin

    -------------------------------------- DATA FLOW --------------------------------------------
    
    --- BALANCE signal equation: you will find the same equation presented in the "Volume_Controller" block. The following equation ---
    --- is written in order to have every interval long as 2^(N), and the 0 value in between the two values -2^(N-1) and 2^(N-1).   ---
    BALANCE_1             <=  to_integer(shift_right(unsigned(balance(9 downto 0))+2**(N-1), N)) - SHIFT;

    --- Multi clock loop back ---
	s_axis_tready_int	<= m_axis_tready or not m_axis_tvalid_int;
	m_axis_tvalid		<= m_axis_tvalid_int;
	s_axis_tready		<= s_axis_tready_int;
    
    ---------------------------------------------------------------------------------------------

    -------------------------------------- PROCESS ----------------------------------------------

	BALANCE_PRCSS : process(aclk, aresetn)
	
	begin
	
        --- Asyncronous Reset ---
        if(aresetn = '0')        then
            m_axis_tvalid_int    <= '0';
            m_axis_tlast         <= s_axis_tlast;
            
        elsif rising_edge(aclk)  then
                
            --- Full/NOT_Empty logic ---          
            if s_axis_tvalid = '1' then
                m_axis_tvalid_int	<= '1';
            elsif m_axis_tready = '1' then
                m_axis_tvalid_int	<= '0';
            end if;
            
            if s_axis_tvalid = '1' and s_axis_tready_int = '1' then
                
                --- L and R balance logic ---
                if(s_axis_tlast = '1'  and BALANCE_1 <= -1)   then
                    m_axis_tdata    <= std_logic_vector(shift_right(signed(s_axis_tdata), abs(BALANCE_1)));
                    m_axis_tlast    <= '1';
                    
                elsif(s_axis_tlast = '0' and BALANCE_1 >= 1)  then
                    m_axis_tdata    <= std_logic_vector(shift_right(signed(s_axis_tdata), abs(BALANCE_1)));
                    m_axis_tlast    <= '0';
                    
                else
                    m_axis_tdata    <= s_axis_tdata;
                    m_axis_tlast    <= s_axis_tlast;
                    
                end if;
                
            end if;

        end if;
			
	end process;
	
    ---------------------------------------------------------------------------------------------

end Behavioral;