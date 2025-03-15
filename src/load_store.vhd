library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;	 

package ls_data_types is
	constant mem_size	: integer := 4096;	-- must be some power of 2
	constant LSLR		: std_logic_vector(0 to 31) := std_logic_vector(to_unsigned(mem_size - 1, 32));
	type memory_array is array (0 to mem_size - 1) of std_logic_vector(0 to 127);
end ls_data_types;

package body ls_data_types is	
end ls_data_types;	  

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.float_pkg.all;
library cell_spu;
use cell_spu.ls_data_types.all;

entity load_store is
	port(
	clk		: in std_logic;
	clr		: in std_logic;
	
	read_address	: in std_logic_vector(0 to 31);
	write_address	: in std_logic_vector(0 to 31);
	write_data		: in std_logic_vector(0 to 127);
	write_en		: in std_logic;
	
	read_data		: out std_logic_vector(0 to 127)
	);
end load_store;

architecture behavioral of load_store is  
signal memory	: memory_array;
begin
	read_data <= memory(to_integer(unsigned(read_address and LSLR))); 
	
	mem_write_proc: process(clr, clk)
	begin
		if clr = '1' then
			for i in 0 to mem_size - 1 loop
				memory(i) <= (others => '0');	 
			end loop;	   
			
			-- integer matrix
			---- put matrix A into LS
--			memory(0) <= (0 to 31 => std_logic_vector(to_signed(1, 32)), 32 to 63 => std_logic_vector(to_signed(2, 32)),
--			64 to 95 => std_logic_vector(to_signed(3, 32)), 96 to 127 => std_logic_vector(to_signed(4, 32)));
--			memory(16) <= (0 to 31 => std_logic_vector(to_signed(5, 32)), 32 to 63 => std_logic_vector(to_signed(6, 32)),
--			64 to 95 => std_logic_vector(to_signed(7, 32)), 96 to 127 => std_logic_vector(to_signed(8, 32)));
--			memory(32) <= (0 to 31 => std_logic_vector(to_signed(9, 32)), 32 to 63 => std_logic_vector(to_signed(10, 32)),
--			64 to 95 => std_logic_vector(to_signed(11, 32)), 96 to 127 => std_logic_vector(to_signed(12, 32)));
--			memory(48) <= (0 to 31 => std_logic_vector(to_signed(13, 32)), 32 to 63 => std_logic_vector(to_signed(14, 32)),
--			64 to 95 => std_logic_vector(to_signed(15, 32)), 96 to 127 => std_logic_vector(to_signed(16, 32)));
--			
--			-- put matrix B into LS
--			memory(64) <= (0 to 31 => std_logic_vector(to_signed(17, 32)), 32 to 63 => std_logic_vector(to_signed(18, 32)),
--			64 to 95 => std_logic_vector(to_signed(19, 32)), 96 to 127 => std_logic_vector(to_signed(20, 32)));
--			memory(80) <= (0 to 31 => std_logic_vector(to_signed(21, 32)), 32 to 63 => std_logic_vector(to_signed(22, 32)),
--			64 to 95 => std_logic_vector(to_signed(23, 32)), 96 to 127 => std_logic_vector(to_signed(24, 32)));
--			memory(96) <= (0 to 31 => std_logic_vector(to_signed(25, 32)), 32 to 63 => std_logic_vector(to_signed(26, 32)),
--			64 to 95 => std_logic_vector(to_signed(27, 32)), 96 to 127 => std_logic_vector(to_signed(28, 32)));
--			memory(112) <= (0 to 31 => std_logic_vector(to_signed(29, 32)), 32 to 63 => std_logic_vector(to_signed(30, 32)),
--			64 to 95 => std_logic_vector(to_signed(31, 32)), 96 to 127 => std_logic_vector(to_signed(32, 32)));

			-- floating point matrix
			-- put matrix A into LS
			memory(0) <= (0 to 31 => to_slv(to_float(to_signed(0, 32))), 32 to 63 => to_slv(to_float(to_signed(1, 32))),
			64 to 95 => to_slv(to_float(to_signed(2, 32))), 96 to 127 => to_slv(to_float(to_signed(3, 32))));
			memory(16) <= (0 to 31 => to_slv(to_float(to_signed(4, 32))), 32 to 63 => to_slv(to_float(to_signed(5, 32))),
			64 to 95 => to_slv(to_float(to_signed(6, 32))), 96 to 127 => to_slv(to_float(to_signed(7, 32))));
			memory(32) <= (0 to 31 => to_slv(to_float(to_signed(8, 32))), 32 to 63 => to_slv(to_float(to_signed(9, 32))),
			64 to 95 => to_slv(to_float(to_signed(10, 32))), 96 to 127 => to_slv(to_float(to_signed(11, 32))));
			memory(48) <= (0 to 31 => to_slv(to_float(to_signed(12, 32))), 32 to 63 => to_slv(to_float(to_signed(13, 32))),
			64 to 95 => to_slv(to_float(to_signed(14, 32))), 96 to 127 => to_slv(to_float(to_signed(15, 32))));
			
			-- put matrix B into LS
			memory(64) <= (0 to 31 => to_slv(to_float(to_signed(16, 32))), 32 to 63 => to_slv(to_float(to_signed(17, 32))),
			64 to 95 => to_slv(to_float(to_signed(18, 32))), 96 to 127 => to_slv(to_float(to_signed(19, 32))));
			memory(80) <= (0 to 31 => to_slv(to_float(to_signed(20, 32))), 32 to 63 => to_slv(to_float(to_signed(21, 32))),
			64 to 95 => to_slv(to_float(to_signed(22, 32))), 96 to 127 => to_slv(to_float(to_signed(23, 32))));
			memory(96) <= (0 to 31 => to_slv(to_float(to_signed(24, 32))), 32 to 63 => to_slv(to_float(to_signed(25, 32))),
			64 to 95 => to_slv(to_float(to_signed(26, 32))), 96 to 127 => to_slv(to_float(to_signed(27, 32))));
			memory(112) <= (0 to 31 => to_slv(to_float(to_signed(28, 32))), 32 to 63 => to_slv(to_float(to_signed(29, 32))),
			64 to 95 => to_slv(to_float(to_signed(30, 32))), 96 to 127 => to_slv(to_float(to_signed(31, 32))));
		elsif rising_edge(clk) then
			if write_en = '1' then
				memory(to_integer(unsigned(write_address and LSLR))) <= write_data;
			end if;
		end if;
	end process mem_write_proc;
end behavioral;		 