library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library cell_spu;
use cell_spu.all;

entity pipe_ls is
	port(
	clk		: in std_logic;
	clr		: in std_logic;
	
	ra			: in std_logic_vector(0 to 127);
	rb			: in std_logic_vector(0 to 127);
	rc			: in std_logic_vector(0 to 127);	-- for store operations, rt is the location from which the result is fetched. Decode logic performs this mapping of register indexes
	i16			: in std_logic_vector(0 to 15);
													
	shared_ctrl	: in std_logic_vector(0 to 7);
	-- shared_ctrl(1) = op
		-- 0 = load, 1 = store
	-- shared_ctrl[6:7] = mode
		-- 00 = relative
		-- 01 = absolute
		-- 10 = xform
		-- 11 = reserved/unused
	pipe_en_in	: in std_logic;
	
	wb_en_out	: out std_logic_vector(1 to 6);
	result_data	: out std_logic_vector(0 to 127)
	);
end pipe_ls;

architecture behavioral of pipe_ls is

signal s1_ra, s1_rb, s1_rc	: std_logic_vector(0 to 127);
signal s1_i16				: std_logic_vector(0 to 15); 

signal s1_op1, s1_op2	: std_logic_vector(0 to 31);
signal s1_data			: std_logic_vector(0 to 127);

signal s2_op1, s2_op2	: std_logic_vector(0 to 31);
signal s2_data			: std_logic_vector(0 to 127);

signal s2_address	: std_logic_vector(0 to 31);	

signal s3_data		: std_logic_vector(0 to 127);
signal s3_address	: std_logic_vector(0 to 31);

-- Load/Store signals
signal ls_write_address	: std_logic_vector(0 to 31);
signal ls_read_address	: std_logic_vector(0 to 31);
signal ls_write_en		: std_logic;
signal ls_write_data	: std_logic_vector(0 to 127);
signal ls_result		: std_logic_vector(0 to 127);

signal s4_result	: std_logic_vector(0 to 127);
signal s5_result	: std_logic_vector(0 to 127);
signal s6_result	: std_logic_vector(0 to 127);

signal s1_shared_ctrl	: std_logic_vector(0 to 7);
signal s2_shared_ctrl	: std_logic_vector(0 to 7);
signal s3_shared_ctrl	: std_logic_vector(0 to 7);
signal s4_shared_ctrl	: std_logic_vector(0 to 7);
signal s5_shared_ctrl	: std_logic_vector(0 to 7);
signal s6_shared_ctrl	: std_logic_vector(0 to 7);

signal pipe_en	: std_logic_vector(1 to 6);

