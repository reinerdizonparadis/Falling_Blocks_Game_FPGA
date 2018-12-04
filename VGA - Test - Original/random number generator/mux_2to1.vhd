library IEEE;
use IEEE.std_logic_1164.all;

entity mux_2to1 is
	 port(
		 a, b, sel : in STD_LOGIC;
		 q : out STD_LOGIC
	     );
end mux_2to1;

architecture dataflow of mux_2to1 is
begin

	q <= a when sel = '0' else
		 b when sel = '1';

end dataflow;
