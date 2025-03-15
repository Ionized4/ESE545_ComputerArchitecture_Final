library ieee;
use ieee.std_logic_1164.all;

entity IF_ID_pipeline_register is
	port(
	clk	: in std_logic;
	clr	: in std_logic;
	
	IF_i0		: in std_logic_vector(0 to 31);
	IF_i1		: in std_logic_vector(0 to 31);
	IF_i0_pc	: in std_logic_vector(0 to 31);
	IF_i1_pc	: in std_logic_vector(0 to 31);
	
	ID_i0		: out std_logic_vector(0 to 31);
	ID_i1		: out std_logic_vector(0 to 31);
	ID_i0_pc	: out std_logic_vector(0 to 31);
	ID_i1_pc	: out std_logic_vector(0 to 31)
	);
end IF_ID_pipeline_register;

architecture behavioral of IF_ID_pipeline_register is
begin
	IF_ID_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				ID_i0 <= (1 | 10 => '1', others => '0');
				ID_i1 <= (1 | 10 => '1', others => '0');
				ID_i0_pc <= (others => '0');
				ID_i1_pc <= (others => '0');	
			else
				ID_i0 <= IF_i0;
				ID_i1 <= IF_i1;
				ID_i0_pc <= IF_i0_pc;
				ID_i1_pc <= IF_i1_pc;
			end if;
		end if;
	end process IF_ID_reg;
end behavioral;