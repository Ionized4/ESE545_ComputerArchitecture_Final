package instruction_type_enum is
	type instruction_type is (itype_rr, itype_rrr, itype_ri7, itype_ri8, itype_ri10, itype_ri16, itype_nop, itype_stop, itype_invalid);
end instruction_type_enum;

package body instruction_type_enum is		
end instruction_type_enum;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library cell_spu;
use cell_spu.instruction_type_enum.all;

entity instruction_decoder is
	port(
	instruction		: in std_logic_vector(0 to 31);
	
	ra_index		: out std_logic_vector(0 to 6);
	rb_index		: out std_logic_vector(0 to 6);
	rc_index		: out std_logic_vector(0 to 6);
	rt_index		: out std_logic_vector(0 to 6);		-- rt destination
	i16				: out std_logic_vector(0 to 15);	-- 16 bit immediate field (smaller immediates just occupy bits 0 to n)		  
	
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
	shared_ctrl		: out std_logic_vector(0 to 7);	   
	ma_ctrl			: out std_logic_vector(0 to 9);
	sf1_ctrl		: out std_logic_vector(0 to 10);
	sf2_pipe_en		: out std_logic;
	byte_pipe_en	: out std_logic;
	ls_pipe_en		: out std_logic;
	perm_pipe_en	: out std_logic;
	br_pipe_en		: out std_logic;
	registers_used	: out std_logic_vector(1 to 3);
	
	even_nop		: out std_logic;
	odd_nop			: out std_logic;
	stop			: out std_logic
	);
end instruction_decoder;			

architecture behavioral of instruction_decoder is

-- shared control signals
signal source	: std_logic;
signal op		: std_logic_vector(0 to 2);
signal op_size	: std_logic_vector(0 to 1);
signal mode		: std_logic_vector(0 to 1);

-- even pipe		
-- multiply accumulate
signal ma_pipe_en		: std_logic;
signal ma_sign			: std_logic;	-- 0 - unsigned, 1 - signed
signal ma_citf			: std_logic;	-- convert int to float
signal ma_cfti			: std_logic;	-- convert float to int
signal ma_scale_conv	: std_logic;	-- enables scaling of the conversion. not sure if this is the way
signal ma_mult			: std_logic;	-- enable multiplier
signal ma_add_en		: std_logic;	-- enable adder
signal ma_add_mode		: std_logic;	-- 0 - add, 1 - subtract
signal ma_negate		: std_logic;	-- negate result 
signal ma_shift_right	: std_logic;

-- simple fixed 1
signal sf1_pipe_en		: std_logic;
signal sf1_imm_size		: std_logic;
signal sf1_imm_mask		: std_logic_vector(0 to 1);
signal sf1_logical_op	: std_logic_vector(0 to 1);
signal sf1_complement_logical_result	: std_logic;
signal sf1_subtract_ra					: std_logic;	-- subtract ra
signal sf1_complement_rb				: std_logic;	-- complement rb
signal sf1_compare_mode					: std_logic_vector(0 to 1);	-- controls comparisons

