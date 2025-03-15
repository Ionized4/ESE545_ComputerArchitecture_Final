library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipe_branch is
	port(
	clk				: in std_logic;
	clr				: in std_logic;
	
	shared_ctrl		: in std_logic_vector(0 to 7);
	-- shared_ctrl[1:2] = op
		-- 00 - unconditional
		-- 01 - unused/reserved
		-- 10 brnz
		-- 11 brz
	-- shared_ctrl[6] = mode
		-- 0 relative
		-- 1 absolute
	pipe_en_in	: in std_logic;
	br_pos		: in std_logic;
	-- br_pos keeps track of the whether the branch was the first or second instruction in the pair of instructions that were issued.
	-- br_pos = '0' => branch instruction was i0
	-- br_pos = '1' => branch instruction was i1
	prediction	: in std_logic;
	
	pc				: in std_logic_vector(0 to 31);
	ra				: in std_logic_vector(0 to 127);
	i16				: in std_logic_vector(0 to 15); 
	
	address			: out std_logic_vector(0 to 31);
	pc_out			: out std_logic_vector(0 to 31);
	br_pos_out		: out std_logic;
	branch_taken	: out std_logic;
	mispredict		: out std_logic
	);
end pipe_branch;

architecture behavioral of pipe_branch is

signal s1_pc	: std_logic_vector(0 to 31);	
signal s1_ra	: std_logic_vector(0 to 127);
signal s1_i16	: std_logic_vector(0 to 15);

signal s1_shared_ctrl	: std_logic_vector(0 to 7);	
signal s1_pipe_en		: std_logic;
signal s1_br_pos		: std_logic;
signal s1_prediction	: std_logic;

signal s1_branch_taken	: std_logic;
signal s1_jump_address	: std_logic_vector(0 to 31);
signal s1_next_pc		: std_logic_vector(0 to 31);

begin
	br_input_s1_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				s1_pc <= (others => '0');
				s1_ra <= (others => '0');
				s1_i16 <= (others => '0');
				
				s1_shared_ctrl <= (others => '0');
				s1_pipe_en <= '0';
				s1_br_pos <= '0';
				s1_prediction <= '0';
			else
				s1_pc <= pc;
				s1_ra <= ra;
				s1_i16 <= i16;
				
				s1_shared_ctrl <= shared_ctrl;
				s1_pipe_en <= pipe_en_in;
				s1_br_pos <= br_pos;
				s1_prediction <= prediction;
			end if;
		end if;
	end process;
	
	pipe_branch_proc: process(all)
	begin
		-- compute branch address
		if s1_shared_ctrl(6) = '0' then		-- relative mode
			s1_jump_address <= std_logic_vector(signed(s1_pc) + resize(signed(s1_i16 & "00"), 32));
		else
			s1_jump_address <= std_logic_vector(resize(signed(s1_i16 & "00"), 32));	-- I don't like that this is signed but I didn't choose the way it is described in the RTL
		end if;
		
		-- determine whether branch taken
		if s1_shared_ctrl(1 to 2) = "00" then			-- unconditional branch
			s1_branch_taken <= '1' and s1_pipe_en;
		elsif s1_shared_ctrl(1 to 2) = "01" then		-- unused
			s1_branch_taken <= '0' and s1_pipe_en;
		elsif s1_shared_ctrl(1 to 2) = "10" then		-- brnz
			if unsigned(s1_ra(0 to 31)) = 0 then
				s1_branch_taken <= '0' and s1_pipe_en;
			else
				s1_branch_taken <= '1' and s1_pipe_en;  
			end if;
		else						-- brz
			if unsigned(s1_ra(0 to 31)) = 0 then
				s1_branch_taken <= '1' and s1_pipe_en;
			else
				s1_branch_taken <= '0' and s1_pipe_en;
			end if;
		end if;
		
		-- if branch was i0, next pc is pc+8
		-- if branch was i1, next pc is pc+4
		case s1_br_pos is
			when '0' =>	s1_next_pc <= std_logic_vector(signed(s1_pc) + to_signed(8, 32));
			when '1' =>	s1_next_pc <= std_logic_vector(signed(s1_pc) + to_signed(4, 32));
			when others =>	s1_next_pc <= (others => '0');
		end case;
		
		-- if branch is taken, the target is jump_address
		-- if branch is not taken, the target is next_pc
		case s1_branch_taken is
			when '1' =>	address <= s1_jump_address;
			when '0' =>	address <= s1_next_pc;
			when others =>	address <= (others => '0');
		end case;
		
		branch_taken <= s1_branch_taken;
		mispredict <= s1_branch_taken xor s1_prediction;
		br_pos_out <= s1_br_pos;		
		pc_out <= s1_pc;
		
	end process pipe_branch_proc;	
end behavioral;