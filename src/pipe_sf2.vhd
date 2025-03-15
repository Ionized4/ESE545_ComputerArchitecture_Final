library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipe_sf2 is
	port(
	clk : in std_logic;
	clr : in std_logic;
	
	-- control signals
	shared_ctrl	: in std_logic_vector(0 to 7);
	-- op(0) = 0 if shift instruction, 1 if rotate instruction
	-- source = 0 if argument 2 is the register value, 1 if immediate
	-- op_size(0) = 0 if halfword instruction, 1 if word instruction
	sf2_pipe_en	: in std_logic;
	
	-- data inputs
	ra	: in std_logic_vector(0 to 127);
	rb	: in std_logic_vector(0 to 127);
	i7	: in std_logic_vector(0 to 6);
	
	-- hazard detection outputs
	pipe_en_out	: out std_logic_vector(1 to 3);	-- stage 3 does not need to be checked, cause data will be ready at stage 3
	-- arguably, stage 2 doesn't need to be checked either, because when the hazard checking stage sees an instruction in stage 2, the data will be ready in the next stage
	
	flush	: in std_logic_vector(0 to 1);
	
	-- output
	result_data	: out std_logic_vector(0 to 127)
	);
end pipe_sf2;

architecture model of pipe_sf2 is

signal s1_shared_ctrl	: std_logic_vector(0 to 7);	-- signals for future stages are not made because this model architecture computes the result in one stage and passes the result through all stages
	
signal s1_ra, s1_rb		: std_logic_vector(0 to 127);
signal s1_i7			: std_logic_vector(0 to 6);

signal pipe_en	: std_logic_vector(1 to 3);

signal s1_result	: std_logic_vector(0 to 127);
signal s2_result	: std_logic_vector(0 to 127);
signal s3_result	: std_logic_vector(0 to 127);

begin
	sf2_input_s1_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' or flush(0) = '1' then
				s1_ra <= (others => '0');
				s1_rb <= (others => '0');
				s1_i7 <= (others => '0');
				
				s1_shared_ctrl <= (others => '0');
				pipe_en(1) <= '0';
			else
				s1_ra <= ra;
				s1_rb <= rb;
				s1_i7 <= i7;
				
				s1_shared_ctrl <= shared_ctrl;
				pipe_en(1) <= sf2_pipe_en;
			end if;
		end if;
	end process sf2_input_s1_reg;
	
	sf2_s1_result_computation: process(all)
	variable r, s, t : std_logic_vector(0 to 127);
	begin
		if s1_shared_ctrl(4) = '0' and pipe_en(1) = '1' then		-- halfword instruction
			for j in 0 to 7 loop
				if s1_shared_ctrl(0) = '0' then
					s(16*j to 16*j + 15) := s1_rb(16*j to 16*j + 15);
				else
					s(16*j to 16*j + 15) := std_logic_vector(resize(signed(s1_i7), 16));	
				end if;
				s(16*j to 16*j + 15) := s(16*j to 16*j + 15) and ("00000000000" & (not s1_shared_ctrl(1)) & "1111");
				t(16*j to 16*j + 15) := s1_ra(16*j to 16*j + 15);	

				for b in 0 to 15 loop
					if b + to_integer(unsigned(s(16*j to 16*j + 15))) < 16 then
						r(16*j + b) := t(16*j + b + to_integer(unsigned(s(16*j to 16*j + 15))));					-- left shift assignment
					else
						r(16*j + b) := t(16*j + b + to_integer(unsigned(s(16*j to 16*j + 15))) - 16) and s1_shared_ctrl(1);	-- if op = 1, performs the rotation, otherwise the and completes the shift operation
					end if;
				end loop;  
			
				s1_result(16*j to 16*j + 15) <= r(16*j to 16*j + 15);	-- existence of r is not necessary, but used just to mimic the RTL description
			end loop;
		elsif pipe_en(1) = '1' then						-- word instruction
			for j in 0 to 3 loop
				if s1_shared_ctrl(0) = '0' then
					s(32*j to 32*j + 31) := s1_rb(32*j to 32*j + 31);
				else
					s(32*j to 32*j + 31) := std_logic_vector(resize(signed(s1_i7), 32));	
				end if;
				s(32*j to 32*j + 31) := s(32*j to 32*j + 31) and ("00000000000000000000000000" & (not s1_shared_ctrl(1)) & "11111");
				t(32*j to 32*j + 31) := s1_ra(32*j to 32*j + 31);

				for b in 0 to 31 loop
					if b + to_integer(unsigned(s(32*j to 32*j + 31))) < 32 then
						r(32*j + b) := t(32*j + b + to_integer(unsigned(s(32*j to 32*j + 31))));					-- left shift assignment
					else
						r(32*j + b) := t(32*j + b + to_integer(unsigned(s(32*j to 32*j + 31))) - 32) and s1_shared_ctrl(1);	-- if op = 1, performs the rotation, otherwise the and completes the shift operation
					end if;
				end loop;  
			
				s1_result(32*j to 32*j + 31) <= r(32*j to 32*j + 31);	-- existence of r is not necessary, but used just to mimic the RTL description
			end loop;
		else
			s1_result <= (others => '0');
		end if;
	end process sf2_s1_result_computation;	
	
	sf2_s1_s2_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' or flush(1) = '1' then
				pipe_en(2) <= '0';
				s2_result <= (others => '0');
			else
				pipe_en(2) <= pipe_en(1);
				s2_result <= s1_result;
			end if;
		end if;
	end process sf2_s1_s2_reg;
	
	sf2_s2_s3_reg: process(clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' then
				pipe_en(3) <= '0';
				s3_result <= (others => '0');
			else
				pipe_en(3) <= pipe_en(2);
				s3_result <= s2_result;
			end if;
		end if;
	end process sf2_s2_s3_reg;
	
	result_data <= s3_result;
	pipe_en_out(1 to 3) <= pipe_en(1 to 3);
	
end model;