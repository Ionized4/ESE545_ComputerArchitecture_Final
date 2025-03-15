library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipe_sf1 is
	port(
	clk							: in std_logic;
	clr							: in std_logic;
	
	ra		: in std_logic_vector(0 to 127);
	rb		: in std_logic_vector(0 to 127);
	rc		: in std_logic_vector(0 to 127);
	i16		: in std_logic_vector(0 to 15);
	
	-- shared_ctrl[0]	- source
		-- 0 = register source, 1 = immediate source
	-- shared_ctrl[1:3]	- operation
		-- 000 = arithmetic operation
		-- 001 = logical operation
		-- 010 = compare
		-- 011 = sign extend
		-- 100 = load immediate
		-- 101 = select
		-- 110 = clz
		-- 111 = unused/reserved
	-- shared_ctrl[4:5]	- operand size
	-- shared_ctrl[6:7]	- mode for memory addressing
	shared_ctrl	: in std_logic_vector(0 to 7);
	
	-- sf1_ctrl[0] = sf1_pipe_en
	-- sf1_ctrl[1:2] = logical_operation
		-- 00 = and
		-- 01 = or
		-- 10 = xor
		-- 11 = or across
	-- sf1_ctrl[3] = subtract_ra
	-- sf1_ctrl[4] = complement_rb
	-- sf1_ctrl[5] = complement_logical_result	   
	-- sf1_ctrl[6] = compare_mode[0]
		-- 0 = unsigned, 1 = signed
	-- sf1_ctrl[7] = compare_mode[1]
		-- 0 = equal, 1 = greater than
	-- sf1_ctrl[8] = imm_size
		-- 0 = 10 bit, 1 = 16 bit
	-- sf1_ctrl[9:10] - imm_mask
		-- (9) - lower halfword
		-- (10) - upper halfword
	sf1_ctrl	: in std_logic_vector(0 to 10);
	
	flush	: in std_logic_vector(0 to 1);
	
	wb_en	: out std_logic_vector(1 to 2);
	
	result_data		: out std_logic_vector(0 to 127)
	);
end pipe_sf1;


-- stage 1: operand select
-- stage 2: compute results
architecture behavioral of pipe_sf1 is

signal s1_shared_ctrl, s2_shared_ctrl	: std_logic_vector(0 to 7);
signal s1_sf1_ctrl, s2_sf1_ctrl			: std_logic_vector(0 to 10);

signal s1_ra, s1_rb	: std_logic_vector(0 to 127);
signal s1_i16			: std_logic_vector(0 to 15);
signal s1_op1, s1_op2	: std_logic_vector(0 to 127);

signal s2_op1, s2_op2	: std_logic_vector(0 to 127);

