library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipe_permute is
	port(
	clk : in std_logic;
	clr : in std_logic;																															 

	-- shared_ctrl[0]	- source
		-- 0 = register source, 1 = immediate source
	-- shared_ctrl[1:3]	- operation
		-- 00X = shuffle  
		-- 01X = gather 
		-- 10X = shift left quadword
		-- 11X = rotate quadword				 
	-- shared_ctrl[4:5]	- operand size
	-- 00 = bytes
	-- 01 = halfwords
	-- 10 = words
	-- 11 = bits for quadword shifts and rotations
	-- shared_ctrl[6:7]	- mode for memory addressing
	shared_ctrl	: in std_logic_vector(0 to 7);
	pipe_en_in	: in std_logic;	-- only one pipe-specific control signal, being the enable
			
	-- inputs
	ra : in std_logic_vector(0 to 127);
	rb : in std_logic_vector(0 to 127);
	rc : in std_logic_vector(0 to 127);
	i7 : in std_logic_vector(0 to 6);	-- 7 bit immediate					
	
	-- hazard detection signals																					   
	wb_en		: out std_logic_vector(1 to 3);		
	
	result		: out std_logic_vector(0 to 127)
	);
end pipe_permute;

-- this "model" architecture pre-computes the result in stage 1 and passes it down through the pipe to the last stage
architecture model of pipe_permute is

signal s1_ra, s1_rb, s1_rc	: std_logic_vector(0 to 127);	-- operands for stage 1
signal s1_i7				: std_logic_vector(0 to 6);							  
signal s1_shared_ctrl		: std_logic_vector(0 to 7);		-- control signals for computation
	
signal s1_result	: std_logic_vector(0 to 127);
signal pipe_en		: std_logic_vector(1 to 3);		-- internal pipe_en signals to be shifted 

signal s2_result	: std_logic_vector(0 to 127);
signal s3_result	: std_logic_vector(0 to 127);

