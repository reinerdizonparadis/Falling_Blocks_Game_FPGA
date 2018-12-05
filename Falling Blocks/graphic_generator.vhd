LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE WORK.GRAPHICS_LIB.ALL;

ENTITY graphic_generator IS
	PORT(
		-- VGA Inputs
		disp_ena	:	IN		STD_LOGIC;	--display enable ('1' = display time, '0' = blanking time)
		row		:	IN		INTEGER;		--row pixel coordinate
		column	:	IN		INTEGER;		--column pixel coordinate
		
		-- Peripheral Inputs
		SW		:	IN		STD_LOGIC_VECTOR(17 DOWNTO 0);
		KEY	:	IN		STD_LOGIC_VECTOR(3 DOWNTO 0);
		
		-- Clock Inputs
		CLOCK_50		:	IN		STD_LOGIC;
		moving_clk	:	IN		STD_LOGIC;
		rand_clk		:	IN		STD_LOGIC;
		
		-- VGA Outputs
		red		:	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --red magnitude output to DAC
		green		:	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --green magnitude output to DAC
		blue		:	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --blue magnitude output to DAC
		
		-- Other Outputs
		score		:	OUT	NATURAL := 0);
END graphic_generator;

ARCHITECTURE behavior OF graphic_generator IS
	
	-- Random Number Generator Circuit
	COMPONENT random_num_gen IS
		GENERIC(data_width : INTEGER := 32);
		PORT(
			seed : IN STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);
			clk, clrn, ld_sh : IN STD_LOGIC;
			rand_num : INOUT STD_LOGIC_VECTOR(data_width-1 DOWNTO 0));
	END COMPONENT random_num_gen;
	
	-- SIGNALS
	SIGNAL red_y, green_y, blue_y, yellow_y: NATURAL := 0;
	SIGNAL red_en, green_en, blue_en, yellow_en: BOOLEAN := FALSE;
	SIGNAL red_click, green_click, blue_click, yellow_click: BOOLEAN := FALSE;
	SIGNAL red_lock, green_lock, blue_lock, yellow_lock : STD_LOGIC := '1';
	SIGNAL rand_num : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
	SIGNAL red_dbcnt, blue_dbcnt, green_dbcnt, yellow_dbcnt : NATURAL RANGE 0 to DEBOUNCING_CNT-1 := 0;
	SIGNAL red_state, blue_state, green_state, yellow_state : KEY_STATE := INIT;
	