begin
	instr_decoder_proc: process (all)
	variable instr_type		: instruction_type;
	begin 
		ra_index <= (others => '0');
		rb_index <= (others => '0');
		rc_index <= (others => '0');
		rt_index <= (others => '0');
		i16 <= (others => '0');
		
		source <= '0';
		op <= (others => '0');
		op_size <= (others => '0');
		mode <= "00";
		
		-- even pipe		
		-- multiply accumulate
		ma_pipe_en <= '0';
		ma_sign <= '0';
		ma_citf <= '0';
		ma_cfti <= '0';
		ma_scale_conv <= '0';
		ma_mult <= '0';
		ma_add_en <= '0';
		ma_add_mode <= '0';
		ma_negate <= '0';
		ma_shift_right <= '0';
		
		-- simple fixed 1
		sf1_pipe_en <= '0';
		sf1_imm_size <= '0';
		sf1_imm_mask <= (others => '0');
		sf1_logical_op <= (others => '0');
		sf1_complement_logical_result <= '0';
		sf1_subtract_ra <= '0';
		sf1_complement_rb <= '0';
		sf1_compare_mode <= (others => '0');
		
		-- simple fixed 2
		sf2_pipe_en <= '0';
		
		-- byte	
		byte_pipe_en <= '0';
		
		--odd pipe	 
		-- load store
		ls_pipe_en <= '0';
		
		-- permute
		perm_pipe_en <= '0';
		
		-- branch 
		br_pipe_en <= '0';
		
		even_nop <= '0';
		odd_nop <= '0';
		stop <= '0';  
		
		if instruction(0 to 10) = "00000000000" then	-- stop
			stop <= '1';
			instr_type := itype_stop;
			registers_used <= "000";
		elsif instruction(0 to 10) = "00000000001" then	-- lnop
			odd_nop <= '1';
			instr_type := itype_nop;
			registers_used <= "000";
		elsif instruction(0 to 10) = "01000000001" then	-- nop
			even_nop <= '1';
			instr_type := itype_nop;
			registers_used <= "000";
		elsif instruction(0 to 6) = "0111100" and instruction(8 to 10) = "100" then	-- multiply (signed or unsigned) 
			source <= '0';
			ma_pipe_en <= '1';
			ma_sign <= not instruction(7);
			ma_citf <= '1';
			ma_cfti <= '1';
			ma_scale_conv <= '0';
			ma_mult <= '1';
			ma_add_en <= '0';	
			ma_negate <= '0';
			ma_shift_right <= '0';
			instr_type := itype_rr;
			registers_used <= "110";
		elsif instruction(0 to 6) = "0111010" then	-- multiply immediate (signed or unsigned)
			source <= '1';
			ma_pipe_en <= '1';
			ma_sign <= not instruction(7);	-- ma_sign: 0 - unsigned, 1 - signed 								 
			ma_citf <= '1';
			ma_cfti <= '1';
			ma_scale_conv <= '0';
			ma_mult <= '1';
			ma_add_en <= '0';	 
			ma_negate <= '0';
			ma_shift_right <= '0';
			instr_type := itype_ri10;
			registers_used <= "100";
		elsif instruction(0 to 3) = "1100" then			-- multiply and add
			source <= '0';
			ma_pipe_en <= '1';
			ma_sign <= '1';
			ma_citf <= '1';
			ma_cfti <= '1';
			ma_scale_conv <= '0';
			ma_mult <= '1';
			ma_add_en <= '1';
			ma_add_mode <= '0';
			ma_negate <= '0';
			ma_shift_right <= '0';
			instr_type := itype_rrr;
			registers_used <= "111";
		elsif instruction(0 to 10) = "01111000111" then	-- multiply and shift right
			source <= '0';
			ma_pipe_en <= '1';
			ma_sign <= '1';
			ma_citf <= '1';
			ma_cfti <= '1';
			ma_scale_conv <= '0';
			ma_mult <= '1';
			ma_add_en <= '0';	 
			ma_negate <= '0';
			ma_shift_right <= '1';
			instr_type := itype_rr;
			registers_used <= "110";
		elsif instruction(0 to 9) = "0101100010" then	-- floating add or subtract
			source <= '0';
			ma_pipe_en <= '1';
			ma_sign <= '1';
			ma_citf <= '0';
			ma_cfti <= '0';
			ma_scale_conv <= '0';
			ma_mult <= '0';
			ma_add_en <= '1';
			ma_add_mode <= instruction(10);	 
			ma_negate <= '0';
			ma_shift_right <= '0';
			instr_type := itype_rr;
			registers_used <= "110";
		elsif instruction(0 to 10) = "01011000110" then	-- floating multiply
			source <= '0';
			ma_pipe_en <= '1';
			ma_sign <= '1';
			ma_citf <= '0';
			ma_cfti <= '0';
			ma_scale_conv <= '0';
			ma_mult <= '1';
			ma_add_en <= '0';	
			ma_negate <= '0';
			ma_shift_right <= '0';
			instr_type := itype_rr;
			registers_used <= "110";
		elsif instruction(0 to 2) = "111" then			-- floating multiply add or subtract   
			source <= '0';
			ma_pipe_en <= '1';
			ma_sign <= '1';
			ma_citf <= '0';
			ma_cfti <= '0';
			ma_scale_conv <= '0';
			ma_mult <= '1';
			ma_add_en <= '1';	
			ma_add_mode <= instruction(3);
			ma_negate <= '0';
			ma_shift_right <= '0';
			instr_type := itype_rrr;
			registers_used <= "111";
		elsif instruction(0 to 3) = "1101" then			-- floating negative multiply and subtract	 
			source <= '0';
			ma_pipe_en <= '1';
			ma_sign <= '1';
			ma_citf <= '0';
			ma_cfti <= '0';
			ma_scale_conv <= '0';
			ma_mult <= '1';
			ma_add_en <= '1';	
			ma_add_mode <= '1';
			ma_negate <= '1';
			ma_shift_right <= '0';
			instr_type := itype_rrr;
			registers_used <= "111";
		elsif instruction(0 to 7) = "01110110" then		-- float/int conversion
			source <= 'X';	-- scale immediate is handled a bit differently
			ma_pipe_en <= '1';
			ma_sign <= not instruction(9);
			ma_citf <= instruction(8);
			ma_cfti <= not instruction(8);
			ma_scale_conv <= '1';
			ma_mult <= '0';
			ma_add_en <= '0';
			ma_negate <= '0';
			ma_shift_right <= '0';
			instr_type := itype_ri8;
			registers_used <= "100";
		elsif instruction(0 to 7) = "01000001" then	-- immediate load halfword (normal and upper)
			op <= "100";			-- opcode for load
			op_size <= "01";		-- operands are halfwords
			source <= '1';
			sf1_pipe_en <= '1';
			sf1_imm_size <= '1';
			sf1_imm_mask <= (not instruction(8)) & '0';	-- I hope this is right
			instr_type := itype_ri16;
			registers_used <= "000";		   
		elsif instruction(0 to 8) = "010000001" then	-- immediate load word
			op <= "100";			-- opcode for load
			op_size <= "10";		-- operands are words
			source <= '1';
			sf1_pipe_en <= '1';
			sf1_imm_size <= '1';
			sf1_imm_mask <= "00";
			instr_type := itype_ri16;
			registers_used <= "000";
		elsif instruction(0 to 8) = "011000001" then	-- immediate or halfword lower
			op <= "001";	-- logical operation
			op_size <= "01";	-- operands are halfwords
			source <= '1';	-- immediate
			sf1_pipe_en <= '1';
			sf1_imm_size <= '1';	-- 16 bit immediate
			sf1_imm_mask <= "01";	-- mask out upper halfword of immediate
			sf1_logical_op <= "01";	-- or	   
			-- no change to complement signals, default values are 0
			instr_type := itype_ri16;
			registers_used <= "100";	-- doesn't really matter cause, in the current state, all indices will be assigned the value of rt
		elsif instruction(0 to 2) = "000" and instruction(4 to 6) = "100" and instruction(8 to 10) = "000" then	-- add or subtract halfword and word 
			sf1_pipe_en <= '1';
			op <= "000";	-- arithmetic operation
			op_size <= (not instruction(7)) & instruction(7); -- 01 if halfwords, 10 if words
			source <= '0';
			sf1_subtract_ra <= not instruction(3);
			instr_type := itype_rr;
			registers_used <= "110";
		elsif instruction(0 to 2) = "000" and instruction(4 to 6) = "110" then	-- add or subtract halfword and word immediate
			sf1_pipe_en <= '1';
			op <= "000";	-- arithmetic operation
			op_size <= (not instruction(7)) & instruction(7); -- 01 if halfwords, 10 if words
			source <= '1';
			sf1_imm_size <= '0';	-- 10 bit immediate (default already)
			sf1_subtract_ra <= not instruction(3);
			instr_type := itype_ri10;
			registers_used <= "100";
		elsif instruction(0 to 10) = "01010100101" then	-- clz
			sf1_pipe_en <= '1';
			op <= "110";	-- clz
			op_size <= "10";	-- words
			source <= '0';	-- doesnt matter
			instr_type := itype_ri7;
			registers_used <= "100";
		elsif instruction(0 to 8) = "001101101" and instruction(9 to 10) /= "11" then	-- form select mask
			op <= "101";
			source <= '0';
			case instruction(9 to 10) is
				when "10" =>	op_size <= "00";	-- byte
				when "01" =>	op_size <= "01";	-- halfword
				when "00" =>	op_size <= "10";	-- word
				when others =>	op_size <= "00";	-- illegal
			end case;						   
			instr_type := itype_ri7;
			registers_used <= "100";
		elsif instruction(0 to 5) =  "010101" and instruction(6 to 7) /= "11" and instruction(8 to 10) = "110" then	-- sign extend
			op <= "011";
			source <= '0';
			case instruction(6 to 7) is
				when "10" =>	op_size <= "00";	-- byte
				when "01" =>	op_size <= "01";	-- halfword
				when "00" =>	op_size <= "10";	-- word
				when others =>	op_size <= "00";	-- illegal
			end case;						  
			instr_type := itype_ri7;
			registers_used <= "100";	 
		elsif instruction(0 to 2) = "000" and instruction(4 to 6) = "100" and instruction(8 to 10) = "001" then	-- and, or, nand, nor
			sf1_pipe_en <= '1';
			op <= "001";		-- logical operation
			op_size <= "00";	-- I dont think this matters here
			source <= '0';	-- register source
			sf1_logical_op <= '0' & not instruction(3);	-- and if instr(3) = '1', or if instr(3) = '0'
			sf1_complement_logical_result <= instruction(7);	-- instr(7) = '1' if instr is nand or nor, '0' if and or or
			instr_type := itype_rr;
			registers_used <= "110";
		elsif instruction(0 to 6) = "0101100" and instruction(8 to 10) = "001" then	-- and or or with complement
			sf1_pipe_en <= '1';
			source <= '0';
			op <= "001";
			op_size <= "00";
			sf1_logical_op <= '0' & instruction(7);
			sf1_complement_logical_result <= '1';
			-- not sure if anything more is needed
			instr_type := itype_rr;
			registers_used <= "110";
		elsif instruction(0 to 6) = "0100100" and instruction(8 to 10) = "001" then	-- xor or xnor
			sf1_pipe_en <= '1';
			source <= '0';
			op <= "001";	-- logical
			op_size <= "00";
			sf1_logical_op <= "10";	-- xor
			sf1_complement_rb <= instruction(7);
			instr_type := itype_rr;
			registers_used <= "110";
		elsif instruction(0 to 10) = "00111110000" then	-- or across
			sf1_pipe_en <= '1';
			source <= '0';
			op <= "001";
			op_size <= "00";
			sf1_logical_op <= "11";
			instr_type := itype_ri7;
			registers_used <= "100"; 																											   
		elsif instruction(0 to 7) = "00010110" or instruction(0 to 7) = "00010101" or instruction(0 to 7) = "00010100" or instruction(0 to 7) = "00000110"
			or instruction(0 to 7) = "00000101" or instruction(0 to 7) = "00000100" or instruction(0 to 7) = "01000110" or instruction(0 to 7) = "01000101"
			or instruction(0 to 7) = "01000100" then
			sf1_pipe_en <= '1';
			op <= "001";
			source <= '1';
			case instruction(6 to 7) is
				when "10" =>	op_size <= "00";	-- byte
				when "01" =>	op_size <= "01";	-- halfword
				when "00" =>	op_size <= "10";	-- word
				when others =>	op_size <= "00";	-- illegal
			end case; 
			sf1_logical_op <= instruction(1) & (not instruction(3));	-- "11" will make this do or across and fail
			instr_type := itype_ri10;
			registers_used <= "100";
		elsif instruction(0 to 5) = "011110" and instruction(6 to 7) /= "11" and instruction(8 to 10) = "000" then	-- compare equal
			sf1_pipe_en <= '1';
			source <= '0';				 
			op <= "010";	-- compare
			case instruction(6 to 7) is
				when "10" =>	op_size <= "00";	-- byte
				when "01" =>	op_size <= "01";	-- halfword
				when "00" =>	op_size <= "10";	-- word
				when others =>	op_size <= "00";	-- illegal
			end case;
			sf1_compare_mode <= "00";
			instr_type := itype_rr;
			registers_used <= "110";
		elsif instruction(0 to 5) = "011111" and instruction(6 to 7) /= "11" then	-- compare equal immediate
			sf1_pipe_en <= '1';
			source <= '1';
			sf1_imm_size <= '0';	-- i10
			op <= "010";	-- compare
			case instruction(6 to 7) is
				when "10" =>	op_size <= "00";	-- byte
				when "01" =>	op_size <= "01";	-- halfword
				when "00" =>	op_size <= "10";	-- word
				when others =>	op_size <= "00";	-- illegal
			end case;
			sf1_compare_mode <= "00";
			instr_type := itype_ri10;
			registers_used <= "100";				   
		elsif instruction(0 to 2) = "010" and instruction(4 to 5) = "10" and instruction(6 to 7) /= "11" and instruction(8 to 10) = "000" then	--compare greater than
			sf1_pipe_en <= '1';
			source <= '0';				 
			op <= "010";	-- compare
			case instruction(6 to 7) is
				when "10" =>	op_size <= "00";	-- byte
				when "01" =>	op_size <= "01";	-- halfword
				when "00" =>	op_size <= "10";	-- word
				when others =>	op_size <= "00";	-- illegal
			end case;						 
			sf1_compare_mode <= (not instruction(3)) & '1';
			instr_type := itype_rr;
			registers_used <= "110";	
		elsif instruction(0 to 2) = "010" and instruction(4 to 5) = "11" and instruction(6 to 7) /= "11" then	--compare greater than immediate
			sf1_pipe_en <= '1';
			source <= '1';
			sf1_imm_size <= '0'; -- 10 bit
			op <= "010";	-- compare
			case instruction(6 to 7) is
				when "10" =>	op_size <= "00";	-- byte
				when "01" =>	op_size <= "01";	-- halfword
				when "00" =>	op_size <= "10";	-- word
				when others =>	op_size <= "00";	-- illegal
			end case;						 
			sf1_compare_mode <= (not instruction(3)) & '1'; 
			instr_type := itype_ri10;
			registers_used <= "100"; 
		--elsif instruction(0 to 4) = "00001" and instruction(6 to 7) = "11" and instruction(9) = '0' then	-- shift and rotate not quadword
