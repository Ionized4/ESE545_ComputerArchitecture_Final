library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package instruction_memory_types is
	constant instruction_memory_size	: integer := 2048;															  
	type instruction_memory_array is array (0 to instruction_memory_size - 1) of std_logic_vector(0 to 31);
end instruction_memory_types;

package body instruction_memory_types is	
end instruction_memory_types;