BEGIN
	
	-- Random Number Circuit
	rand_u1: random_num_gen port map(
		seed => (OTHERS => '1'),
		clk => rand_clk,
		ld_sh =>  SW(16) OR SW(17),
		clrn => '1',
		rand_num => rand_num
	);
	
	-- Update Debouncing Counters
	PROCESS(CLOCK_50) BEGIN
		IF CLOCK_50'EVENT AND CLOCK_50 = '1' THEN
			CHECK_BTN(red_state, red_click, red_dbcnt, red_lock);
			CHECK_BTN(blue_state, blue_click, blue_dbcnt, blue_lock);
			CHECK_BTN(green_state, green_click, green_dbcnt, green_lock);
			CHECK_BTN(yellow_state, yellow_click, yellow_dbcnt, yellow_lock);
		END IF;
	END PROCESS;
	
	-- Image Generation Process
	PROCESS(disp_ena, row, column, moving_clk)
		-- VARIABLES
		VARIABLE static_r, static_g, static_b :	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
		VARIABLE moving_r, moving_g, moving_b :	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '1');
		VARIABLE score_temp : NATURAL := 0;
		VARIABLE stat_mov_spd : NATURAL := STAT_MOV_SPD_MIN;
		VARIABLE speed_lock : BOOLEAN := FALSE;
	BEGIN
		IF SW(17) = '1' THEN		-- reset state
			score_temp := 0;
			stat_mov_spd := STAT_MOV_SPD_MIN;
			
		ELSIF(disp_ena = '1') THEN		--display time
			
			----------- STATIC PIXEL GENERATION AND DRAWING 
			IF		row >= STAT_BLK_MIN AND row < STAT_BLK_MAX AND column >= 135 AND column < 135+STAT_BLK_SIZE	THEN		-- left: red block
				CREATE_STATIC_BLOCKS(KEY(3), SW(0),
											red_en AND NOT red_click AND red_y+STAT_MOV_SIZE >= STAT_BLK_MIN AND red_y+STAT_MOV_SIZE < STAT_BLK_MAX,
											red_lock = '0' AND KEY(3) = '1' AND red_click,
											"11100100", "00110111", "00010010",
											(OTHERS => '1'), (OTHERS => '0'), (OTHERS => '0'),
											static_r, static_g, static_b,
											red_click, score_temp);
			ELSIF	row >= STAT_BLK_MIN AND row < STAT_BLK_MAX AND column >= 405 AND column < 405+STAT_BLK_SIZE	THEN		-- middle left: green block
				CREATE_STATIC_BLOCKS(KEY(2), SW(0),
											green_en AND NOT green_click AND green_y+STAT_MOV_SIZE >= STAT_BLK_MIN AND green_y+STAT_MOV_SIZE < STAT_BLK_MAX,
											green_lock = '0' AND KEY(2) = '1' AND green_click,
											"00010011", "10100101", "00101110",
											(OTHERS => '0'), (OTHERS => '1'), (OTHERS => '0'),
											static_r, static_g, static_b,
											green_click, score_temp);
			ELSIF	row >= STAT_BLK_MIN AND row < STAT_BLK_MAX AND column >= 675 AND column < 675+STAT_BLK_SIZE	THEN		-- middle right: blue block
				CREATE_STATIC_BLOCKS(KEY(1), SW(0),
											blue_en AND NOT blue_click AND blue_y+STAT_MOV_SIZE >= STAT_BLK_MIN AND blue_y+STAT_MOV_SIZE < STAT_BLK_MAX,
											blue_lock = '0' AND KEY(1) = '1' AND blue_click,
											"00101011", "00010010", "10100101",
											(OTHERS => '0'), (OTHERS => '0'), (OTHERS => '1'),
											static_r, static_g, static_b,
											blue_click, score_temp);
			ELSIF	row >= STAT_BLK_MIN AND row < STAT_BLK_MAX AND column >= 945 AND column < 945+STAT_BLK_SIZE	THEN		-- right: yellow block
				CREATE_STATIC_BLOCKS(KEY(0), SW(0),
											yellow_en AND NOT yellow_click AND yellow_y+STAT_MOV_SIZE >= STAT_BLK_MIN AND yellow_y+STAT_MOV_SIZE < STAT_BLK_MAX,
											yellow_lock = '0' AND KEY(0) = '1' AND yellow_click,
											"10101011", "10010010", "00100101",
											(OTHERS => '1'), (OTHERS => '1'), (OTHERS => '0'),
											static_r, static_g, static_b,
											yellow_click, score_temp);
			ELSE																																			-- background
				ASSIGN_COLOR((OTHERS => '1'), (OTHERS => '1'), (OTHERS => '1'), static_r, static_g, static_b);
			END IF;
			
			----------- MOVING PIXEL GENERATION
			IF(moving_clk'event AND moving_clk = '1' AND SW(0) = '0') THEN
				-- Increase block speed when user score more points
				IF NOT speed_lock AND score_temp > 15 AND score_temp rem 16 < 8  THEN
					stat_mov_spd := stat_mov_spd + 1;
					speed_lock := TRUE;
				ELSIF speed_lock AND score_temp rem 16 >= 8 THEN
					speed_lock := FALSE;
				END IF;
				
				ADJUST_MOVING_BLOCKS(red_en, red_y, stat_mov_spd);
				ADJUST_MOVING_BLOCKS(green_en, green_y, stat_mov_spd);
				ADJUST_MOVING_BLOCKS(blue_en, blue_y, stat_mov_spd);
				ADJUST_MOVING_BLOCKS(yellow_en, yellow_y, stat_mov_spd);
				
				-- Select blocks based on random number generator
				IF		rand_num(31 DOWNTO 30) = "00" AND NOT red_en AND red_y = 0 THEN
					red_en <= TRUE;
				ELSIF	rand_num(31 DOWNTO 30) = "01" AND NOT green_en AND green_y = 0 THEN
					green_en <= TRUE;
				ELSIF	rand_num(31 DOWNTO 30) = "10" AND NOT blue_en AND blue_y = 0 THEN
					blue_en <= TRUE;
				ELSIF	rand_num(31 DOWNTO 30) = "11" AND NOT yellow_en AND yellow_y = 0  THEN
					yellow_en <= TRUE;
				END IF;
				
			END IF;
			
			----------- MOVING BLOCKS DRAWING
			IF		red_en AND row >= red_y AND row < red_y+STAT_MOV_SIZE AND column >= 135 AND column < 135+STAT_BLK_SIZE THEN
				ASSIGN_COLOR("11100100", "00110111", "00010010", moving_r, moving_g, moving_b);
			ELSIF	green_en AND row >= green_y AND row < green_y+STAT_MOV_SIZE AND column >= 405 AND column < 405+STAT_BLK_SIZE THEN
				ASSIGN_COLOR("00010011", "10100101", "00101110", moving_r, moving_g, moving_b);
			ELSIF	blue_en AND row >= blue_y AND row < blue_y+STAT_MOV_SIZE AND column >= 675 AND column < 675+STAT_BLK_SIZE THEN
				ASSIGN_COLOR("00101011", "00010010", "10100101", moving_r, moving_g, moving_b);
			ELSIF	yellow_en AND row >= yellow_y AND row < yellow_y+STAT_MOV_SIZE AND column >= 945 AND column < 945+STAT_BLK_SIZE THEN
				ASSIGN_COLOR("10101011", "10010010", "00100101", moving_r, moving_g, moving_b);
			ELSE
				ASSIGN_COLOR((OTHERS => '1'), (OTHERS => '1'), (OTHERS => '1'), moving_r, moving_g, moving_b);
			END IF;
			
		ELSE								--blanking time
			ASSIGN_COLOR((OTHERS => '0'), (OTHERS => '0'), (OTHERS => '0'), static_r, static_g, static_b);
			ASSIGN_COLOR((OTHERS => '0'), (OTHERS => '0'), (OTHERS => '0'), moving_r, moving_g, moving_b);
		END IF;
		
		-- display to the screen
		red <= static_r AND moving_r;
		green <= static_g AND moving_g;
		blue <= static_b AND moving_b;
		
		-- display score
		score <= score_temp;
	END PROCESS;
END behavior;