--			sf2_pipe_en <= '1';
--			op <= (0 => not instruction(10), others => '0');
--			source <= instruction(5);
--			op_size(0) <= not instruction(8);	-- 0 if halfword, 1 if word
--			case instruction(5) is
--				when '1' =>	instr_type := itype_ri7;
--				when '0' => instr_type := itype_rr;
--				when others =>	instr_type := itype_invalid;
--			end case;
--			registers_used <= "1" & not instruction(5) & "0";
		elsif instruction(0 to 9) = "00001111011" then	-- shift and rotate not quadword
			sf2_pipe_en <= '1';
			op <= "000";
			source <= '1';
			op_size(0) <= '1';	-- 0 if halfword, 1 if word
			instr_type := itype_ri7;
			registers_used <= "100";
		elsif instruction(0 to 10) = "01010110100" then	-- count ones in bytes
			byte_pipe_en <= '1';																																																		
			op <= "000";
			instr_type := itype_ri7;
			registers_used <= "100";
		elsif instruction(0 to 10) = "00011010011" then	-- average bytes
			byte_pipe_en <= '1';
			op <= "010";
			instr_type := itype_rr;
			registers_used <= "110";
		elsif instruction(0 to 10) = "00001010011" then	-- absolute difference in bytes
			byte_pipe_en <= '1';
			op <= "100";
			instr_type := itype_rr;
			registers_used <= "110";
		elsif instruction(0 to 10) = "01001010011" then	-- sum bytes into halfwords
			byte_pipe_en <= '1';
			op <= "110";
			instr_type := itype_rr;
			registers_used <= "110";	  
		elsif instruction(0 to 2) = "001" and instruction(4 to 7) = "0100" then	-- load or store d form
			ls_pipe_en <= '1';
			op <= (0 => not instruction(3), others => '0');
			mode <= "00";	-- d form
			instr_type := itype_ri10;
			registers_used <= "10" & not instruction(3);
		elsif instruction(0 to 2) = "001" and instruction(4 to 10) = "1000100" then	-- load or store x form
			ls_pipe_en <= '1';
			op <= (0 => not instruction(3), others => '0');
			mode <= "10";	-- x form
			instr_type := itype_rr;
			registers_used <= "110";
		elsif instruction(0 to 8) = "001100001" then	-- load a form
			ls_pipe_en <= '1';
			op <= "000";
			mode <= "01";	-- a form
			instr_type := itype_ri16;
			registers_used <= "100";
		elsif instruction(0 to 8) = "001000001" then	-- store a form
			ls_pipe_en <= '1';
			op <= "100";
			mode <= "01";	-- a form
			instr_type := itype_ri16;
			registers_used <= "100";
		elsif instruction(0 to 3) = "1011" then			-- shuffle bytes
			perm_pipe_en <= '1';
			op <= "000";
			source <= '0';
			op_size <= "00";
			instr_type := itype_rrr;
		-- shlqbi	00111011011
		-- shlqbii	00111111011
		-- shlqby	00111011111
		-- shlqbyi	00111111111
		-- rotqby	00111011100
		-- rotqbyi	00111111100
		-- rotqbi	00111011000
		-- rotqbii	00111111000
			registers_used <= "111";
		elsif instruction(0 to 4) = "00111" and instruction(6 to 7) = "11" and (instruction(9 to 10) = "00" or instruction(9 to 10) = "11") then	-- shift or rotate quadword
			perm_pipe_en <= '1';
			op(0 to 1) <= '1' & not instruction(10);	-- instr(10) = '1' if shift, instr(10) = '0'
			source <= instruction(5);	-- instr(5) = '1' if immediate, '0' if register source
			op_size <= (0 | 1 => not instruction(8), others => '0');	-- op-size[0:1] = "11" if bits, "00" if bytes
			case instruction(5) is
				when '1' =>	instr_type := itype_ri7;
				when '0' => instr_type := itype_rr;
				when others =>	instr_type := itype_invalid;
			end case;
			registers_used <= "1" & not instruction(5) & "0";
		elsif instruction(0 to 8) = "001101100" and instruction(9 to 10) /= "11" then	-- gather bits from bytes [9:10] = 10, halfwords [9:10] = 01, words [9:10] = 00
			perm_pipe_en <= '1';
			op(0 to 1) <= "01";
			case instruction(9 to 10) is
				when "10" =>	op_size <= "00";	-- bytes
				when "01" =>	op_size <= "01";	-- halfwords
				when "00" =>	op_size <= "10";	-- words
				when others =>	op_size <= "00";	-- illegal value on [9:10]
			end case;
			instr_type := itype_ri7;
			registers_used <= "100";
		elsif instruction(0 to 5) = "001100" and instruction(7 to 8) = "00" then	-- branch relative and absolute
			br_pipe_en <= '1';
			op(0 to 1) <= "00";	-- unconditional branch
			mode(0) <= not instruction(6);	-- instr(6) = '1' if relative, '0' if absolute
			instr_type := itype_ri16;
			registers_used <= "000";
		elsif instruction(0 to 6) = "0010000" and instruction(8) = '0' then	-- brnz and brz
			br_pipe_en <= '1';
			op(0 to 1) <= '1' & not instruction(7);	-- instr(7) = '1' if brnz, instr(7) = '0' if brz
			mode(0) <= '0';	-- always relative here
			instr_type := itype_ri16;
			registers_used <= "100";
		else
			instr_type := itype_invalid;
		end if;
		
		case instr_type is
			-- there are a few instances where I put the rt field in the seemingly unused input register indices
			-- if I do this for ALL unused registers, WaW hazard detection might become easier
			when itype_rrr =>
			ra_index <= instruction(18 to 24);
			rb_index <= instruction(11 to 17);
			rc_index <= instruction(25 to 31);
			rt_index <= instruction(4 to 10);
			i16 <= (others => '0');
			when itype_rr =>
			ra_index <= instruction(18 to 24);
			rb_index <= instruction(11 to 17);
			rc_index <= instruction(25 to 31);	-- gets rt field cause store quadword uses rt to get the value to store to the local store unit
			rt_index <= instruction(25 to 31);
			i16 <= (others => '0');
			when itype_ri7 =>
			ra_index <= instruction(18 to 24);
			rb_index <= (others => '0');
			rc_index <= (others => '0');
			rt_index <= instruction(25 to 31);
			i16 <= (0 to 6 => instruction(11 to 17), others => '0');
			when itype_ri8 =>
			ra_index <= instruction(18 to 24);
			rb_index <= (others => '0');
			rc_index <= (others => '0');
			rt_index <= instruction(25 to 31);
			i16 <= (0 to 7 => instruction(10 to 17), others => '0');
			when itype_ri10 =>
			ra_index <= instruction(18 to 24);
			rb_index <= (others => '0');
			rc_index <= (others => '0');
			rt_index <= instruction(25 to 31);
			i16 <= (0 to 9 => instruction(8 to 17), others => '0');
			when itype_ri16 =>				
			ra_index <= instruction(25 to 31);	-- immediate or halfword lower reads the value of rt, changes it, and stores it back
			rb_index <= instruction(25 to 31);	-- by sending this value to all indices, no random stalls occur because of having index 0 on unused register fields
			rc_index <= instruction(25 to 31);
			rt_index <= instruction(25 to 31);
			i16 <= instruction(9 to 24);
			when others =>
			ra_index <= (others => '0');
			rb_index <= (others => '0');
			rc_index <= (others => '0');
			rt_index <= (others => '0');
		end case;
		
		-- assign individual signals to control bus
		shared_ctrl(0) <= source;
		shared_ctrl(1 to 3) <= op;
		shared_ctrl(4 to 5) <= op_size;
		shared_ctrl(6 to 7) <= mode;
													
		ma_ctrl(0) <= ma_pipe_en;
		ma_ctrl(1) <= ma_sign;
		ma_ctrl(2) <= ma_citf;
		ma_ctrl(3) <= ma_cfti;
		ma_ctrl(4) <= ma_scale_conv;
		ma_ctrl(5) <= ma_mult;
		ma_ctrl(6) <= ma_add_en;
		ma_ctrl(7) <= ma_add_mode;
		ma_ctrl(8) <= ma_negate;
		ma_ctrl(9) <= ma_shift_right;
		
		sf1_ctrl(0) <= sf1_pipe_en;
		sf1_ctrl(1 to 2) <= sf1_logical_op;
		sf1_ctrl(3) <= sf1_subtract_ra;
		sf1_ctrl(4) <= sf1_complement_rb;
		sf1_ctrl(5) <= sf1_complement_logical_result;
		sf1_ctrl(6 to 7) <= sf1_compare_mode;
		sf1_ctrl(8) <= sf1_imm_size;
		sf1_ctrl(9 to 10) <= sf1_imm_mask;
	end process instr_decoder_proc;
