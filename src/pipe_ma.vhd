library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.float_pkg.all;

entity pipe_ma is
	port(
	clk	: in std_logic;
	clr	: in std_logic;
	
	ra	: in std_logic_vector(0 to 127);
	rb	: in std_logic_vector(0 to 127);
	rc	: in std_logic_vector(0 to 127);
	imm	: in std_logic_vector(0 to 9);
	
	source	: in std_logic;
	ma_ctrl_in	: in std_logic_vector(0 to 9);
	-- ma_ctrl[0] - ma_pipe_en
	-- ma_ctrl[1] - ma_sign
	-- ma_ctrl[2] - ma_citf
	-- ma_ctrl[3] - ma_cfti
	-- ma_ctrl[4] - ma_scale_conv
	-- ma_ctrl[5] - ma_mult
	-- ma_ctrl[6] - ma_add_en
	-- ma_ctrl[7] - ma_add_mode
	-- ma_ctrl[8] - ma_negate
	-- ma_ctrl[9] - ma_shift_right
	
	flush	: in std_logic_vector(0 to 1);
	
	float_wb_en			: out std_logic_vector(1 to 6);
	float_result_data	: out std_logic_vector(0 to 127);
	int_wb_en			: out std_logic_vector(1 to 7);
	int_result_data		: out std_logic_vector(0 to 127)
	);
	
end pipe_ma;

architecture behavioral of pipe_ma is

signal f_wb_en	: std_logic_vector(1 to 6);
signal i_wb_en	: std_logic_vector(1 to 7);

signal s1_source	: std_logic;

signal s1_ma_ctrl	: std_logic_vector(0 to 9);
signal s2_ma_ctrl	: std_logic_vector(0 to 9);
signal s3_ma_ctrl	: std_logic_vector(0 to 9);
signal s4_ma_ctrl	: std_logic_vector(0 to 9);
signal s5_ma_ctrl	: std_logic_vector(0 to 9);
signal s6_ma_ctrl	: std_logic_vector(0 to 9);
signal s7_ma_ctrl	: std_logic_vector(0 to 9);

signal s1_scale, s2_scale, s3_scale	: std_logic_vector(0 to 7);
signal s4_scale, s5_scale, s6_scale	: std_logic_vector(0 to 7);

-- s1 inputs
signal s1_ra, s1_rb, s1_rc	: std_logic_vector(0 to 127);
signal s1_imm				: std_logic_vector(0 to 9);
-- s1 outputs
signal s1_multiplicand		: std_logic_vector(0 to 127);
signal s1_multiplier		: std_logic_vector(0 to 127);
signal s1_addend			: std_logic_vector(0 to 127);

-- s2 inputs
signal s2_multiplicand_in	: std_logic_vector(0 to 127);
signal s2_multiplier_in		: std_logic_vector(0 to 127);
signal s2_addend_in			: std_logic_vector(0 to 127);
-- s2 outputs
signal s2_multiplicand_out	: std_logic_vector(0 to 127);
signal s2_multiplier_out	: std_logic_vector(0 to 127);
signal s2_addend_out		: std_logic_vector(0 to 127);

-- s3 inputs
signal s3_multiplicand		: std_logic_vector(0 to 127);
signal s3_multiplier		: std_logic_vector(0 to 127);
signal s3_addend			: std_logic_vector(0 to 127);
-- s3 outputs
signal s3_product			: std_logic_vector(0 to 127);

-- s4 inputs
signal s4_product			: std_logic_vector(0 to 127);
signal s4_addend			: std_logic_vector(0 to 127);
-- s4 outputs
signal s4_sum				: std_logic_vector(0 to 127);

-- s5 input
signal s5_sum				: std_logic_vector(0 to 127);
-- s5 output
signal s5_result			: std_logic_vector(0 to 127);

-- s6 input
signal s6_result_in			: std_logic_vector(0 to 127);
-- s6 output
signal s6_int_result		: std_logic_vector(0 to 127);

-- s7 input (which is just the output)
signal s7_int_result		: std_logic_vector(0 to 127);

