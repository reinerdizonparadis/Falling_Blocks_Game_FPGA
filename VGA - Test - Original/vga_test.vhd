LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY vga_test IS
	PORT(
		-- Clock Inputs
		CLOCK_50	: IN STD_LOGIC;
		
		-- Switch and Key Inputs
		SW			: IN STD_LOGIC_VECTOR(17 DOWNTO 0);
		KEY		: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		
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
END vga_test;

ARCHITECTURE behavior OF vga_test IS
	
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
			h_pulse 	:	INTEGER := 144;    	--horiztonal sync pulse width in pixels
			h_bp	 	:	INTEGER := 248;		--horiztonal back porch width in pixels
			h_pixels	:	INTEGER := 1280;		--horiztonal display width in pixels
			h_fp	 	:	INTEGER := 16;		--horiztonal front porch width in pixels
			h_pol		:	STD_LOGIC := '1';	--horizontal sync pulse polarity (1 = positive, 0 = negative)
			v_pulse 	:	INTEGER := 3;		--vertical sync pulse width in rows
			v_bp	 	:	INTEGER := 38;		--vertical back porch width in rows
			v_pixels	:	INTEGER := 1024;		--vertical display width in rows
			v_fp	 	:	INTEGER := 1;		--vertical front porch width in rows
			v_pol		:	STD_LOGIC := '1');	--vertical sync pulse polarity (1 = positive, 0 = negative)
		PORT(
			pixel_clk	:	IN		STD_LOGIC;	--pixel clock at frequency of VGA mode being used
			reset_n		:	IN		STD_LOGIC;	--active low asycnchronous reset
			h_sync		:	OUT	STD_LOGIC;	--horiztonal sync pulse
			v_sync		:	OUT	STD_LOGIC;	--vertical sync pulse
			disp_ena		:	OUT	STD_LOGIC;	--display enable ('1' = display time, '0' = blanking time)
			column		:	OUT	INTEGER;	--horizontal pixel coordinate
			row			:	OUT	INTEGER;	--vertical pixel coordinate
			n_blank		:	OUT	STD_LOGIC;	--direct blacking output to DAC
			n_sync		:	OUT	STD_LOGIC); --sync-on-green output to DAC
	END COMPONENT vga_controller;
	
	-- Pixel Generation Component
	COMPONENT PIXEL_GEN IS
		PORT(
			disp_ena		:	IN		STD_LOGIC;	--display enable ('1' = display time, '0' = blanking time)
			row			:	IN		INTEGER;	--row pixel coordinate
			column		:	IN		INTEGER;	--column pixel coordinate
			SW				:	IN		STD_LOGIC_VECTOR(17 DOWNTO 0);
			KEY			:	IN		STD_LOGIC_VECTOR(3 DOWNTO 0);
			CLOCK_50		:	IN		STD_LOGIC;
			moving_clk	:	IN		STD_LOGIC;
			rand_clk		:	IN		STD_LOGIC;
			red		:	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --red magnitude output to DAC
			green		:	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --green magnitude output to DAC
			blue		:	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');  --blue magnitude output to DAC
			score		:	OUT	NATURAL := 0;
			LEDR	: OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
			); 
		
	END COMPONENT PIXEL_GEN;
	
	-- BCD to 7 segment Decoder Component
	component bcd_7seg is
		port (
			bi_bar : in std_logic; -- blanking input
			lt_bar : in std_logic; -- lamp test input
			dcba : in std_logic_vector (3 downto 0); --BCD input
			seg: out std_logic_vector(6 downto 0) -- segments in order from a to g
			);
	end component bcd_7seg;
	
	-- Signals
	SIGNAL px_clk, disp_ena : STD_LOGIC;
	SIGNAL vga_col, vga_row : INTEGER;
	SIGNAL clk_counter : NATURAL RANGE 0 to 249999 := 0;
	SIGNAL rand_cnt : NATURAL RANGE 0 to 13574999 := 0;
	SIGNAL debounce_cnt : NATURAL RANGE 0 to 4999 := 0;
	SIGNAL moving_clk : STD_LOGIC := '0';
	SIGNAL rand_clk : STD_LOGIC := '0';
	SIGNAL debounce_clk : STD_LOGIC := '0';
	SIGNAL score_out : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL score : NATURAL := 0;
	
BEGIN
	-- VGA Clock Generator using PLL
	pll_clk: vga_pll PORT MAP(
		clk_in_clk => CLOCK_50,
		reset_reset => SW(17),
		clk_out_clk => px_clk	-- 135 MHz
		);
	
	VGA_CLK <= px_clk;
	
	-- VGA controller circuit
	vga_ctrl: vga_controller PORT MAP(
		pixel_clk => px_clk,
		reset_n => not SW(17),
		h_sync => VGA_HS,
		v_sync => VGA_VS,
		disp_ena => disp_ena,
		column => vga_col,
		row => vga_row,
		n_blank => VGA_BLANK,
		n_sync => VGA_SYNC
		);
	
	-- image generator circuit
	image_gen: PIXEL_GEN PORT MAP(
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
		score => score,
		LEDR => LEDR
		);
	
	-- Switches to Red LEDs
	--LEDR <= SW;
	
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
	PROCESS(CLOCK_50, SW(17))
	BEGIN
		IF SW(17) = '1' THEN
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
	
	-- Display Score to 7 segment displays
	score_out <= std_logic_vector(to_unsigned(score, score_out'length));
	BCD_U3 : bcd_7seg port map(bi_bar => '1', lt_bar => '1', dcba => score_out(15 downto 12), seg => HEX3);
	BCD_U2 : bcd_7seg port map(bi_bar => '1', lt_bar => '1', dcba => score_out(11 downto  8), seg => HEX2);
	BCD_U1 : bcd_7seg port map(bi_bar => '1', lt_bar => '1', dcba => score_out(7  downto  4), seg => HEX1);
	BCD_U0 : bcd_7seg port map(bi_bar => '1', lt_bar => '1', dcba => score_out(3  downto  0), seg => HEX0);
	
END behavior;
