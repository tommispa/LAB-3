library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity balance_controller is
    Port ( 
         aclk           : in STD_LOGIC;
         aresetn        : in STD_LOGIC;
        
		 m_axis_tlast	: out STD_LOGIC; -- Segnale che mi dice se sto ricevendo da canale di destra o di sinistra
		 m_axis_tvalid	: out STD_LOGIC;
		 m_axis_tdata	: out STD_LOGIC_VECTOR(23 downto 0);
		 m_axis_tready	: in STD_LOGIC;
		 
		 s_axis_tlast 	: in STD_LOGIC; -- Segnale che arriva dall'IS_2, che mi dice se sto ricevendo left channel o rigth channel
		 s_axis_tvalid	: in STD_LOGIC;
		 s_axis_tdata	: in STD_LOGIC_VECTOR(23 downto 0);
		 s_axis_tready	: out STD_LOGIC;

         balance        : in STD_LOGIC_VECTOR (9 downto 0));
end balance_controller;

architecture Behavioral of balance_controller is

begin


end Behavioral;