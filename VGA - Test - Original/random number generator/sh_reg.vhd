library IEEE;
use IEEE.std_logic_1164.all;

entity sh_reg is
	generic (
		data_width : integer := 32
	);
	port(
		d : in STD_LOGIC_VECTOR(data_width-1 downto 0);		-- parallel load input
		ser : in STD_LOGIC;									-- serial input
		ld_sh, clk, clrn, setn : in STD_LOGIC;				-- control signals
		q : inout STD_LOGIC_VECTOR(data_width-1 downto 0)	-- parallel output
		);
end sh_reg;

architecture structural of sh_reg is
component d_ff is
	 port(
		 d, clrn, setn, clk : in STD_LOGIC;
		 q, qbar : inout STD_LOGIC
	     );
end component d_ff;

component mux_2to1 is
	 port(
		 a, b, sel : in STD_LOGIC;
		 q : out STD_LOGIC
	     );
end component mux_2to1;

	signal mux_out : STD_LOGIC_VECTOR(data_width-1 downto 0);
	signal q_out : STD_LOGIC_VECTOR(data_width downto 0);
begin
	
	q_out <= ser & q;
	GEN_SH_REG: for I in 0 to data_width-1 generate
		MUX_UX : mux_2to1 port map(a => q_out(I+1), b => d(I), sel => ld_sh, q => mux_out(I));
		DFF_UX : d_ff port map(d => mux_out(I), clrn => clrn, setn => setn, clk => clk, q => q(I), qbar => open);
	end generate GEN_SH_REG;
	
end structural;
