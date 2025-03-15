library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipe_byte is
	port(
	clk	: in std_logic;
	clr	: in std_logic;
	
	pipe_en_in		: in std_logic;
	shared_ctrl		: in std_logic_vector(0 to 7);
	-- shared_ctrl[1:2] (op)
	-- 00 = count ones in bytes
	-- 01 = average bytes
	-- 10 = absolute difference in bytes
	-- 11 = sum bytes into halfwords
	
	-- inputs
	ra	: in std_logic_vector(0 to 127);
	rb	: in std_logic_vector(0 to 127);
	
	flush	: in std_logic_vector(0 to 1);
	
	-- enable outputs
	pipe_en_out	: out std_logic_vector(1 to 3);
	
	-- result
	result_data	: out std_logic_vector(0 to 127)
	);
end pipe_byte;

architecture behavioral of pipe_byte is
signal s1_ra, s1_rb							: std_logic_vector(0 to 127);
signal s1_popcnt, s1_avg, s1_diff, s1_sum	: std_logic_vector(0 to 127);

signal s2_popcnt, s2_avg, s2_diff, s2_sum	: std_logic_vector(0 to 127);
signal s2_result							: std_logic_vector(0 to 127);

signal pipe_en		: std_logic_vector(1 to 3);
signal s1_op, s2_op	: std_logic_vector(0 to 1);

signal s3_result	: std_logic_vector(0 to 127);
begin
	-- pipeline register between input and stage 1
	byte_input_s1_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' or flush(0) = '1' then
				s1_ra <= (others => '0');
				s1_rb <= (others => '0');
				
				pipe_en(1) <= '0';	
				s1_op <= "00";
			else
				s1_ra <= ra;
				s1_rb <= rb;
				
				pipe_en(1) <= pipe_en_in;	
				s1_op <= shared_ctrl(1 to 2);
			end if;
		end if;
	end process byte_input_s1_reg;
	
	-- stage 1: performs all byte computations
	byte_s1_computations: process(all)
	
	-- functions to assist in computations
	function number_of_ones_8b(input : std_logic_vector(0 to 7)) return unsigned is
		variable n : unsigned(0 to 7);
	begin
		n := (others => '0');	-- n = 0
		for i in 0 to 7 loop
			n := n + unsigned('0' & input(i));
		end loop;
		return n;
	end number_of_ones_8b;
	
	function average_bytes(a : std_logic_vector(0 to 7); b : std_logic_vector(0 to 7)) return std_logic_vector is
		variable v : unsigned(0 to 15);
		variable result : std_logic_vector(0 to 7);
	begin
		v := resize(unsigned(a(0 to 7)), 16) + resize(unsigned(b(0 to 7)), 16);
		result := std_logic_vector(v(7 to 14));
		return result;
	end average_bytes;
	begin
		-- count ones in bytes
		for j in 0 to 15 loop
			s1_popcnt(8*j to 8*j + 7) <= std_logic_vector(number_of_ones_8b(s1_ra(8*j to 8*j + 7)));
		end loop;
		
		-- average bytes
		for j in 0 to 15 loop
			s1_avg(j*8 to j*8+7) <= average_bytes(s1_ra(j*8 to j*8+7), s1_rb(j*8 to j*8+7));
		end loop;
		
		-- absolute difference
		for j in 0 to 15 loop
			s1_diff(8*j to 8*j + 7) <= std_logic_vector(abs(abs(signed(s1_ra(8*j to 8*j + 7))) - abs(signed(s1_rb(8*j to 8*j + 7)))));
		end loop;
		
		-- sum bytes into halfwords
		for j in 0 to 3 loop																		 
			s1_sum(32*j to 32*j + 15) <= std_logic_vector(resize(signed(s1_rb(32*j + 0 to 32*j + 7)), 16) + resize(signed(s1_rb(32*j + 8 to 32*j + 15)), 16) +
				resize(signed(s1_rb(32*j + 16 to 32*j + 23)), 16) + resize(signed(s1_rb(32*j + 24 to 32*j + 31)), 16));
			s1_sum(32*j + 16 to 32*j + 31) <= std_logic_vector(resize(signed(s1_ra(32*j + 0 to 32*j + 7)), 16) + resize(signed(s1_ra(32*j + 8 to 32*j + 15)), 16) +
				resize(signed(s1_ra(32*j + 16 to 32*j + 23)), 16) + resize(signed(s1_ra(32*j + 24 to 32*j + 31)), 16));
		end loop;
	end process byte_s1_computations;
	
	-- pipeline register between stage 1 and stage 2
	byte_s1_s2_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' and flush(1) = '1' then
				s2_popcnt <= (others => '0');
				s2_avg <= (others => '0');
				s2_diff <= (others => '0');
				s2_sum <= (others => '0');
				
				pipe_en(2) <= '0';
				s2_op <= (others => '0');
			else
				s2_popcnt <= s1_popcnt;
				s2_avg <= s1_avg;
				s2_diff <= s1_diff;
				s2_sum <= s1_sum;
				
				
				pipe_en(2) <= pipe_en(1);
				s2_op <= s1_op;
			end if;
		end if;
	end process byte_s1_s2_reg;
	
	-- stage 2: selects result for the specified operation
	byte_s2_result_select: process(all)
	begin
		case s2_op is
			when "00" =>	s2_result <= s2_popcnt;
			when "01" =>	s2_result <= s2_avg;
			when "10" =>	s2_result <= s2_diff;
			when "11" =>	s2_result <= s2_sum;
			when others =>	s2_result <= (others => '0');
		end case;
	end process byte_s2_result_select;
	
	-- pipeline register bewteen stage 2 and stage 3
	byte_s2_s3_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				s3_result <= (others => '0');
				
				pipe_en(3) <= '0';
			else
				s3_result <= s2_result;
				
				pipe_en(3) <= pipe_en(2);
			end if;
		end if;
	end process byte_s2_s3_reg;
	
	result_data <= s3_result;
	pipe_en_out <= pipe_en;
end behavioral;