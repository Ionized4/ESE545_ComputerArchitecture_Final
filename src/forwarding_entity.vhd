library ieee;
use ieee.std_logic_1164.all;

entity forwarding_register is
	port(
	clk		: in std_logic;
	clr		: in std_logic;
	
	data_in			: in std_logic_vector(0 to 127);  
	data_ready_in	: in std_logic;
	
	data_out		: out std_logic_vector(0 to 127); 
	data_ready_out	: out std_logic
	);
end forwarding_register;

architecture behavioral of forwarding_register is
begin
	fwd_reg_proc: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				data_out <= (others => '0');  
				data_ready_out <= '0';
			else
				data_out <= data_in;		
				data_ready_out <= data_ready_in;
			end if;
		end if;
	end process fwd_reg_proc;
end behavioral;
	
	