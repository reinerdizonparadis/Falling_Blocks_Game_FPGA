LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY falling_blocks IS
	PORT(
		-- Clock Inputs
		CLOCK_50	: IN STD_LOGIC;
		
		-- Switch and Key Inputs
		SW		: IN STD_LOGIC_VECTOR(17 DOWNTO 0);
		KEY	: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		
		-- LED Outputs
		LEDR	: OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
		LEDG	: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		
		-- 7 Segment Display Outputs
		HEX3	: OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX2	: OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX1	: OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX0	: OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		
		-- VGA Outputs
		VGA_CLK 					: OUT STD_LOGIC;
		VGA_HS, VGA_VS			: OUT STD_LOGIC;
		VGA_BLANK, VGA_SYNC	: OUT STD_LOGIC;
		VGA_R, VGA_G, VGA_B	: OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
END falling_blocks;

ARCHITECTURE structural OF falling_blocks IS
	
	-- PLL Clock Component from Qsys (50MHz => 135 MHz)
	COMPONENT vga_pll IS
		PORT(
			clk_in_clk  : IN  STD_LOGIC := 'X';
			reset_reset : IN  STD_LOGIC := 'X'; 
			clk_out_clk : OUT STD_LOGIC);
	END COMPONENT vga_pll;
	
	-- VGA Controller
	COMPONENT vga_controller IS
		GENERIC(
			h_pixels	:	INTEGER := 1280;		--horizontal display width in pixels
			h_fp	 	:	INTEGER := 16;			--horizontal front porch width in pixels
			h_pulse 	:	INTEGER := 144;    	--horizontal sync pulse width in pixels
			h_bp	 	:	INTEGER := 248;		--horizontal back porch width in pixels
			h_pol		:	STD_LOGIC := '1';		--horizontal sync pulse polarity (1 = positive, 0 = negative)
			v_pixels	:	INTEGER := 1024;		--vertical display width in rows
			v_fp	 	:	INTEGER := 1;			--vertical front porch width in rows
			v_pulse 	:	INTEGER := 3;			--vertical sync pulse width in rows
			v_bp	 	:	INTEGER := 38;			--vertical back porch width in rows
			v_pol		:	STD_LOGIC := '1');	--vertical sync pulse polarity (1 = positive, 0 = negative)
		PORT(
			pixel_clk			:	IN		STD_LOGIC;	--pixel clock at frequency of VGA mode being used
			reset_n				:	IN		STD_LOGIC;	--active low asycnchronous reset
			h_sync, v_sync		:	OUT	STD_LOGIC;	--horizontal, vertical sync pulse
			disp_ena				:	OUT	STD_LOGIC;	--display enable ('1' = display time, '0' = blanking time)
			row, column			:	OUT	INTEGER;		--horizontal, vertical pixel coordinate
			n_blank				:	OUT	STD_LOGIC;	--direct blacking output to DAC
			n_sync				:	OUT	STD_LOGIC); --sync-on-green output to DAC
	END COMPONENT vga_controller;
	
	-- Image Generation Component
	COMPONENT graphic_generator IS
		PORT(
			disp_ena		:	IN		STD_LOGIC;	--display enable ('1' = display time, '0' = blanking time)
			row			:	IN		INTEGER;		--row pixel coordinate
			column		:	IN		INTEGER;		--column pixel coordinate
			SW				:	IN		STD_LOGIC_VECTOR(17 DOWNTO 0);
			KEY			:	IN		STD_LOGIC_VECTOR(3 DOWNTO 0);
			CLOCK_50		:	IN		STD_LOGIC;
			moving_clk	:	IN		STD_LOGIC;
			rand_clk		:	IN		STD_LOGIC;
			red		:	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --red magnitude output to DAC
			green		:	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --green magnitude output to DAC
			blue		:	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --blue magnitude output to DAC
			score		:	OUT	NATURAL := 0
			); 
		
	END COMPONENT graphic_generator;
	
	-- HEX to 7 segment Decoder Component
	COMPONENT hex_7seg IS
		PORT (
		dcba : IN STD_LOGIC_VECTOR (3 DOWNTO 0);	-- BCD INPUT
		seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0));	-- SEGMENTS IN ORDER FROM A TO G
	END COMPONENT hex_7seg;
	
	-- Clock Generator Circuits
	COMPONENT clock_gen IS
		PORT(
			CLOCK_50			: IN STD_LOGIC;
			reset				: IN STD_LOGIC;
			moving_clk		: INOUT STD_LOGIC := '0';
			rand_clk			: INOUT STD_LOGIC := '0'
		);
	END COMPONENT clock_gen;
	
	-- Signals
	SIGNAL px_clk, disp_ena : STD_LOGIC;
	SIGNAL vga_col, vga_row : INTEGER;
	SIGNAL moving_clk, rand_clk : STD_LOGIC := '0';
	SIGNAL score_out : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL score : NATURAL := 0;
	
BEGIN
	-- VGA Clock Generator using PLL
	pll_clk: vga_pll PORT MAP(
		clk_in_clk => CLOCK_50,
		reset_reset => SW(17),
		clk_out_clk => px_clk);	-- 135 MHz
	
	VGA_CLK <= px_clk;
	
	-- VGA controller circuit
	vga_ctrl: vga_controller PORT MAP(
		pixel_clk => px_clk,
		reset_n => not SW(17),
		h_sync => VGA_HS,
		v_sync => VGA_VS,
		disp_ena => disp_ena,
		row => vga_row,
		column => vga_col,
		n_blank => VGA_BLANK,
		n_sync => VGA_SYNC);
	
	-- image generator circuit
	image_gen: graphic_generator PORT MAP(
		disp_ena => disp_ena,
		row => vga_row,
		column => vga_col,
		SW => SW,
		KEY => KEY,
		CLOCK_50 => CLOCK_50,
		moving_clk => moving_clk,
		rand_clk => rand_clk,
		red => VGA_R,
		green => VGA_G,
		blue => VGA_B,
		score => score);
	
	-- Switches to Red LEDs
	LEDR <= SW;
	
	-- Key Buttons to Green LEDs
	LEDG(7) <= NOT KEY(3);
	LEDG(6) <= NOT KEY(3);
	LEDG(5) <= NOT KEY(2);
	LEDG(4) <= NOT KEY(2);
	LEDG(3) <= NOT KEY(1);
	LEDG(2) <= NOT KEY(1);
	LEDG(1) <= NOT KEY(0);
	LEDG(0) <= NOT KEY(0);
	
	-- Clock Generation for moving pixel, random number generator, and debouncing
	clk_gen : clock_gen PORT MAP(
		CLOCK_50 => CLOCK_50,
		reset => SW(17),
		moving_clk => moving_clk,
		rand_clk => rand_clk);
	
	-- Display Score to 7 segment displays
	score_out <= std_logic_vector(to_unsigned(score, score_out'length));
	BCD_U3 : hex_7seg port map(dcba => score_out(15 downto 12), seg => HEX3);
	BCD_U2 : hex_7seg port map(dcba => score_out(11 downto  8), seg => HEX2);
	BCD_U1 : hex_7seg port map(dcba => score_out(7  downto  4), seg => HEX1);
	BCD_U0 : hex_7seg port map(dcba => score_out(3  downto  0), seg => HEX0);
END structural;