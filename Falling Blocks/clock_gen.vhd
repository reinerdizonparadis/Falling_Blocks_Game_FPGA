LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY clock_gen IS
	PORT(
		CLOCK_50			: IN STD_LOGIC;
		reset				: IN STD_LOGIC;
		moving_clk		: INOUT STD_LOGIC := '0';
		rand_clk			: INOUT STD_LOGIC := '0';
		debounce_clk	: INOUT STD_LOGIC := '0'
	);
END clock_gen;
	
ARCHITECTURE behavior OF clock_gen IS
	SIGNAL clk_counter : NATURAL RANGE 0 to 249999 := 0;
	SIGNAL rand_cnt : NATURAL RANGE 0 to 13574999 := 0;
	SIGNAL debounce_cnt : NATURAL RANGE 0 to 4999 := 0;
BEGIN
	PROCESS(CLOCK_50, reset)
	BEGIN
		IF reset = '1' THEN
			clk_counter <= 0;
			rand_cnt <= 0;
		ELSIF(CLOCK_50'event AND CLOCK_50 = '1') THEN
			clk_counter <= clk_counter + 1;
			debounce_cnt <= debounce_cnt + 1;
			rand_cnt <= rand_cnt + 1;
			
			IF(clk_counter + 1 = 249999) THEN
				moving_clk <= NOT moving_clk;
			END IF;
			
			IF(debounce_cnt + 1 = 4999) THEN
				debounce_clk <= NOT debounce_clk;
			END IF;
			
			IF(rand_cnt + 1 = 13574999) THEN
				rand_clk <= NOT rand_clk;
			END IF;
		END IF;
	END PROCESS;
END behavior;