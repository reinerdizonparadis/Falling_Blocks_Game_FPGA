LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

entity random_num_gen IS
	generic (data_width : integer := 32);
	port(
		seed : in STD_LOGIC_VECTOR(data_width-1 downto 0);
		clk, clrn, ld_sh : in STD_LOGIC;
		rand_num : inout STD_LOGIC_VECTOR(data_width-1 downto 0) := "000010110" & (others => '1') & "0000010");
end random_num_gen;

ARCHITECTURE structural of random_num_gen IS
BEGIN
	
	PROCESS(clk, ld_sh)
	BEGIN
	
	IF(ld_sh = '1') THEN
		rand_num <= seed;
	ELSIF(clrn = '0') THEN
		rand_num <= (others => '0');
	ELSIF(clk'event and clk = '1') THEN
		rand_num(data_width-1) <= rand_num(31) xor rand_num(21) xor rand_num(1) xor rand_num(0);
		rand_num(data_width-2 DOWNTO 0) <= rand_num(data_width-1 DOWNTO 1);
	END IF;
	
	
	END PROCESS;
	
END structural;
