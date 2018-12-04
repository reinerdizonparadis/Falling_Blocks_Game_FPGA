library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity d_ff is
	 port(
		 d, clrn, setn, clk : in STD_LOGIC;
		 q : inout STD_LOGIC := '1';
		 qbar : inout STD_LOGIC := '0'
	     );
end d_ff;

architecture behavioral of d_ff is
begin
	process(clk, clrn, setn)
	begin
		if clrn = '0' then
			q <= '0';
			qbar <= '1';
		elsif setn = '0' then
			q <= '1';
			qbar <= '0';
		elsif clk'event and clk = '1' then
			q <= d;
			qbar <= not d;
		end if;
	end process;
end behavioral;
