library ieee;
use ieee.std_logic_1164.all;

entity mux_32 is
	port(
	a	: in std_logic_vector(0 to 31);
	b	: in std_logic_vector(0 to 31);
	sel	: in std_logic;
	
	y	: out std_logic_vector(0 to 31)
	);
end mux_32;

architecture dataflow of mux_32 is
begin
	mux_proc: process(all)
	begin
		case sel is
			when '0' =>	y <= a;
			when '1' =>	y <= b;
			when others =>	y <= (others => '0');
		end case;
	end process mux_proc;
end dataflow;