begin
	
	input_s1_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' or flush(0) = '1' then
				s1_ra <= (others => '0');
				s1_rb <= (others => '0');
				s1_i16 <= (others => '0');
				
				s1_shared_ctrl <= (others => '0');
				s1_sf1_ctrl <= (others => '0');
			else
				s1_ra <= ra;
				s1_rb <= rb;
				s1_i16 <= i16;
				
				s1_shared_ctrl <= shared_ctrl;
				s1_sf1_ctrl <= sf1_ctrl;
			end if;
		end if;
	end process input_s1_reg;
	
	s1_operand_select: process(all)
	variable imm	: std_logic_vector(0 to 127);
	begin
		-- operand 1 selection (ra or complemented ra)
		s1_op1 <= s1_ra xor (0 to 127 => s1_sf1_ctrl(3));	-- if s1_sf1_ctrl(3) is set, this complements ra
			
		-- immediate value generation based on operand size, immediate size, and masking
		if s1_shared_ctrl(4 to 5) = "00" then		-- byte operation
			for i in 0 to 15 loop
				case s1_sf1_ctrl(8) is
					when '0' => imm(8*i to 8*i + 7) := s1_i16(2 to 9);
					when '1' => imm(8*i to 8*i + 7) := s1_i16(8 to 15);
					when others => imm := (others => '0');
				end case;
			end loop;
		elsif s1_shared_ctrl(4 to 5) = "01" then	-- halfword operation
			for i in 0 to 7 loop   
				case s1_sf1_ctrl(8) is
					when '0' => imm(16*i to 16*i + 15) := std_logic_vector(resize(signed(s1_i16(0 to 9)), 16));
					when '1' => imm(16*i to 16*i + 15) := s1_i16;
					when others => imm := (others => '0');
				end case;
			end loop;
		elsif s1_shared_ctrl(4 to 5) = "10" then	-- word operation
			for i in 0 to 3 loop		
				case s1_sf1_ctrl(8) is
					when '0' => imm(32*i to 32*i + 31) := std_logic_vector(resize(signed(s1_i16(0 to 9)), 32));
					when '1' => imm(32*i to 32*i + 31) := std_logic_vector(resize(signed(s1_i16), 32));
					when others => imm := (others => '0');
				end case;
				-- old masking logic
				/*if s1_sf1_ctrl(9) = '1' then				-- mask out lower halfword if imm_mask(0) is set
					imm(32*i + 16 to 32*i + 31) := (others => '0');
				end if;
				if s1_sf1_ctrl(10) = '1' then				-- mask out upper halfword if imm_mask(1) is set
					imm(32*i to 32*i + 15) := (others => '0');
				end if; */	 
			end loop;
		else										-- invalid/unused operand size
			imm := (others => '0');
		end if;
		-- masking		***************** masking of upper halfword *******************		********************** masking of lower halfword **************
		imm := imm and (0 to 15 | 32 to 47 | 64 to 79 | 96 to 111 => not s1_sf1_ctrl(10), 16 to 31 | 48 to 63 | 80 to 95 | 112 to 127 => not s1_sf1_ctrl(9));
		
		-- operand 2 selection (rb, complemented rb, or immediate)
		case s1_shared_ctrl(0) is
			when '1' =>	s1_op2 <= imm;
			when '0' => s1_op2 <= s1_rb xor (0 to 127 => s1_sf1_ctrl(4));
			when others =>	s1_op2 <= (others => '0');
		end case;
	end process s1_operand_select;
	
	s1_s2_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' or flush(1) = '1' then
				s2_op1 <= (others => '0');
				s2_op2 <= (others => '0');
				
				s2_shared_ctrl <= (others => '0');
				s2_sf1_ctrl <= (others => '0');
			else
				s2_op1 <= s1_op1;
				s2_op2 <= s1_op2;
				
				s2_shared_ctrl <= s1_shared_ctrl;
				s2_sf1_ctrl <= s1_sf1_ctrl;	
			end if;
		end if;
	end process s1_s2_reg;
	
	s2_computation_proc: process(all)
	variable arith_result		: std_logic_vector(0 to 127);
	variable comp_result		: std_logic_vector(0 to 127);
	variable logical_result		: std_logic_vector(0 to 127);
	variable signext_result		: std_logic_vector(0 to 127);
	variable load_result		: std_logic_vector(0 to 127);
	variable select_result		: std_logic_vector(0 to 127);
	variable clz_result			: std_logic_vector(0 to 127);
	
	function count_leading_zeros_32b(input : std_logic_vector(0 to 31)) return std_logic_vector is
		variable n : integer;
		variable z : std_logic;
	begin																						 
		n := 0;
		z := '1';
		for i in 0 to 31 loop
			if input(i) = '0' and z = '1' then
				n := n + 1;
			else
				z := '0';
			end if;
		end loop;
		return std_logic_vector(to_unsigned(n, 32));
	end count_leading_zeros_32b;
	
	begin
		-- arithmetic
		-- compute sum of operands and carry in for each packed value, implement carry in
		if s2_shared_ctrl(4 to 5) = "01" then		-- add or subtract halfword
			for i in 0 to 7 loop
				arith_result(16*i to 16*i + 15) := std_logic_vector(signed(s2_op1(16*i to 16*i + 15)) + signed(s2_op2(16*i to 16*i + 15)) + signed('0' & s2_sf1_ctrl(3)));	 
			end loop;
		elsif s2_shared_ctrl(4 to 5) = "10" then	-- add or subtract word
			for i in 0 to 3 loop
				arith_result(32*i to 32*i + 31) := std_logic_vector(signed(s2_op1(32*i to 32*i + 31)) + signed(s2_op2(32*i to 32*i + 31)) + signed('0' & s2_sf1_ctrl(3)));			
			end loop;
		else						-- invalid operand size
			arith_result := (others => '0');
		end if;								  
		
		-- logicals										
		-- this is a word operation that uses a 16 bit immediate that gets ZERO extended 
		case s2_sf1_ctrl(1 to 2) is
			when "00" => logical_result := s2_op1 and s2_op2;
			when "01" => logical_result := s2_op1 or s2_op2;
			when "10" => logical_result := s2_op1 xor s2_op2;
			when "11" => logical_result := (0 to 31 => s2_op1(0 to 31) or s2_op1(32 to 63) or s2_op1(64 to 95) or s2_op1(96 to 127), others => '0');
			when others => logical_result := (others => '0');
		end case;
		
		if s2_sf1_ctrl(5) = '1' then
			logical_result := not logical_result;
		end if;
		-- end of logical computation
	
		-- selects															 
		if s2_shared_ctrl(4 to 5) = "00" then		-- form select mask for bytes
			for i in 0 to 15 loop
				select_result(8*i to 8*i + 7) := (others => s2_op1(16 + i));
			end loop;
		elsif s2_shared_ctrl(4 to 5) = "01" then	-- halfwords
			for i in 0 to 7 loop
				select_result(16*i to 16*i + 15) := (others => s2_op2(24 + i));
			end loop;
		elsif s2_shared_ctrl(4 to 5) = "10" then	-- words
			for i in 0 to 3 loop
				select_result(32*i to 32*i + 31) := (others => s2_op2(28 + i));
			end loop;
		else							-- not valid
			select_result := (others => '0');
		end if;
		
		-- sign extensions
		if s2_shared_ctrl(4 to 5) = "00" then			-- extend byte to halfword
			for i in 0 to 7 loop
				signext_result(16*i to 16*i + 15) := std_logic_vector(resize(signed(s2_op1(16*i + 8 to 16*i + 15)), 16));
			end loop;
		elsif s2_shared_ctrl(4 to 5) = "01" then		-- extend halfword to word
			for i in 0 to 3 loop
				signext_result(32*i to 32*i + 31) := std_logic_vector(resize(signed(s2_op1(32*i + 16 to 32*i + 31)), 32));
			end loop;
		elsif s2_shared_ctrl(4 to 5) = "10" then		-- extend word to doubleword
			for i in 0 to 1 loop
				signext_result(64*i to 64*i + 63) := std_logic_vector(resize(signed(s2_op1(64*i + 32 to 64*i + 63)), 64));
			end loop;
		else								-- not valid
			signext_result := (others => '0');
		end if;
		
		-- compares
		if s2_sf1_ctrl(6) = '0' then		-- unsigned equal
			if s2_shared_ctrl(4 to 5) = "00" then			-- bytes
				for i in 0 to 15 loop
					case s2_op1(8*i to 8*i + 7) = s2_op2(8*i to 8*i + 7) is
						when true => comp_result(8*i to 8*i + 7) := (others => '1');
						when false => comp_result(8*i to 8*i + 7) := (others => '0');
						when others => comp_result(8*i to 8*i + 7) := (others => 'X');
					end case;
				end loop;
			elsif s2_shared_ctrl(4 to 5) = "01" then		-- halfwords
				for i in 0 to 7 loop
					case s2_op1(16*i to 16*i + 15) = s2_op2(16*i to 16*i + 15) is
						when true => comp_result(16*i to 16*i + 15) := (others => '1');
						when false => comp_result(16*i to 16*i + 15) := (others => '0');
						when others => comp_result(16*i to 16*i + 15) := (others => 'X');
					end case;
				end loop;
			elsif s2_shared_ctrl(4 to 5) = "10" then		--words
				for i in 0 to 3 loop
					case s2_op1(32*i to 32*i + 31) = s2_op2(32*i to 32*i + 31) is
						when true => comp_result(32*i to 32*i + 31) := (others => '1');
						when false => comp_result(32*i to 32*i + 31) := (others => '0');
						when others => comp_result(32*i to 32*i + 31) := (others => 'X');
					end case;
				end loop;
			else								-- not valid
				comp_result := (others => '0');
			end if;
		elsif s2_sf1_ctrl(6 to 7) = "01" then	-- unsigned greater than   
			if s2_shared_ctrl(4 to 5) = "00" then			-- bytes
				for i in 0 to 15 loop
					case signed(s2_op1(8*i to 8*i + 7)) > signed(s2_op2(8*i to 8*i + 7)) is
						when true => comp_result(8*i to 8*i + 7) := (others => '1');
						when false => comp_result(8*i to 8*i + 7) := (others => '0');
						when others => comp_result(8*i to 8*i + 7) := (others => 'X');
					end case;
				end loop;
			elsif s2_shared_ctrl(4 to 5) = "01" then		-- halfwords
				for i in 0 to 7 loop
					case signed(s2_op1(16*i to 16*i + 15)) > signed(s2_op2(16*i to 16*i + 15)) is
						when true => comp_result(16*i to 16*i + 15) := (others => '1');
						when false => comp_result(16*i to 16*i + 15) := (others => '0');
						when others => comp_result(16*i to 16*i + 15) := (others => 'X');
					end case;
				end loop;
			elsif s2_shared_ctrl(4 to 5) = "10" then		--words
				for i in 0 to 3 loop
					case signed(s2_op1(32*i to 32*i + 31)) > signed(s2_op2(32*i to 32*i + 31)) is
						when true => comp_result(32*i to 32*i + 31) := (others => '1');
						when false => comp_result(32*i to 32*i + 31) := (others => '0');
						when others => comp_result(32*i to 32*i + 31) := (others => 'X');
					end case;
				end loop;
			else								-- not valid
				comp_result := (others => '0');
			end if;
		elsif s2_sf1_ctrl(6 to 7) = "11" then
			if s2_shared_ctrl(4 to 5) = "00" then			-- bytes
				for i in 0 to 15 loop
					case unsigned(s2_op1(8*i to 8*i + 7)) > unsigned(s2_op2(8*i to 8*i + 7)) is
						when true => comp_result(8*i to 8*i + 7) := (others => '1');
						when false => comp_result(8*i to 8*i + 7) := (others => '0');
						when others => comp_result(8*i to 8*i + 7) := (others => 'X');
					end case;
				end loop;
			elsif s2_shared_ctrl(4 to 5) = "01" then		-- halfwords
				for i in 0 to 7 loop
					case unsigned(s2_op1(16*i to 16*i + 15)) > unsigned(s2_op2(16*i to 16*i + 15)) is
						when true => comp_result(16*i to 16*i + 15) := (others => '1');
						when false => comp_result(16*i to 16*i + 15) := (others => '0');
						when others => comp_result(16*i to 16*i + 15) := (others => 'X');
					end case;
				end loop;
			elsif s2_shared_ctrl(4 to 5) = "10" then		--words
				for i in 0 to 3 loop
					case unsigned(s2_op1(32*i to 32*i + 31)) > unsigned(s2_op2(32*i to 32*i + 31)) is
						when true => comp_result(32*i to 32*i + 31) := (others => '1');
						when false => comp_result(32*i to 32*i + 31) := (others => '0');
						when others => comp_result(32*i to 32*i + 31) := (others => 'X');
					end case;
				end loop;
			else								-- not valid
				comp_result := (others => '0');
			end if;
		else							-- error state
			comp_result := (others => '0');
		end if;
		
		-- load immediates
		-- all the logic for sign extension occurs in stage 0, so I can just assign the value here
		load_result := s2_op2;
		
		-- clz
		for i in 0 to 3 loop
			clz_result(32*i to 32*i + 31) := count_leading_zeros_32b(ra(32*i to 32*i + 31));
		end loop;
		
		case s2_shared_ctrl(1 to 3) is
			when "000" =>	result_data <= arith_result;
			when "001" =>	result_data <= logical_result;
			when "010" =>	result_data <= comp_result;
			when "011" =>	result_data <= signext_result;
			when "100" =>	result_data <= load_result;
			when "101" =>	result_data <= select_result;
			when "110" =>	result_data <= clz_result;
			when others =>	result_data <= (others => '0');
		end case;
	end process s2_computation_proc;
	
	wb_en(1) <= s1_sf1_ctrl(0);
	wb_en(2) <= s2_sf1_ctrl(0);
	
end behavioral;