begin
	-- Load/Store Entity
	ls : entity load_store port map(
		clk => clk, clr => clr, read_address => ls_read_address, write_address => ls_write_address, write_data => ls_write_data, write_en => ls_write_en, read_data => ls_result
	);
	
	-- input to stage 1 pipeline register
	ls_input_s1_reg: process (clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				s1_ra <= (others => '0');
				s1_rb <= (others => '0');
				s1_rc <= (others => '0');
				s1_i16 <= (others => '0');
				
				s1_shared_ctrl <= (others => '0');
				pipe_en(1) <= '0';
			else
				s1_ra <= ra;
				s1_rb <= rb;
				s1_rc <= rc;
				s1_i16 <= i16;
				
				s1_shared_ctrl <= shared_ctrl;
				pipe_en(1) <= pipe_en_in;
			end if;
		end if;
	end process ls_input_s1_reg;
	
	-- stage 1: operand select
	ls_s1_operand_select: process (all)
	begin
		case s1_shared_ctrl(6 to 7) is
			when "00" =>
				s1_op1 <= s1_ra(0 to 31);
				s1_op2 <= std_logic_vector(resize(signed(s1_i16(0 to 9)), 32));
			when "01" =>
				s1_op1 <= (others => '0');
				s1_op2 <= std_logic_vector(resize(signed(s1_i16), 32));
			when "10" =>
				s1_op1 <= s1_ra(0 to 31);
				s1_op2 <= s1_rb(0 to 31);
			when others =>				 	-- invalid state on mode signal
				s1_op1 <= (others => '0');
				s1_op2 <= (others => '0');
		end case;
		s1_data <= s1_rc;
	end process ls_s1_operand_select;
	
	-- pipeline register between stage 1 and stage 2
	ls_s1_s2_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				s2_op1 <= (others => '0');
				s2_op2 <= (others => '0');
				s2_data <= (others => '0');
				
				s2_shared_ctrl <= (others => '0');
				pipe_en(2) <= '0';
			else
				s2_op1 <= s1_op1;
				s2_op2 <= s1_op2;
				s2_data <= s1_data;
				
				s2_shared_ctrl <= s1_shared_ctrl;
				pipe_en(2) <= pipe_en(1);
			end if;
		end if;
	end process ls_s1_s2_reg;
	
	-- stage 2: address computation
	ls_s2_addr_comp: process(all)
	begin
		s2_address <= std_logic_vector(signed(s2_op1) + signed(s2_op2));
	end process ls_s2_addr_comp;
	
	-- pipeline register between stage 2 and stage 3
	ls_s2_s3_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				s3_address <= (others => '0');
				s3_data <= (others => '0');
				
				s3_shared_ctrl <= (others => '0');
				pipe_en(3) <= '0';
			else
				s3_address <= s2_address;
				s3_data <= s2_data;
				
				s3_shared_ctrl <= s2_shared_ctrl;
				pipe_en(3) <= pipe_en(2);
			end if;
		end if;
	end process ls_s2_s3_reg;
	
	-- stage 3: LS access
	ls_s3_ls_access: process(all)
	begin
		ls_read_address <= s3_address;
		ls_write_address <= s3_address;
		ls_write_en <= pipe_en(3) and s3_shared_ctrl(1);	-- write_en = 1 if the pipe is active and if the operation is a store (op = 1)
		ls_write_data <= s3_data;
	end process ls_s3_ls_access;
	
	-- pipeline register between stage 3 and stage 4
	ls_s3_s4_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				s4_result <= (others => '0');
				s4_shared_ctrl <= (others => '0');
				pipe_en(4) <= '0';
			else
				s4_result <= ls_result;
				s4_shared_ctrl <= s3_shared_ctrl;
				pipe_en(4) <= pipe_en(3);
			end if;
		end if;
	end process ls_s3_s4_reg;
	
	-- the remaining stages are nop's to model the actual behavior of the Cell SPU Load/Store pipe.  In this model only three stages are truly pipelined for the purposes of demonstration
	
	-- pipeline register between stage 4 and stage 5
	ls_s4_s5_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				s5_result <= (others => '0');
				s5_shared_ctrl <= (others => '0');
				pipe_en(5) <= '0';
			else
				s5_result <= s4_result;
				s5_shared_ctrl <= s4_shared_ctrl;
				pipe_en(5) <= pipe_en(4);
			end if;
		end if;
	end process ls_s4_s5_reg;
	
	-- pipeline register between stage 5 and stage 6
	ls_s5_s6_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				s6_result <= (others => '0');
				s6_shared_ctrl <= (others => '0');
				pipe_en(6) <= '0';
			else
				s6_result <= s5_result;
				s6_shared_ctrl <= s5_shared_ctrl;
				pipe_en(6) <= pipe_en(5);
			end if;
		end if;
	end process ls_s5_s6_reg;
	
	-- output signals
	result_data <= s6_result;
	wb_en_out(1) <= pipe_en(1) and (not s1_shared_ctrl(1));
	wb_en_out(2) <= pipe_en(2) and (not s2_shared_ctrl(1));
	wb_en_out(3) <= pipe_en(3) and (not s3_shared_ctrl(1));
	wb_en_out(4) <= pipe_en(4) and (not s4_shared_ctrl(1));
	wb_en_out(5) <= pipe_en(5) and (not s5_shared_ctrl(1));
	wb_en_out(6) <= pipe_en(6) and (not s6_shared_ctrl(1));
	
end behavioral;