LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE graphics_lib IS
	CONSTANT DEBOUNCING_CNT	: NATURAL := 125000;
	
	CONSTANT STAT_BLK_MIN	: NATURAL := 924;
	CONSTANT STAT_BLK_MAX	: NATURAL := 1024;
	CONSTANT STAT_BLK_SIZE	: NATURAL := 200;
	
	CONSTANT STAT_MOV_SIZE		: NATURAL := 50;
	CONSTANT STAT_MOV_SPD_MIN	: NATURAL := 5;
	
	TYPE KEY_STATE IS (INIT, START_TIMER, RUN, END_TIMER);
	
	PROCEDURE CREATE_STATIC_BLOCKS(
		SIGNAL KEY, SW : IN STD_LOGIC;
		CONSTANT score_lock_exp, score_unlock_exp : IN BOOLEAN;
		CONSTANT upR, upG, upB, dwR, dwG, dwB : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		VARIABLE R, G, B : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		SIGNAL click_lock : OUT BOOLEAN;
		VARIABLE score : INOUT NATURAL
	);
	
	PROCEDURE CHECK_BTN(
		SIGNAL state : INOUT KEY_STATE;
		SIGNAL click_lock : IN BOOLEAN;
		SIGNAL deb_cnt : INOUT NATURAL RANGE 0 to DEBOUNCING_CNT-1;
		SIGNAL counter_lock : OUT STD_LOGIC
	);
	
	PROCEDURE ADJUST_MOVING_BLOCKS(
		SIGNAL enable : INOUT BOOLEAN;
		SIGNAL pos : INOUT NATURAL;
		VARIABLE speed : IN NATURAL
	);
	
END graphics_lib;

PACKAGE BODY graphics_lib IS
	
	-- Create Static Blocks Procedure
	PROCEDURE CREATE_STATIC_BLOCKS(
		SIGNAL KEY, SW : IN STD_LOGIC;
		CONSTANT score_lock_exp, score_unlock_exp : IN BOOLEAN;
		CONSTANT upR, upG, upB, dwR, dwG, dwB : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		VARIABLE R, G, B : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		SIGNAL click_lock : OUT BOOLEAN;
		VARIABLE score : INOUT NATURAL) IS
	BEGIN
		IF KEY = '0' AND SW = '0' THEN
			R := dwR;
			G := dwG;
			B := dwB;
			
			IF score_lock_exp THEN
				click_lock <= TRUE;
			END IF;
			
		ELSE
			R := upR;
			G := upG;
			B := upB;
			IF score_unlock_exp THEN
				score := score + 1;
				click_lock <= FALSE;
			END IF;
		END IF;
	
	END CREATE_STATIC_BLOCKS;
	
	
	-- Check Button Procedure
	PROCEDURE CHECK_BTN(
		SIGNAL state : INOUT KEY_STATE;
		SIGNAL click_lock : IN BOOLEAN;
		SIGNAL deb_cnt : INOUT NATURAL RANGE 0 to DEBOUNCING_CNT-1;
		SIGNAL counter_lock : OUT STD_LOGIC) IS
	BEGIN
		CASE state IS
			WHEN INIT =>
				IF click_lock THEN state <= RUN; END IF;
				deb_cnt <= 0;
				counter_lock <= '0';
			WHEN RUN =>
				counter_lock <= '1';
				deb_cnt <= deb_cnt + 1;
				IF deb_cnt + 1 = DEBOUNCING_CNT-1 THEN state <= END_TIMER; END IF;
			WHEN END_TIMER =>
				deb_cnt <= 0;
				counter_lock <= '0';
				IF NOT click_lock THEN state <= INIT; END IF;
			WHEN OTHERS =>
				state <= INIT;
		END CASE;
	END CHECK_BTN;
	
	-- Adjust Moving Blocks
	PROCEDURE ADJUST_MOVING_BLOCKS(
		SIGNAL enable : INOUT BOOLEAN;
		SIGNAL pos : INOUT NATURAL;
		VARIABLE speed : IN NATURAL) IS
	BEGIN
		IF(enable) THEN
			pos <= pos + speed;
			IF(pos + speed > STAT_BLK_MIN-1) THEN
				enable <= FALSE;
				pos <= 0;
			END IF;
		END IF;
	END ADJUST_MOVING_BLOCKS;
	
END graphics_lib;