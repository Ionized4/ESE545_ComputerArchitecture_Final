library ieee;
use ieee.std_logic_1164.all;

package register_file_data_types is
	type register_set is array (0 to 127) of std_logic_vector(0 to 127);
end package register_file_data_types;

package body register_file_data_types is
end package body register_file_data_types;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
library cell_spu;
use cell_spu.register_file_data_types.all;

entity register_file is
	port (
	clk		: in std_logic;
	clr		: in std_logic;	-- asynchronous clear	
	
	even_ra_index	: in std_logic_vector(0 to 6);
	even_rb_index	: in std_logic_vector(0 to 6);
	even_rc_index	: in std_logic_vector(0 to 6);
	odd_ra_index	: in std_logic_vector(0 to 6);
	odd_rb_index	: in std_logic_vector(0 to 6);
	odd_rc_index	: in std_logic_vector(0 to 6);
	
	even_wb_en		: in std_logic;	-- write enable from the even pipeline	
	even_wb_index	: in std_logic_vector(0 to 6);
	even_wb_data	: in std_logic_vector(0 to 127);
	odd_wb_en		: in std_logic;	-- write enable from the odd pipeline	
	odd_wb_index	: in std_logic_vector(0 to 6);
	odd_wb_data		: in std_logic_vector(0 to 127);
	
	even_ra			: out std_logic_vector(0 to 127);
	even_rb			: out std_logic_vector(0 to 127);
	even_rc			: out std_logic_vector(0 to 127);	
	odd_ra			: out std_logic_vector(0 to 127);
	odd_rb			: out std_logic_vector(0 to 127);
	odd_rc			: out std_logic_vector(0 to 127)
	);
end register_file;		

architecture behavioral of register_file is
signal registers : register_set;	
begin 
	-- combinational read assignments
	even_ra <= registers(to_integer(unsigned(even_ra_index)));
	even_rb <= registers(to_integer(unsigned(even_rb_index)));
	even_rc <= registers(to_integer(unsigned(even_rc_index)));
	odd_ra <= registers(to_integer(unsigned(odd_ra_index)));
	odd_rb <= registers(to_integer(unsigned(odd_rb_index)));
	odd_rc <= registers(to_integer(unsigned(odd_rc_index)));
	
	rf_write_proc: process(clk, clr)
	begin
		if clr = '1' then	-- asynchronous clear
			for i in 0 to 127 loop
				registers(i) <= (others => '0');	-- write 0 to all registers
			end loop;
		elsif rising_edge(clk) then -- writes on rising edge
			if even_wb_en = '1' then		-- write from even pipe
				registers(to_integer(unsigned(even_wb_index))) <= even_wb_data;
			end if;
			if odd_wb_en = '1' then		-- write from odd pipe
				registers(to_integer(unsigned(odd_wb_index))) <= odd_wb_data;
			end if;
		end if;
	end process rf_write_proc;
end behavioral;