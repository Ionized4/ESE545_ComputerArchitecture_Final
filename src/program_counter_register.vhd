library ieee;
use ieee.std_logic_1164.all;

entity program_counter is
	port(
	clk	: in std_logic;
	clr	: in std_logic;	
	
	pc_in	: in std_logic_vector(0 to 31);
	
	pc_out	: out std_logic_vector(0 to 31)
	);
end program_counter;

architecture behavioral of program_counter is
begin
	pc_reg: process(clk, clr)
	begin
		if rising_edge(clk) then  
			if clr = '1' then
				pc_out <= (others => '0');
			else
				pc_out <= pc_in;
			end if;
		end if;
	end process pc_reg;
end behavioral;