begin
	-- input to stage 1 register
	pipe_ma_input_s1_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' or flush(0) = '1' then
				s1_ra <= (others => '0');
				s1_rb <= (others => '0');
				s1_rc <= (others => '0');
				s1_imm <= (others => '0');
				
				s1_source <= '0';
				s1_ma_ctrl <= (others => '0');
				s1_scale <= (others => '0');
				
				f_wb_en(1) <= '0';
				i_wb_en(1) <= '0';
			else
				s1_ra <= ra;
				s1_rb <= rb;
				s1_rc <= rc;
				s1_imm <= imm;
				
				s1_source <= source;
				s1_ma_ctrl <= ma_ctrl_in;
				s1_scale <= imm(0 to 7);
				
				f_wb_en(1) <= ma_ctrl_in(0) and not ma_ctrl_in(3);
				i_wb_en(1) <= ma_ctrl_in(0) and ma_ctrl_in(3);
			end if;
		end if;
	end process pipe_ma_input_s1_reg;
	
	-- stage 1: operand selection logic
	pipe_ma_s1_op_select: process(all)
	begin
		-- select multiplicand
		-- in all cases, multiplicand is ra
		s1_multiplicand <= s1_ra;
		
		-- select multiplier
		-- if source = 1, the multiplier comes from the sign extended immediate (immediates only come from integer instructions)
		-- if source = 0, the multiplier is the value in rb
		case s1_source is
			when '1' =>
			for i in 0 to 3 loop
				s1_multiplier(32*i to 32*i + 31) <=	std_logic_vector(resize(signed(s1_imm), 32));
			end loop;
			when '0' =>	s1_multiplier <= s1_rb;
			when others =>	s1_multiplier <= (others => '0');
		end case;
		
		-- select addend
		-- if mult = 1, then the addend is the value in rc
		-- if mult = 0, the addend is the value in rb
		-- there is no way mult = 0 and source = 1, because that would just be an add immediate instruction which gets executed in the sf1 pipe
		case s1_ma_ctrl(5) is
			when '1' =>	s1_addend <= s1_rc;
			when '0' =>	s1_addend <= s1_rb;
			when others =>	s1_addend <= (others => '0');
		end case;
	end process pipe_ma_s1_op_select;
	
	-- pipeline register between s1 and s2
	pipe_ma_s1_s2_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' or flush(1) = '1' then
				s2_multiplicand_in <= (others => '0');
				s2_multiplier_in <= (others => '0');
				s2_addend_in <= (others => '0');
				
				s2_ma_ctrl <= (others => '0');
				s2_scale <= (others => '0');
				
				f_wb_en(2) <= '0';
				i_wb_en(2) <= '0';
			else
				s2_multiplicand_in <= s1_multiplicand;
				s2_multiplier_in <= s1_multiplier;
				s2_addend_in <= s1_addend;
				
				s2_ma_ctrl <= s1_ma_ctrl;
				s2_scale <= s1_scale;
				
					  
				f_wb_en(2) <= f_wb_en(1);
				i_wb_en(2) <= i_wb_en(1);
			end if;
		end if;
	end process pipe_ma_s1_s2_reg;
	
	-- stage 2: integer to floating point conversion
	pipe_ma_s2_citf: process(all)
	variable multiplicand, multiplier, addend	: std_logic_vector(0 to 127);
	begin
		-- perform a cast based on the citf & sign signals
		-- inconsequential note on implementation: I decided to put the for loop outside of the case statement to reduce code size.
		-- not inconsequential note on implementation: integer multiplication requires 16 bit value to be cast, but conversion instructions require all 32 bits to be cast
		-- this current implementation only casts 16 bit values, conversion needs to be done differently based on the type of instruction, potentially use the mult control signal to determine
		-- size of conversion
		for i in 0 to 3 loop
			case s2_ma_ctrl(2) & s2_ma_ctrl(1)is
				when "10" => -- unsigned conversion
				multiplicand(32*i to 32*i + 31) := to_slv(to_float(resize(unsigned(s2_multiplicand_in(32*i + 16 to 32*i + 31)), 32)));
				multiplier(32*i to 32*i + 31) := to_slv(to_float(resize(unsigned(s2_multiplier_in(32*i + 16 to 32*i + 31)), 32)));
				addend(32*i to 32*i + 31) := to_slv(to_float(resize(unsigned(s2_addend_in(32*i to 32*i + 31)), 32)));
				when "11" => -- signed conversion
				multiplicand(32*i to 32*i + 31) := to_slv(to_float(resize(signed(s2_multiplicand_in(32*i + 16 to 32*i + 31)), 32)));
				multiplier(32*i to 32*i + 31) := to_slv(to_float(resize(signed(s2_multiplier_in(32*i + 16 to 32*i + 31)), 32)));
				addend(32*i to 32*i + 31) := to_slv(to_float(resize(signed(s2_addend_in(32*i to 32*i + 31)), 32)));
				when "00" | "01" =>	-- no conversion
				multiplicand(32*i to 32*i + 31) := s2_multiplicand_in(32*i to 32*i + 31);
				multiplier(32*i to 32*i + 31) := s2_multiplier_in(32*i to 32*i + 31);
				addend(32*i to 32*i + 31) := s2_addend_in(32*i to 32*i + 31);
				when others =>
				multiplicand(32*i to 32*i + 31) := (others => '0');
				multiplier(32*i to 32*i + 31) := (others => '0');
				addend(32*i to 32*i + 31) := (others => '0'); 
			end case;
			
			-- scale the result based on the scale_conv signal
			if s2_ma_ctrl(4) = '1' then
				for i in 0 to 3 loop
					-- untested scaling function
					-- IEEE 754 FP numbers are represented as the following:
					-- [sign] * 1.[mantissa] * 2^[exponent]
					-- and have the following encoding: [1 bit sign][8 bit exponent][23 bit mantissa]
					-- since the scaling functions multiply the floating point number by 2^(155 - i8), the resulting number is
					-- [sign] * 1.[mantissa] * 2^[exponent] * 2^(155 - i8) = [sign] * 1.[mantissa] * 2^[exponent + (155 - i8)]
					-- thus, the scaling functions simply modifies the exponent field of the floating point number by adding (155 - i8) to the exponent field
					-- here, I scale all three numbers for no particular reason, as in the only instructions that scale operands, the multiplicand is the only relevant operand
					multiplicand(32*i + 1 to 32*i + 8) := std_logic_vector(signed(multiplicand(32*i + 1 to 32*i + 8)) + (to_signed(155, 8) - signed(s2_scale)));
					multiplier(32*i + 1 to 32*i + 8) := std_logic_vector(signed(multiplier(32*i + 1 to 32*i + 8)) + (to_signed(155, 8) - signed(s2_scale)));
					addend(32*i + 1 to 32*i + 8) := std_logic_vector(signed(addend(32*i + 1 to 32*i + 8)) + (to_signed(155, 8) - signed(s2_scale)));			 
				end loop;
			end if;
			
			s2_multiplicand_out <= multiplicand;
			s2_multiplier_out <= multiplier;
			s2_addend_out <= addend;
		end loop;
	end process pipe_ma_s2_citf;
	
	-- pipeline register between s2 and s3
	pipe_ma_s2_s3_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				s3_multiplicand <= (others => '0');
				s3_multiplier <= (others => '0');
				s3_addend <= (others => '0');
				
				s3_ma_ctrl <= (others => '0');
				s3_scale <= (others => '0');
				
				f_wb_en(3) <= '0';
				i_wb_en(3) <= '0';
			else
				s3_multiplicand <= s2_multiplicand_out;
				s3_multiplier <= s2_multiplier_out;
				s3_addend <= s2_addend_out;
				
				s3_ma_ctrl <= s2_ma_ctrl;
				s3_scale <= s2_scale;
				
				f_wb_en(3) <= f_wb_en(2);
				i_wb_en(3) <= i_wb_en(2);
			end if;
		end if;
	end process pipe_ma_s2_s3_reg;
	
	-- stage 3: multiplication
	pipe_ma_s3_mult: process(all)
	begin
		for i in 0 to 3 loop
			case s3_ma_ctrl(5) is
				when '1' =>	s3_product(32*i to 32*i + 31) <= to_slv(to_float(s3_multiplicand(32*i to 32*i + 31)) * to_float(s3_multiplier(32*i to 32*i + 31)));
				when '0' => s3_product(32*i to 32*i + 31) <= s3_multiplicand(32*i to 32*i + 31);
				when others =>	s3_product <= (others => '0');
			end case;
		end loop;
	end process pipe_ma_s3_mult;
	
	-- pipeline register between s3 and s4
	pipe_ma_s3_s4_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				s4_product <= (others => '0');
				s4_addend <= (others => '0');
				
				s4_ma_ctrl <= (others => '0');
				s4_scale <= (others => '0');
				
				f_wb_en(4) <= '0';
				i_wb_en(4) <= '0';
			else
				s4_product <= s3_product;
				s4_addend <= s3_addend;
				
				s4_ma_ctrl <= s3_ma_ctrl;
				s4_scale <= s3_scale;
				
				f_wb_en(4) <= f_wb_en(3);
				i_wb_en(4) <= i_wb_en(3);
			end if;
		end if;
	end process pipe_ma_s3_s4_reg;
	
	-- stage 4: addition
	pipe_ma_s4_add: process(all)
	begin
		for i in 0 to 3 loop
			case s4_ma_ctrl(6 to 7) is	-- add_en & add_mode
				when "00" | "01" =>	s4_sum(32*i to 32*i + 31) <= s4_product(32*i to 32*i + 31);	-- adder is disabled
				when "10" =>		s4_sum(32*i to 32*i + 31) <= to_slv(to_float(s4_product(32*i to 32*i + 31)) + to_float(s4_addend(32*i to 32*i + 31)));	-- adder enabled and in addition mode
				when "11" =>		s4_sum(32*i to 32*i + 31) <= to_slv(to_float(s4_product(32*i to 32*i + 31)) - to_float(s4_addend(32*i to 32*i + 31)));	-- adder enabled and in subtraction mode
				when others =>		s4_sum(32*i to 32*i + 31) <= (others => '0');
			end case;
		end loop;
	end process pipe_ma_s4_add;
	
	-- pipeline register between s4 and s5
	pipe_ma_s4_s5_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				s5_sum <= (others => '0');
				
				s5_ma_ctrl <= (others => '0');
				s5_scale <= (others => '0');
				
				f_wb_en(5) <= '0';
				i_wb_en(5) <= '0';
			else
				s5_sum <= s4_sum;
				
				s5_ma_ctrl <= s4_ma_ctrl;
				s5_scale <= s4_scale;
				
				f_wb_en(5) <= f_wb_en(4);
				i_wb_en(5) <= i_wb_en(4);
			end if;
		end if;
	end process pipe_ma_s4_s5_reg;
	
	-- stage 5: negation
	pipe_ma_s5_negate: process(all)
	variable mask	: std_logic_vector(0 to 127);
	begin
		mask := (0 | 32 | 64 | 96 => s5_ma_ctrl(8), others => '0');
		s5_result <= s5_sum xor mask;
	end process pipe_ma_s5_negate;
	
	-- pipeline register between s5 and s6
	pipe_ma_s5_s6_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				s6_result_in <= (others => '0');
				
				s6_ma_ctrl <= (others => '0');
				s6_scale <= (others => '0');
				
				f_wb_en(6) <= '0';
				i_wb_en(6) <= '0';
			else
				s6_result_in <= s5_result;
				
				s6_ma_ctrl <= s5_ma_ctrl;
				s6_scale <= s5_scale;
				
				f_wb_en(6) <= f_wb_en(5);
				i_wb_en(6) <= i_wb_en(5);
			end if;
		end if;
	end process pipe_ma_s5_s6_reg;
	
	-- output floating point results
	float_result_data <= s6_result_in;
	float_wb_en <= f_wb_en;
	/***********************************************************************************************************************************************
	 * DO NOT FORGET TO SET UP THE VALID OUTPUTS APPROPRIATELY ***************************************************************************************
	 *************************************************************************************************************************************************/
	 -- I did :)
	
	-- stage 6: convert float to int
	pipe_ma_s6_cfti: process(all)
	variable result	: std_logic_vector(0 to 127);
	begin
		-- if scaling is enabled, scale the result based on the value in s6_scale
		result := s6_result_in;
		if s6_ma_ctrl(4) then
			for i in 0 to 3 loop
				result(32*i + 1 to 32*i + 8) := std_logic_vector(signed(result(32*i + 1 to 32*i + 8)) + (to_signed(155, 8) - signed(s6_scale)));
			end loop;
		end if;
		
		-- unconditional conversion, result only used if the conversion is valid anyways
		for i in 0 to 3 loop
			case s6_ma_ctrl(1) is
				when '0' =>	s6_int_result(32*i to 32*i + 31) <= std_logic_vector(to_unsigned(to_float(result(32*i to 32*i + 31)), 32));
				when '1' =>	s6_int_result(32*i to 32*i + 31) <= std_logic_vector(to_signed(to_float(result(32*i to 32*i + 31)), 32));
				when others => s6_int_result(32*i to 32*i + 31) <= (others => '0');	-- illegal value on sign signal
			end case;
		end loop;
	end process pipe_ma_s6_cfti;
	
	-- pipeline register between s6 and s7
	pipe_ma_s6_s7_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				s7_int_result <= (others => '0');						 
				i_wb_en(7) <= '0';
			else
				s7_int_result <= s6_int_result;						 
				i_wb_en(7) <= i_wb_en(6);
			end if;
		end if;
	end process pipe_ma_s6_s7_reg;
	
	-- output integer results
	int_result_data <= s7_int_result;
	int_wb_en <= i_wb_en;
	
	-- output debug signals
	--s1_multiplicand_dbg <= s1_multiplicand;
--	s1_multiplier_dbg <= s1_multiplier;
--	s1_addend_dbg <= s1_addend;
--	s2_multiplicand_dbg <= s2_multiplicand_out;
--	s2_multiplier_dbg <= s2_multiplier_out;
--	s2_addend_dbg <= s2_addend_out;
--	s3_product_dbg <= s3_product;
--	s3_addend_dbg <= s3_addend;
--	s4_sum_dbg <= s4_sum;
--	s5_result_dbg <= s5_result;
--	s6_int_result_dbg <= s6_int_result;
	
	
end behavioral;