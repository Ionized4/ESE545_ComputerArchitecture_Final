library ieee;
use ieee.std_logic_1164.all;

entity forwarding_select is
	port(
	-- data from register file
	even_ra_in	: in std_logic_vector(0 to 127);
	even_rb_in	: in std_logic_vector(0 to 127);
	even_rc_in	: in std_logic_vector(0 to 127);
	odd_ra_in	: in std_logic_vector(0 to 127);
	odd_rb_in	: in std_logic_vector(0 to 127);
	odd_rc_in	: in std_logic_vector(0 to 127);
	
	-- indices for data from register file
	even_ra_index	: in std_logic_vector(0 to 6);
	even_rb_index	: in std_logic_vector(0 to 6);
	even_rc_index	: in std_logic_vector(0 to 6);
	odd_ra_index	: in std_logic_vector(0 to 6);
	odd_rb_index	: in std_logic_vector(0 to 6);
	odd_rc_index	: in std_logic_vector(0 to 6);			
	
	-- data ready and wb_en for stages of each pipeline
	even_data_ready	: in std_logic_vector(2 to 7);
	odd_data_ready	: in std_logic_vector(4 to 7);
	even_wb_en		: in std_logic;
	odd_wb_en		: in std_logic;
	
	-- data and target index from even pipeline
	s2_even_data	: in std_logic_vector(0 to 127);
	s2_even_index	: in std_logic_vector(0 to 6);
	s3_even_data	: in std_logic_vector(0 to 127);
	s3_even_index	: in std_logic_vector(0 to 6);
	s4_even_data	: in std_logic_vector(0 to 127);
	s4_even_index	: in std_logic_vector(0 to 6);
	s5_even_data	: in std_logic_vector(0 to 127);
	s5_even_index	: in std_logic_vector(0 to 6);
	s6_even_data	: in std_logic_vector(0 to 127);
	s6_even_index	: in std_logic_vector(0 to 6);
	s7_even_data	: in std_logic_vector(0 to 127);
	s7_even_index	: in std_logic_vector(0 to 6);
	wb_even_data	: in std_logic_vector(0 to 127);
	wb_even_index	: in std_logic_vector(0 to 6);
	
	-- data and target index from odd pipeline
	s4_odd_data		: in std_logic_vector(0 to 127);
	s4_odd_index	: in std_logic_vector(0 to 6);
	s5_odd_data		: in std_logic_vector(0 to 127);
	s5_odd_index	: in std_logic_vector(0 to 6);
	s6_odd_data		: in std_logic_vector(0 to 127);
	s6_odd_index	: in std_logic_vector(0 to 6);
	s7_odd_data		: in std_logic_vector(0 to 127);
	s7_odd_index	: in std_logic_vector(0 to 6);
	wb_odd_data		: in std_logic_vector(0 to 127);
	wb_odd_index	: in std_logic_vector(0 to 6);
	
	-- selected data		
	even_ra				: out std_logic_vector(0 to 127);
	even_rb				: out std_logic_vector(0 to 127);
	even_rc				: out std_logic_vector(0 to 127);  
	odd_ra				: out std_logic_vector(0 to 127);
	odd_rb				: out std_logic_vector(0 to 127);
	odd_rc				: out std_logic_vector(0 to 127)
	);
end forwarding_select;

