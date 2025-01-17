LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY PIXEL_GEN IS
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
		score		:	OUT	NATURAL := 0;
		LEDR	: OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
		);
END PIXEL_GEN;

ARCHITECTURE behavior OF PIXEL_GEN IS
	
	-- Random Number Generator Circuit
	COMPONENT random_num_gen IS
		GENERIC(data_width : INTEGER := 32);
		PORT(
			seed : IN STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);
			clk, clrn, ld_sh : IN STD_LOGIC;
			rand_num : INOUT STD_LOGIC_VECTOR(data_width-1 DOWNTO 0));
	END COMPONENT random_num_gen;
	
	-- TYPE
	TYPE KEY_STATE IS (INIT, START_TIMER, RUN, END_TIMER);
	
	-- SIGNALS
	SIGNAL red_y, green_y, blue_y, yellow_y: NATURAL := 0;
	SIGNAL red_en, green_en, blue_en, yellow_en: BOOLEAN := FALSE;
	SIGNAL red_click, green_click, blue_click, yellow_click: BOOLEAN := FALSE;
	SIGNAL red_lock, green_lock, blue_lock, yellow_lock : STD_LOGIC := '1';
	SIGNAL rand_num : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
	SIGNAL red_dbcnt, blue_dbcnt, green_dbcnt, yellow_dbcnt : NATURAL RANGE 0 to 124999 := 0;
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
	
	LEDR(2) <= red_lock;
	LEDR(1) <= '1' when red_click else '0';
	
	-- Update Debouncing Counters
	PROCESS(CLOCK_50) BEGIN
		IF CLOCK_50'EVENT AND CLOCK_50 = '1' THEN
			CASE red_state IS
				WHEN INIT =>
					IF red_click THEN red_state <= RUN; END IF;
					red_dbcnt <= 0;
					red_lock <= '0';
				WHEN RUN =>
					red_lock <= '1';
					red_dbcnt <= red_dbcnt + 1;
					IF red_dbcnt + 1 = 124999 THEN red_state <= END_TIMER; END IF;
				WHEN END_TIMER =>
					red_dbcnt <= 0;
					red_lock <= '0';
					IF NOT red_click THEN red_state <= INIT; END IF;
				WHEN OTHERS =>
					red_state <= INIT;
			END CASE;
			CASE blue_state IS
				WHEN INIT =>
					IF blue_click THEN blue_state <= RUN; END IF;
					blue_dbcnt <= 0;
					blue_lock <= '0';
				WHEN RUN =>
					blue_lock <= '1';
					blue_dbcnt <= blue_dbcnt + 1;
					IF blue_dbcnt + 1 = 124999 THEN blue_state <= END_TIMER; END IF;
				WHEN END_TIMER =>
					blue_dbcnt <= 0;
					blue_lock <= '0';
					IF NOT blue_click THEN blue_state <= INIT; END IF;
				WHEN OTHERS =>
					blue_state <= INIT;
			END CASE;
			
			CASE green_state IS
				WHEN INIT =>
					IF green_click THEN green_state <= RUN; END IF;
					green_dbcnt <= 0;
					green_lock <= '0';
				WHEN RUN =>
					green_lock <= '1';
					green_dbcnt <= green_dbcnt + 1;
					IF green_dbcnt + 1 = 124999 THEN green_state <= END_TIMER; END IF;
				WHEN END_TIMER =>
					green_dbcnt <= 0;
					green_lock <= '0';
					IF NOT green_click THEN green_state <= INIT; END IF;
				WHEN OTHERS =>
					green_state <= INIT;
			END CASE;
			
			CASE yellow_state IS
				WHEN INIT =>
					IF yellow_click THEN yellow_state <= RUN; END IF;
					yellow_dbcnt <= 0;
					yellow_lock <= '0';
				WHEN RUN =>
					yellow_lock <= '1';
					yellow_dbcnt <= yellow_dbcnt + 1;
					IF yellow_dbcnt + 1 = 124999 THEN yellow_state <= END_TIMER; END IF;
				WHEN END_TIMER =>
					yellow_dbcnt <= 0;
					yellow_lock <= '0';
					IF NOT yellow_click THEN yellow_state <= INIT; END IF;
				WHEN OTHERS =>
					yellow_state <= INIT;
			END CASE;
		END IF;
	END PROCESS;
	
	-- Image Generation Circuit
	PROCESS(disp_ena, row, column, moving_clk)
		
		-- CONSTANTS
		CONSTANT STAT_BLK_MIN	: NATURAL := 924;
		CONSTANT STAT_BLK_MAX	: NATURAL := 1024;
		CONSTANT STAT_BLK_SIZE	: NATURAL := 200;
		
		CONSTANT STAT_MOV_SIZE		: NATURAL := 50;
		CONSTANT STAT_MOV_SPD_MIN	: NATURAL := 10;
		
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
				IF KEY(3) = '0' AND SW(0) = '0' THEN
					static_r := (OTHERS => '1');
					static_g	:= (OTHERS => '0');
					static_b := (OTHERS => '0');
					
					IF(red_en AND NOT red_click AND red_y+STAT_MOV_SIZE >= STAT_BLK_MIN AND red_y+STAT_MOV_SIZE < STAT_BLK_MAX) THEN
						red_click <= TRUE;
					END IF;
					
				ELSE
					static_r := "11100100";
					static_g	:= "00110111";
					static_b := "00010010";
					IF red_lock = '0' AND KEY(3) = '1' AND red_click THEN
						score_temp := score_temp + 1;
						red_click <= FALSE;
					END IF;
				END IF;
				
			ELSIF	row >= STAT_BLK_MIN AND row < STAT_BLK_MAX AND column >= 405 AND column < 405+STAT_BLK_SIZE	THEN		-- middle left: green block
				IF KEY(2) = '0' AND SW(0) = '0' THEN
					static_r := (OTHERS => '0');
					static_g	:= (OTHERS => '1');
					static_b := (OTHERS => '0');
					
					IF(green_en AND NOT green_click AND green_y+STAT_MOV_SIZE >= STAT_BLK_MIN AND green_y+STAT_MOV_SIZE < STAT_BLK_MAX) THEN
						green_click <= TRUE;
					END IF;
				ELSE
					static_r := "00010011";
					static_g	:= "10100101";
					static_b := "00101110";
					IF green_lock = '0' AND KEY(2) = '1' AND green_click THEN
						score_temp := score_temp + 1;
						green_click <= FALSE;
					END IF;
				END IF;
				
			ELSIF	row >= STAT_BLK_MIN AND row < STAT_BLK_MAX AND column >= 675 AND column < 675+STAT_BLK_SIZE	THEN		-- middle right: blue block
				IF KEY(1) = '0' AND SW(0) = '0' THEN
					static_r := (OTHERS => '0');
					static_g	:= (OTHERS => '0');
					static_b := (OTHERS => '1');
					
					IF(blue_en AND NOT blue_click AND blue_y+STAT_MOV_SIZE >= STAT_BLK_MIN AND blue_y+STAT_MOV_SIZE < STAT_BLK_MAX) THEN
						blue_click <= TRUE;
					END IF;
				ELSE
					static_r := "00101011";
					static_g	:= "00010010";
					static_b := "10100101";
					IF blue_lock = '0' AND KEY(1) = '1' AND blue_click THEN
						score_temp := score_temp + 1;
						blue_click <= FALSE;
					END IF;
				END IF;
				
			ELSIF	row >= STAT_BLK_MIN AND row < STAT_BLK_MAX AND column >= 945 AND column < 945+STAT_BLK_SIZE	THEN		-- right: yellow block
				IF KEY(0) = '0' AND SW(0) = '0' THEN
					static_r := (OTHERS => '1');
					static_g	:= (OTHERS => '1');
					static_b := (OTHERS => '0');
					
					IF(yellow_en AND NOT yellow_click AND yellow_y+STAT_MOV_SIZE >= STAT_BLK_MIN AND yellow_y+STAT_MOV_SIZE < STAT_BLK_MAX) THEN
						yellow_click <= TRUE;
					END IF;
				ELSE
					static_r := "10101011";
					static_g	:= "10010010";
					static_b := "00100101";
					IF yellow_lock = '0' AND KEY(0) = '1' AND yellow_click THEN
						score_temp := score_temp + 1;
						yellow_click <= FALSE;
					END IF;
				END IF;
				
			ELSE																																			-- background
				static_r := (OTHERS => '1');
				static_g	:= (OTHERS => '1');
				static_b := (OTHERS => '1');
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
				
				IF(red_en) THEN
					red_y <= red_y + stat_mov_spd;
					IF(red_y + stat_mov_spd > STAT_BLK_MIN-1) THEN
						red_en <= FALSE;
						red_y <= 0;
					END IF;
				END IF;
				
				IF(green_en) THEN
					green_y <= green_y + stat_mov_spd;
					IF(green_y + stat_mov_spd > STAT_BLK_MIN-1) THEN
						green_en <= FALSE;
						green_y <= 0;
					END IF;
				END IF;
				
				IF(blue_en) THEN
					blue_y <= blue_y + stat_mov_spd;
					IF(blue_y + stat_mov_spd > STAT_BLK_MIN-1) THEN
						blue_en <= FALSE;
						blue_y <= 0;
					END IF;
				END IF;
				
				IF(yellow_en) THEN
					yellow_y <= yellow_y + stat_mov_spd;
					IF(yellow_y + stat_mov_spd > STAT_BLK_MIN-1) THEN
						yellow_en <= FALSE;
						yellow_y <= 0;
					END IF;
				END IF;
				
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
				moving_r := "11100100";
				moving_g	:= "00110111";
				moving_b := "00010010";
				
			ELSIF	green_en AND row >= green_y AND row < green_y+STAT_MOV_SIZE AND column >= 405 AND column < 405+STAT_BLK_SIZE THEN
				moving_r := "00010011";
				moving_g	:= "10100101";
				moving_b := "00101110";
				
			ELSIF	blue_en AND row >= blue_y AND row < blue_y+STAT_MOV_SIZE AND column >= 675 AND column < 675+STAT_BLK_SIZE THEN
				moving_r := "00101011";
				moving_g	:= "00010010";
				moving_b := "10100101";
				
			ELSIF	yellow_en AND row >= yellow_y AND row < yellow_y+STAT_MOV_SIZE AND column >= 945 AND column < 945+STAT_BLK_SIZE THEN
				moving_r := "10101011";
				moving_g	:= "10010010";
				moving_b := "00100101";
				
			ELSE
				moving_r := (OTHERS => '1');
				moving_g := (OTHERS => '1');
				moving_b := (OTHERS => '1');
			END IF;
			
		ELSE								--blanking time
			static_r := (OTHERS => '0');
			static_g := (OTHERS => '0');
			static_b := (OTHERS => '0');
			
			moving_r := (OTHERS => '0');
			moving_g := (OTHERS => '0');
			moving_b := (OTHERS => '0');
		END IF;
		
		
		-- display to the screen
		red <= static_r AND moving_r;
		green <= static_g AND moving_g;
		blue <= static_b AND moving_b;
		
		-- display score
		score <= score_temp;
		
	END PROCESS;
END behavior;