library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity edge_detector is
	Generic (
		TRIGGER_RISING	: boolean := true
	);
	Port (
		-- Clock and reset
		clk				: in std_logic;
		reset			: in std_logic;

		-- Trigger signal
		input_signal	: in std_logic;

		-- Output signal
		edge_detected	: out std_logic
	);
end edge_detector;


architecture Behavioral of edge_detector is

	signal input_signal_previous	: STD_LOGIC;
	signal edge_detected_reg 		: STD_LOGIC;
	

begin

	edge_detected <= edge_detected_reg;

	process(clk, reset)
	begin
		if reset = '1' then

			input_signal_previous	<= '0';
			edge_detected_reg		<= '0';

		elsif rising_edge(clk) then

			-- Sample trigger: in this way "trigger_previous" contains the
			-- state of the trigger signal in the previous clock cycle,
			-- "trigger" the state in this one
			input_signal_previous	<= input_signal;

			-- If TRIGGER_RISING is true, the last input signal was 0 and now is 1, or...
			-- ..TRIGGER_RISING is false, the last input signal was 1 and now is 0, then...
			if (TRIGGER_RISING and input_signal_previous = '0' and input_signal = '1') or
				(not TRIGGER_RISING and input_signal_previous = '1' and input_signal = '0') then

				-- In questo modo ho un'uscita costante dall'edge_detector e non piu' un impulso
				edge_detected_reg	<= not(edge_detected_reg);

			end if;

		end if;
	end process;

end Behavioral;