architecture behavioral of forwarding_select is
begin
	-- even ra data forwarding
	fwd_sel_even_ra_proc: process(all)
	begin
		-- STAGE 2
		if (even_ra_index = s2_even_index) and (even_data_ready(2) = '1') then		-- forward from stage 2 (even)
			even_ra <= s2_even_data;															  
		-- STAGE 3
		elsif (even_ra_index = s3_even_index) and (even_data_ready(3) = '1') then		-- forward from stage 2 (even)
			even_ra <= s3_even_data;															  
		-- STAGE 4
		elsif (even_ra_index = s4_even_index) and (even_data_ready(4) = '1') then		-- forward from stage 2 (even)
			even_ra <= s4_even_data;
		elsif (even_ra_index = s4_odd_index) and (odd_data_ready(4) = '1') then		-- forward from stage 2 (odd)
			even_ra <= s4_odd_data;															  
		-- STAGE 5
		elsif (even_ra_index = s5_even_index) and (even_data_ready(5) = '1') then		-- forward from stage 2 (even)
			even_ra <= s5_even_data;
		elsif (even_ra_index = s5_odd_index) and (odd_data_ready(5) = '1') then		-- forward from stage 2 (odd)
			even_ra <= s5_odd_data;															  
		-- STAGE 6
		elsif (even_ra_index = s6_even_index) and (even_data_ready(6) = '1') then		-- forward from stage 2 (even)
			even_ra <= s6_even_data;
		elsif (even_ra_index = s6_odd_index) and (odd_data_ready(6) = '1') then		-- forward from stage 2 (odd)
			even_ra <= s6_odd_data;															  
		-- STAGE 7
		elsif (even_ra_index = s7_even_index) and (even_data_ready(7) = '1') then		-- forward from stage 2 (even)
			even_ra <= s7_even_data;
		elsif (even_ra_index = s7_odd_index) and (odd_data_ready(7) = '1') then		-- forward from stage 2 (odd)
			even_ra <= s7_odd_data;															  
		elsif (even_ra_index = wb_even_index) and (even_wb_en = '1') then			-- forward from wb stage (even)
			even_ra <= wb_even_data;
		elsif (even_ra_index = wb_odd_index) and (odd_wb_en = '1') then				-- forward from wb stage (odd)
			even_ra <= wb_odd_data;
		else																		-- no forwarding
			even_ra <= even_ra_in;
		end if;
	end process fwd_sel_even_ra_proc;
	
	-- even rb data forwarding
	fwd_sel_even_rb_proc: process(all)
	begin
		-- STAGE 2
		if (even_rb_index = s2_even_index) and (even_data_ready(2) = '1') then		-- forward from stage 2 (even)
			even_rb <= s2_even_data;															  
		-- STAGE 3
		elsif (even_rb_index = s3_even_index) and (even_data_ready(3) = '1') then		-- forward from stage 2 (even)
			even_rb <= s3_even_data;															  
		-- STAGE 4
		elsif (even_rb_index = s4_even_index) and (even_data_ready(4) = '1') then		-- forward from stage 2 (even)
			even_rb <= s4_even_data;
		elsif (even_rb_index = s4_odd_index) and (odd_data_ready(4) = '1') then		-- forward from stage 2 (odd)
			even_rb <= s4_odd_data;															  
		-- STAGE 5
		elsif (even_rb_index = s5_even_index) and (even_data_ready(5) = '1') then		-- forward from stage 2 (even)
			even_rb <= s5_even_data;
		elsif (even_rb_index = s5_odd_index) and (odd_data_ready(5) = '1') then		-- forward from stage 2 (odd)
			even_rb <= s5_odd_data;															  
		-- STAGE 6
		elsif (even_rb_index = s6_even_index) and (even_data_ready(6) = '1') then		-- forward from stage 2 (even)
			even_rb <= s6_even_data;
		elsif (even_rb_index = s6_odd_index) and (odd_data_ready(6) = '1') then		-- forward from stage 2 (odd)
			even_rb <= s6_odd_data;															  
		-- STAGE 7
		elsif (even_rb_index = s7_even_index) and (even_data_ready(7) = '1') then		-- forward from stage 2 (even)
			even_rb <= s7_even_data;
		elsif (even_rb_index = s7_odd_index) and (odd_data_ready(7) = '1') then		-- forward from stage 2 (odd)
			even_rb <= s7_odd_data;															  
		elsif (even_rb_index = wb_even_index) and (even_wb_en = '1') then			-- forward from wb stage (even)
			even_rb <= wb_even_data;
		elsif (even_rb_index = wb_odd_index) and (odd_wb_en = '1') then				-- forward from wb stage (odd)
			even_rb <= wb_odd_data;
		else																		-- no forwarding
			even_rb <= even_rb_in;
		end if;
	end process fwd_sel_even_rb_proc;
	
	-- even rc data forwarding
	fwd_sel_even_rc_proc: process(all)
	begin
		-- STAGE 2
		if (even_rc_index = s2_even_index) and (even_data_ready(2) = '1') then		-- forward from stage 2 (even)
			even_rc <= s2_even_data;															  
		-- STAGE 3
		elsif (even_rc_index = s3_even_index) and (even_data_ready(3) = '1') then		-- forward from stage 2 (even)
			even_rc <= s3_even_data;															  
		-- STAGE 4
		elsif (even_rc_index = s4_even_index) and (even_data_ready(4) = '1') then		-- forward from stage 2 (even)
			even_rc <= s4_even_data;
		elsif (even_rc_index = s4_odd_index) and (odd_data_ready(4) = '1') then		-- forward from stage 2 (odd)
			even_rc <= s4_odd_data;															  
		-- STAGE 5
		elsif (even_rc_index = s5_even_index) and (even_data_ready(5) = '1') then		-- forward from stage 2 (even)
			even_rc <= s5_even_data;
		elsif (even_rc_index = s5_odd_index) and (odd_data_ready(5) = '1') then		-- forward from stage 2 (odd)
			even_rc <= s5_odd_data;															  
		-- STAGE 6
		elsif (even_rc_index = s6_even_index) and (even_data_ready(6) = '1') then		-- forward from stage 2 (even)
			even_rc <= s6_even_data;
		elsif (even_rc_index = s6_odd_index) and (odd_data_ready(6) = '1') then		-- forward from stage 2 (odd)
			even_rc <= s6_odd_data;															  
		-- STAGE 7
		elsif (even_rc_index = s7_even_index) and (even_data_ready(7) = '1') then		-- forward from stage 2 (even)
			even_rc <= s7_even_data;
		elsif (even_rc_index = s7_odd_index) and (odd_data_ready(7) = '1') then		-- forward from stage 2 (odd)
			even_rc <= s7_odd_data;															  
		elsif (even_rc_index = wb_even_index) and (even_wb_en = '1') then			-- forward from wb stage (even)
			even_rc <= wb_even_data;
		elsif (even_rc_index = wb_odd_index) and (odd_wb_en = '1') then				-- forward from wb stage (odd)
			even_rc <= wb_odd_data;
		else																		-- no forwarding
			even_rc <= even_rc_in;
		end if;
	end process fwd_sel_even_rc_proc;
	
	-- odd ra data forwarding
	fwd_sel_odd_ra_proc: process(all)
	begin
		-- STAGE 2
		if (odd_ra_index = s2_even_index) and (even_data_ready(2) = '1') then		-- forward from stage 2 (even)
			odd_ra <= s2_even_data;															  
		-- STAGE 3
		elsif (odd_ra_index = s3_even_index) and (even_data_ready(3) = '1') then		-- forward from stage 2 (even)
			odd_ra <= s3_even_data;															  
		-- STAGE 4
		elsif (odd_ra_index = s4_even_index) and (even_data_ready(4) = '1') then		-- forward from stage 2 (even)
			odd_ra <= s4_even_data;
		elsif (odd_ra_index = s4_odd_index) and (odd_data_ready(4) = '1') then		-- forward from stage 2 (odd)
			odd_ra <= s4_odd_data;															  
		-- STAGE 5
		elsif (odd_ra_index = s5_even_index) and (even_data_ready(5) = '1') then		-- forward from stage 2 (even)
			odd_ra <= s5_even_data;
		elsif (odd_ra_index = s5_odd_index) and (odd_data_ready(5) = '1') then		-- forward from stage 2 (odd)
			odd_ra <= s5_odd_data;															  
		-- STAGE 6
		elsif (odd_ra_index = s6_even_index) and (even_data_ready(6) = '1') then		-- forward from stage 2 (even)
			odd_ra <= s6_even_data;
		elsif (odd_ra_index = s6_odd_index) and (odd_data_ready(6) = '1') then		-- forward from stage 2 (odd)
			odd_ra <= s6_odd_data;															  
		-- STAGE 7
		elsif (odd_ra_index = s7_even_index) and (even_data_ready(7) = '1') then		-- forward from stage 2 (even)
			odd_ra <= s7_even_data;
		elsif (odd_ra_index = s7_odd_index) and (odd_data_ready(7) = '1') then		-- forward from stage 2 (odd)
			odd_ra <= s7_odd_data;															  
		elsif (odd_ra_index = wb_even_index) and (even_wb_en = '1') then			-- forward from wb stage (even)
			odd_ra <= wb_even_data;
		elsif (odd_ra_index = wb_odd_index) and (odd_wb_en = '1') then				-- forward from wb stage (odd)
			odd_ra <= wb_odd_data;
		else																		-- no forwarding
			odd_ra <= odd_ra_in;
		end if;
	end process fwd_sel_odd_ra_proc;
	
	-- odd rb data forwarding
	fwd_sel_odd_rb_proc: process(all)
	begin
		-- STAGE 2
		if (odd_rb_index = s2_even_index) and (even_data_ready(2) = '1') then		-- forward from stage 2 (even)
			odd_rb <= s2_even_data;															  
		-- STAGE 3
		elsif (odd_rb_index = s3_even_index) and (even_data_ready(3) = '1') then		-- forward from stage 2 (even)
			odd_rb <= s3_even_data;															  
		-- STAGE 4
		elsif (odd_rb_index = s4_even_index) and (even_data_ready(4) = '1') then		-- forward from stage 2 (even)
			odd_rb <= s4_even_data;
		elsif (odd_rb_index = s4_odd_index) and (odd_data_ready(4) = '1') then		-- forward from stage 2 (odd)
			odd_rb <= s4_odd_data;															  
		-- STAGE 5
		elsif (odd_rb_index = s5_even_index) and (even_data_ready(5) = '1') then		-- forward from stage 2 (even)
			odd_rb <= s5_even_data;
		elsif (odd_rb_index = s5_odd_index) and (odd_data_ready(5) = '1') then		-- forward from stage 2 (odd)
			odd_rb <= s5_odd_data;															  
		-- STAGE 6
		elsif (odd_rb_index = s6_even_index) and (even_data_ready(6) = '1') then		-- forward from stage 2 (even)
			odd_rb <= s6_even_data;
		elsif (odd_rb_index = s6_odd_index) and (odd_data_ready(6) = '1') then		-- forward from stage 2 (odd)
			odd_rb <= s6_odd_data;															  
		-- STAGE 7
		elsif (odd_rb_index = s7_even_index) and (even_data_ready(7) = '1') then		-- forward from stage 2 (even)
			odd_rb <= s7_even_data;
		elsif (odd_rb_index = s7_odd_index) and (odd_data_ready(7) = '1') then		-- forward from stage 2 (odd)
			odd_rb <= s7_odd_data;															  
		elsif (odd_rb_index = wb_even_index) and (even_wb_en = '1') then			-- forward from wb stage (even)
			odd_rb <= wb_even_data;
		elsif (odd_rb_index = wb_odd_index) and (odd_wb_en = '1') then				-- forward from wb stage (odd)
			odd_rb <= wb_odd_data;
		else																		-- no forwarding
			odd_rb <= odd_rb_in;
		end if;
	end process fwd_sel_odd_rb_proc;
	
	-- odd rc data forwarding
	fwd_sel_odd_rc_proc: process(all)
	begin
		-- STAGE 2
		if (odd_rc_index = s2_even_index) and (even_data_ready(2) = '1') then		-- forward from stage 2 (even)
			odd_rc <= s2_even_data;															  
		-- STAGE 3
		elsif (odd_rc_index = s3_even_index) and (even_data_ready(3) = '1') then		-- forward from stage 2 (even)
			odd_rc <= s3_even_data;															  
		-- STAGE 4
		elsif (odd_rc_index = s4_even_index) and (even_data_ready(4) = '1') then		-- forward from stage 2 (even)
			odd_rc <= s4_even_data;
		elsif (odd_rc_index = s4_odd_index) and (odd_data_ready(4) = '1') then		-- forward from stage 2 (odd)
			odd_rc <= s4_odd_data;															  
		-- STAGE 5
		elsif (odd_rc_index = s5_even_index) and (even_data_ready(5) = '1') then		-- forward from stage 2 (even)
			odd_rc <= s5_even_data;
		elsif (odd_rc_index = s5_odd_index) and (odd_data_ready(5) = '1') then		-- forward from stage 2 (odd)
			odd_rc <= s5_odd_data;															  
		-- STAGE 6
		elsif (odd_rc_index = s6_even_index) and (even_data_ready(6) = '1') then		-- forward from stage 2 (even)
			odd_rc <= s6_even_data;
		elsif (odd_rc_index = s6_odd_index) and (odd_data_ready(6) = '1') then		-- forward from stage 2 (odd)
			odd_rc <= s6_odd_data;															  
		-- STAGE 7
		elsif (odd_rc_index = s7_even_index) and (even_data_ready(7) = '1') then		-- forward from stage 2 (even)
			odd_rc <= s7_even_data;
		elsif (odd_rc_index = s7_odd_index) and (odd_data_ready(7) = '1') then		-- forward from stage 2 (odd)
			odd_rc <= s7_odd_data;															  
		elsif (odd_rc_index = wb_even_index) and (even_wb_en = '1') then			-- forward from wb stage (even)
			odd_rc <= wb_even_data;
		elsif (odd_rc_index = wb_odd_index) and (odd_wb_en = '1') then				-- forward from wb stage (odd)
			odd_rc <= wb_odd_data;
		else																		-- no forwarding
			odd_rc <= odd_rc_in;
		end if;
	end process fwd_sel_odd_rc_proc;
end behavioral;