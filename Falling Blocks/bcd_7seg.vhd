LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY bcd_7seg IS
	PORT (
		dcba : IN STD_LOGIC_VECTOR (3 DOWNTO 0);	-- BCD INPUT
		seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0));	-- SEGMENTS IN ORDER FROM A TO G
END bcd_7seg;

ARCHITECTURE dataflow OF bcd_7seg IS   
BEGIN
	seg <= "1000000" WHEN (dcba = "0000") ELSE
			"1111001" WHEN (dcba = "0001") ELSE
			"0100100" WHEN (dcba = "0010") ELSE
			"0110000" WHEN (dcba = "0011") ELSE
			"0011001" WHEN (dcba = "0100") ELSE
			"0010010" WHEN (dcba = "0101") ELSE
			"0000010" WHEN (dcba = "0110") ELSE
			"1111000" WHEN (dcba = "0111") ELSE
			"0000000" WHEN (dcba = "1000") ELSE
			"0011000" WHEN (dcba = "1001") ELSE
			"0001000" WHEN (dcba = "1010") ELSE
			"0000011" WHEN (dcba = "1011") ELSE
			"1000110" WHEN (dcba = "1100") ELSE
			"0100001" WHEN (dcba = "1101") ELSE
			"0000110" WHEN (dcba = "1110") ELSE
			"0001110" WHEN (dcba = "1111") ELSE
			"0000000";
END dataflow;