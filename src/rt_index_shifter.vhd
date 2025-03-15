library ieee;
use ieee.std_logic_1164.all;

entity rt_index_shifter is
	port(
	clk		: in std_logic;
	clr		: in std_logic;
	
	rt_index_in	: in std_logic_vector(0 to 6);
	
	s1_rt_index	: out std_logic_vector(0 to 6);
	s2_rt_index	: out std_logic_vector(0 to 6);
	s3_rt_index	: out std_logic_vector(0 to 6);
	s4_rt_index	: out std_logic_vector(0 to 6);
	s5_rt_index	: out std_logic_vector(0 to 6);
	s6_rt_index	: out std_logic_vector(0 to 6);
	s7_rt_index	: out std_logic_vector(0 to 6);
	wb_rt_index	: out std_logic_vector(0 to 6)
	);
end rt_index_shifter;

architecture behavioral of rt_index_shifter is
signal s1, s2, s3, s4, s5, s6, s7, wb	: std_logic_vector(0 to 6);
begin
	s1_rt_index <= s1;
	s2_rt_index <= s2;
	s3_rt_index <= s3;
	s4_rt_index <= s4;
	s5_rt_index <= s5;
	s6_rt_index <= s6;
	s7_rt_index <= s7;
	wb_rt_index <= wb;
	
	rt_index_shifter_proc: process(clk, clr)
	begin
		 
		if rising_edge(clk) then
			if clr = '1' then
				s1 <= "0000000";
				s2 <= "0000000";
				s3 <= "0000000";
				s4 <= "0000000";
				s5 <= "0000000";
				s6 <= "0000000";
				s7 <= "0000000";
				wb <= "0000000";
			else
				s1 <= rt_index_in;
				s2 <= s1;
				s3 <= s2;
				s4 <= s3;
				s5 <= s4;
				s6 <= s5;
				s7 <= s6;
				wb <= s7;
			end if;
		end if;
	end process rt_index_shifter_proc;
end behavioral;