end behavioral;

--architecture behavioral2 of instruction_decoder is
---- shared control signals
--signal source	: std_logic;
--signal op		: std_logic_vector(0 to 2);
--signal op_size	: std_logic_vector(0 to 1);
--signal mode		: std_logic_vector(0 to 1);
--
---- even pipe		
---- multiply accumulate
--signal ma_pipe_en		: std_logic;
--signal ma_sign			: std_logic;	-- 0 - unsigned, 1 - signed
--signal ma_citf			: std_logic;	-- convert int to float
--signal ma_cfti			: std_logic;	-- convert float to int
--signal ma_scale_conv	: std_logic;	-- enables scaling of the conversion. not sure if this is the way
--signal ma_mult			: std_logic;	-- enable multiplier
--signal ma_add_en		: std_logic;	-- enable adder
--signal ma_add_mode		: std_logic;	-- 0 - add, 1 - subtract
--signal ma_negate		: std_logic;	-- negate result 
--signal ma_shift_right	: std_logic;
--
---- simple fixed 1
--signal sf1_pipe_en		: std_logic;
--signal sf1_imm_size		: std_logic;
--signal sf1_imm_mask		: std_logic_vector(0 to 1);
--signal sf1_logical_op	: std_logic_vector(0 to 1);
--signal sf1_complement_logical_result	: std_logic;
--signal sf1_subtract_ra					: std_logic;	-- subtract ra
--signal sf1_complement_rb				: std_logic;	-- complement rb
--signal sf1_compare_mode					: std_logic_vector(0 to 1);	-- controls comparisons
--begin
--	instr_decoder_proc: process (all)
--	variable instr_type		: instruction_type;
--	begin 
--		ra_index <= (others => '0');
--		rb_index <= (others => '0');
--		rc_index <= (others => '0');
--		rt_index <= (others => '0');
--		i16 <= (others => '0');
--		
--		source <= '0';
--		op <= (others => '0');
--		op_size <= (others => '0');
--		mode <= "00";
--		
--		-- even pipe		
--		-- multiply accumulate
--		ma_pipe_en <= '0';
--		ma_sign <= '0';
--		ma_citf <= '0';
--		ma_cfti <= '0';
--		ma_scale_conv <= '0';
--		ma_mult <= '0';
--		ma_add_en <= '0';
--		ma_add_mode <= '0';
--		ma_negate <= '0';
--		ma_shift_right <= '0';
--		
--		-- simple fixed 1
--		sf1_pipe_en <= '0';
--		sf1_imm_size <= '0';
--		sf1_imm_mask <= (others => '0');
--		sf1_logical_op <= (others => '0');
--		sf1_complement_logical_result <= '0';
--		sf1_subtract_ra <= '0';
--		sf1_complement_rb <= '0';
--		sf1_compare_mode <= (others => '0');
--		
--		-- simple fixed 2
--		sf2_pipe_en <= '0';
--		
--		-- byte	
--		byte_pipe_en <= '0';
--		
--		--odd pipe	 
--		-- load store
--		ls_pipe_en <= '0';
--		
--		-- permute
--		perm_pipe_en <= '0';
--		
--		-- branch 
--		br_pipe_en <= '0';
--		
--		even_nop <= '0';
--		odd_nop <= '0';
--		stop <= '0';
--		
--		if instruction(0 to 10) = "00000000000" then	-- stop
--			stop <= '1';
--			ra_index <= (others => '0');
--			rb_index <= (others => '0');
--			rc_index <= (others => '0');
--			rt_index <= (others => '0');
--			registers_used <= "000";
--		elsif instruction(0 to 10) = "00000000001" then	-- lnop
--			odd_nop <= '1';
--			ra_index <= (others => '0');
--			rb_index <= (others => '0');
--			rc_index <= (others => '0');
--			rt_index <= (others => '0');
--			registers_used <= "000";
--		elsif instruction(0 to 10) = "01000000001" then	-- nop
--			even_nop <= '1';
--			ra_index <= (others => '0');
--			rb_index <= (others => '0');
--			rc_index <= (others => '0');
--			rt_index <= (others => '0');
--			registers_used <= "000";
--		elsif instruction(0 to ) = "01111000100" then -- multiply
--			ra_index <= ;
--			rb_index <= ;
--			rc_index <= ;
--			rt_index <= ;
--			source <= '0';
--			ma_pipe_en <= '1';
--			ma_sign <= '1';
--			ma_citf <= '1';
--			ma_cfti <= '1';
--			ma_scale_conv <= '0';
--			ma_mult <= '1';
--			ma_add_en <= '0';	
--			ma_negate <= '0';
--			ma_shift_right <= '0';
--			registers_used = "110";
--	end process instr_decoder_proc;
--end behavioral2;