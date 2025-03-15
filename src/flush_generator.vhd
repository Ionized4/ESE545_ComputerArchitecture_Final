library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity flush_generator is
	port(
	ID_even_PC	: in std_logic_vector(0 to 31);
	ID_odd_PC	: in std_logic_vector(0 to 31);
	RF_even_PC	: in std_logic_vector(0 to 31);
	RF_odd_PC	: in std_logic_vector(0 to 31);
	s1_even_PC	: in std_logic_vector(0 to 31);
	
	br_pc			: in std_logic_vector(0 to 31);
	br_pos			: in std_logic;
	br_taken		: in std_logic;
	br_mispredict	: in std_logic;
	
	ID_even_flush	: out std_logic;
	ID_odd_flush	: out std_logic;
	RF_even_flush	: out std_logic;
	RF_odd_flush	: out std_logic;
	s1_even_flush	: out std_logic
	);
end flush_generator;

architecture behavioral of flush_generator is	  
begin
	process (all)
	begin
		-- If the branch instruction was instruction 0, and the branch was taken, flush s1_even
		if br_taken = '1' and br_pos = '0' then
			s1_even_flush <= '1';
		else	-- the instruction currently in this stage of the even pipe is supposed to be executed, because either this instruction was not dependent on the branch or the branch was not taken
				-- and this instruction was supposed to be executed anyways
			s1_even_flush <= '0';
		end if;
	end process;
	
	process (all)
	begin
		if br_taken = '1' and br_pos = '0' and signed(ID_even_PC) = signed(br_pc) + 4 then
			ID_even_flush <= '1';
		elsif br_mispredict = '1' then
			ID_even_flush <= '1';
		else	
			ID_even_flush <= '0';
		end if;
	end process;
	
	process (all)
	begin
		if br_taken = '1' and br_pos = '0' and signed(ID_odd_PC) = signed(br_pc) + 4 then
			ID_odd_flush <= '1';
		elsif br_mispredict = '1' then
			ID_odd_flush <= '1';
		else	
			ID_odd_flush <= '0';
		end if;
	end process;
	
	process (all)
	begin
		if br_taken = '1' and br_pos = '0' and signed(RF_even_PC) = signed(br_pc) + 4 then
			RF_even_flush <= '1';
		elsif br_mispredict = '1' then
			RF_even_flush <= '1';
		else	
			RF_even_flush <= '0';
		end if;
	end process;
	
	process (all)
	begin
		if br_taken = '1' and br_pos = '0' and signed(RF_odd_PC) = signed(br_pc) + 4 then
			RF_odd_flush <= '1';
		elsif br_mispredict = '1' then
			RF_odd_flush <= '1';
		else	
			RF_odd_flush <= '0';
		end if;
	end process;
	
end behavioral;