library ieee;
use ieee.std_logic_1164.all;
entity bcd_7seg is
	port (
		bi_bar : in std_logic; -- blanking input
		lt_bar : in std_logic; -- lamp test input
		dcba : in std_logic_vector (3 downto 0); --BCD input
		seg: out std_logic_vector(6 downto 0) -- segments in order from a to g
		);
end bcd_7seg;

architecture conditional of bcd_7seg is   
begin
	seg <= "1111111" when bi_bar = '0' else
			"0000000" when lt_bar = '0' else
			"1000000" when (dcba = "0000") else
			"1111001" when (dcba = "0001") else
			"0100100" when (dcba = "0010") else
			"0110000" when (dcba = "0011") else
			"0011001" when (dcba = "0100") else
			"0010010" when (dcba = "0101") else
			"0000010" when (dcba = "0110") else
			"1111000" when (dcba = "0111") else
			"0000000" when (dcba = "1000") else
			"0011000" when (dcba = "1001") else
			"0001000" when (dcba = "1010") else
			"0000011" when (dcba = "1011") else
			"1000110" when (dcba = "1100") else
			"0100001" when (dcba = "1101") else
			"0000110" when (dcba = "1110") else
			"0001110" when (dcba = "1111") else
			"0000000";
end conditional;