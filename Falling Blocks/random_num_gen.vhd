LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY random_num_gen IS
	GENERIC (data_width : integer := 32);
	PORT(
		seed : IN STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);
		clk, clrn, ld_sh : IN STD_LOGIC;
		rand_num : INOUT STD_LOGIC_VECTOR(data_width-1 DOWNTO 0) := "000010110" & (OTHERS => '1') & "0000010");
END random_num_gen;

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
