LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY vga_controller IS
	GENERIC(
		h_pixels	:	INTEGER := 1920;		--horizontal display width in pixels
		h_fp	 	:	INTEGER := 128;		--horizontal front porch width in pixels
		h_pulse 	:	INTEGER := 208;    	--horizontal sync pulse width in pixels
		h_bp	 	:	INTEGER := 336;		--horizontal back porch width in pixels
		h_pol		:	STD_LOGIC := '0';		--horizontal sync pulse polarity (1 = positive, 0 = negative)
		v_pixels	:	INTEGER := 1200;		--vertical display width in rows
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
END vga_controller;

ARCHITECTURE behavior OF vga_controller IS
	CONSTANT	h_period	:	INTEGER := h_pulse + h_bp + h_pixels + h_fp;  --total number of pixel clocks in a row
	CONSTANT	v_period	:	INTEGER := v_pulse + v_bp + v_pixels + v_fp;  --total number of rows in column
BEGIN

	n_blank <= '1';  --no direct blanking
	n_sync <= '0';   --no sync on green
	
	PROCESS(pixel_clk, reset_n)
		VARIABLE h_count	:	INTEGER RANGE 0 TO h_period - 1 := 0;  --horizontal counter (counts the columns)
		VARIABLE v_count	:	INTEGER RANGE 0 TO v_period - 1 := 0;  --vertical counter (counts the rows)
	BEGIN
	
		IF(reset_n = '0') THEN		--reset asserted
			h_count := 0;				--reset horizontal counter
			v_count := 0;				--reset vertical counter
			h_sync <= NOT h_pol;		--deassert horizontal sync
			v_sync <= NOT v_pol;		--deassert vertical sync
			disp_ena <= '0';			--disable display
			row <= 0;					--reset row pixel coordinate
			column <= 0;				--reset column pixel coordinate
			
		ELSIF(pixel_clk'EVENT AND pixel_clk = '1') THEN
			--counters
			IF(h_count < h_period - 1) THEN		--horizontal counter (pixels)
				h_count := h_count + 1;
			ELSE
				h_count := 0;
				IF(v_count < v_period - 1) THEN	--vertical counter (rows)	
						v_count := v_count + 1;
				ELSE	v_count := 0;
				END IF;
			END IF;
			
			--horizontal sync signal
			IF(h_count < h_pixels + h_fp OR h_count >= h_pixels + h_fp + h_pulse) THEN
					h_sync <= NOT h_pol;		--deassert horizontal sync pulse
			ELSE	h_sync <= h_pol;			--assert horizontal sync pulse
			END IF;
			
			--vertical sync signal
			IF(v_count < v_pixels + v_fp OR v_count >= v_pixels + v_fp + v_pulse) THEN
					v_sync <= NOT v_pol;		--deassert vertical sync pulse
			ELSE	v_sync <= v_pol;			--assert vertical sync pulse
			END IF;
			
			--set pixel coordinates
			IF(h_count < h_pixels) THEN column <= h_count;	END IF;	--set horizontal pixel coordinate
			IF(v_count < v_pixels) THEN row <= v_count;		END IF;	--set vertical pixel coordinate

			--set display enable output
			IF(h_count < h_pixels AND v_count < v_pixels) THEN  	--display time
				disp_ena <= '1';											 	--enable display
			ELSE																	--blanking time
				disp_ena <= '0';												--disable display
			END IF;

		END IF;
	END PROCESS;

END behavior;