begin					 
	perm_input_s1_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				s1_ra <= (others => '0');
				s1_rb <= (others => '0');
				s1_rc <= (others => '0');
				s1_i7 <= (others => '0');
				
				s1_shared_ctrl <= (others => '0');
				pipe_en(1) <= '0';
			else
				s1_ra <= ra;
				s1_rb <= rb;
				s1_rc <= rc;
				s1_i7 <= i7;
				
				s1_shared_ctrl <= shared_ctrl;
				pipe_en(1) <= pipe_en_in;
			end if;
		end if;
	end process perm_input_s1_reg;
	
	perm_s1_computation_proc: process (all)
	variable a, b, c, s	: std_logic_vector(0 to 7);
	variable Rconcat	: std_logic_vector(0 to 255);
	begin
		-- compute result and assign to stage0_rt
		if s1_shared_ctrl(1 to 2) = "00" then		-- shuffle
			-- WHEN YOU GO TO WRITE THESE, MAKE SURE YOU NOTE WHICH CONTROL SIGNALS YOU'RE USING FOR EACH INSTRUCTION
			-- op_size = "00"
			-- source = '0'
			Rconcat := s1_ra & s1_rb;
			for j in 0 to 15 loop
				b := s1_rc(8*j to 8*j + 7);
				if b(0 to 1) = "10" then
					c := "00000000";
				elsif b(0 to 2) = "110" then
					c := "11111111";
				elsif b(0 to 2) = "111" then
					c := "10000000";
				else
					b := b and "00011111";
					c := Rconcat(8*(to_integer(unsigned(b))) to 8*(to_integer(unsigned(b))) + 7);
				end if;
				s1_result(8*j to 8*j + 7) <= c;
			end loop;
		elsif s1_shared_ctrl(1 to 2) = "01" then	-- gather bits
			if s1_shared_ctrl(4 to 5) = "00" then		-- from bytes
				s1_result <= (16 => s1_ra(7), 17 => s1_ra(15), 18 => s1_ra(23), 19 => s1_ra(31), 20 => s1_ra(39), 21 => s1_ra(47), 22 => s1_ra(55), 23 => s1_ra(63), 24 => s1_ra(71),
				25 => s1_ra(79), 26 => s1_ra(87), 27 => s1_ra(95), 28 => s1_ra(103), 29 => s1_ra(111), 30 => s1_ra(119), 31 => s1_ra(127), others => '0');
			elsif s1_shared_ctrl(4 to 5) = "01" then	-- from halfwords
				s1_result <= (24 => s1_ra(15), 25 => s1_ra(31), 26 => s1_ra(47), 27 => s1_ra(63), 28 => s1_ra(79), 29 => s1_ra(95), 30 => s1_ra(111), 31 => s1_ra(127), others => '0');
			elsif s1_shared_ctrl(4 to 5) = "10" then	-- from words
				s1_result <= (28 => s1_ra(31), 29 => s1_ra(63), 30 => s1_ra(95), 31 => s1_ra(127), others => '0');
			else						-- illegal op_size
				s1_result <= (others => '0');
			end if;
		elsif s1_shared_ctrl(1 to 2) = "10" then	-- shift left quadword
			if s1_shared_ctrl(4 to 5) = "00" then	-- shift by bytes
				case s1_shared_ctrl(0) is
					when '1' =>	s := ('0' & s1_i7) and "00011111";
					when '0' => s := "000" & s1_rb(27 to 31);
					when others => s := (others => '0');	-- illegal value on source signal
				end case;
				for j in 0 to 15 loop
					if (j + to_integer(unsigned(s))) < 16 then
						s1_result(8*j to 8*j + 7) <= s1_ra(8*(j + to_integer(unsigned(s))) to 8*(j + to_integer(unsigned(s))) + 7);
					else
						s1_result(8*j to 8*j + 7) <= (others => '0');
					end if;
				end loop;
			elsif s1_shared_ctrl(4 to 5) = "11" then	-- shift by bits
				case s1_shared_ctrl(0) is
					when '1' =>	s := ('0' & s1_i7) and "00000111";
					when '0' => s := "00000" & s1_rb(29 to 31);
					when others => s := (others => '0');	-- illegal value on source signal
				end case;
				for j in 0 to 127 loop
					if (j + to_integer(unsigned(s))) < 128 then
						s1_result(j) <= s1_ra(j + to_integer(unsigned(s)));
					else
						s1_result(j) <= '0';
					end if;
				end loop;
			else					-- illegal control signals
				s1_result <= (others => '0');
			end if;
		elsif s1_shared_ctrl(1 to 2) = "11" then	-- rotate quadword
			if s1_shared_ctrl(4 to 5) = "00" then	-- rotate by bytes
				case s1_shared_ctrl(0) is
					when '1' =>	s := ('0' & s1_i7) and "00001111";
					when '0' => s := "0000" & s1_rb(28 to 31);
					when others => s := (others => '0');	-- illegal value on source signal
				end case;
				for j in 0 to 15 loop
					if (j + to_integer(unsigned(s))) < 16 then
						s1_result(8*j to 8*j + 7) <= s1_ra(8*(j + to_integer(unsigned(s))) to 8*(j + to_integer(unsigned(s))) + 7);
					else
						s1_result(8*j to 8*j + 7) <= s1_ra(8*(j + to_integer(unsigned(s)) - 16) to 8*(j + to_integer(unsigned(s)) - 16) + 7);
					end if;
				end loop;
			elsif s1_shared_ctrl(4 to 5) = "11" then	-- shift by bits
				case s1_shared_ctrl(0) is
					when '1' =>	s := ('0' & s1_i7) and "00000111";
					when '0' => s := "00000" & s1_rb(29 to 31);
					when others => s := (others => '0');	-- illegal value on source signal
				end case;
				for j in 0 to 127 loop
					if (j + to_integer(unsigned(s))) < 128 then
						s1_result(j) <= s1_ra(j + to_integer(unsigned(s)));
					else
						s1_result(j) <= s1_ra(j + to_integer(unsigned(s)) - 128);
					end if;
				end loop;
			else					-- illegal control signals
				s1_result <= (others => '0');
			end if;
		end if;
	end process perm_s1_computation_proc;
	
	perm_s1_s2_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				s2_result <= (others => '0');
				pipe_en(2) <= '0';
			else
				s2_result <= s1_result;
				pipe_en(2) <= pipe_en(1);
			end if;
		end if;
	end process perm_s1_s2_reg;
	
	perm_s2_s3_reg: process(clk, clr)
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
	end process perm_s2_s3_reg;
	
	result <= s3_result;
	wb_en <= pipe_en;
end model;

-- this "behavioral" architecture attempts to split the computation into stages and more accurately represent a pipe
architecture behavioral of pipe_permute is

begin
	
end behavioral;