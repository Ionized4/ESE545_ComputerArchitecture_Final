library ieee;
use ieee.std_logic_1164.all;

entity data_hazard_detector is
	port(
	i0_ra_index	: in std_logic_vector(0 to 6);
	i0_rb_index	: in std_logic_vector(0 to 6);
	i0_rc_index	: in std_logic_vector(0 to 6);
	i0_rt_index	: in std_logic_vector(0 to 6);	-- used to check any hazards between i0 and i1
	i1_ra_index	: in std_logic_vector(0 to 6);
	i1_rb_index	: in std_logic_vector(0 to 6);
	i1_rc_index	: in std_logic_vector(0 to 6);
	
	i0_wb_en	: in std_logic;	-- or all the pipe_en inputs, make sure store instructions and branch instructions are treated properly
	
	i0_registers_used	: in std_logic_vector(1 to 3);
	i1_registers_used	: in std_logic_vector(1 to 3);
	
	rf_even_index	: in std_logic_vector(0 to 6);
	rf_odd_index	: in std_logic_vector(0 to 6);
	rf_even_wb_en	: in std_logic;	-- wb for even instruction in rf stage, make sure store and branch treated properly
	rf_odd_wb_en	: in std_logic;	-- same shit as above
	
	ma_int_wb_en	: in std_logic_vector(1 to 5);
	ma_flt_wb_en	: in std_logic_vector(1 to 4);
	-- sf1_wb_en not required
	sf2_wb_en		: in std_logic;	-- only check stage 1
	byte_wb_en		: in std_logic;	-- only check stage 1
	perm_wb_en		: in std_logic_vector(1 to 2);	-- check stages 1 and 2 cause data isn't ready for forwarding until stage 4
	ls_wb_en		: in std_logic_vector(1 to 4);
	
	s1_even_index	: in std_logic_vector(0 to 6);
	s2_even_index	: in std_logic_vector(0 to 6);
	s3_even_index	: in std_logic_vector(0 to 6);
	s4_even_index	: in std_logic_vector(0 to 6);
	s5_even_index	: in std_logic_vector(0 to 6);
	
	s1_odd_index	: in std_logic_vector(0 to 6);
	s2_odd_index	: in std_logic_vector(0 to 6);
	s3_odd_index	: in std_logic_vector(0 to 6);
	s4_odd_index	: in std_logic_vector(0 to 6);
	
	data_hazard_i0	: out std_logic;	-- indicates there is a data hazard that requires i0 to be stalled	 
	data_hazard_i1	: out std_logic		-- indicates there is a data hazard that requires i1 to be stalled
	);
end data_hazard_detector;
	
architecture behavioral of data_hazard_detector is

signal i0_ra_hazard	: std_logic;
signal i0_rb_hazard	: std_logic;
signal i0_rc_hazard	: std_logic;
signal i1_ra_hazard	: std_logic;
signal i1_rb_hazard	: std_logic;
signal i1_rc_hazard	: std_logic;

begin
	i0_hazard_detect: process(all)
	
	function register_equal(a, b : std_logic_vector(0 to 6)) return std_logic is
		variable	diff	: std_logic_vector(0 to 6);
	begin
		diff := a xor b;
		return not (diff(0) or diff(1) or diff(2) or diff(3) or diff(4) or diff(5) or diff(6));
	end register_equal;
	
	begin
		i0_ra_hazard <=
		-- check RF stage
		((register_equal(i0_ra_index, rf_even_index) and rf_even_wb_en) or (register_equal(i0_ra_index, rf_odd_index) and rf_odd_wb_en) or 
		-- check stage 1
		(register_equal(i0_ra_index, s1_even_index) and (ma_int_wb_en(1) or ma_flt_wb_en(1) or sf2_wb_en or byte_wb_en)) or
		(register_equal(i0_ra_index, s1_odd_index) and (perm_wb_en(1) or ls_wb_en(1))) or 
		-- check stage 2
		(register_equal(i0_ra_index, s2_even_index) and (ma_int_wb_en(2) or ma_flt_wb_en(2))) or (register_equal(i0_ra_index, s2_odd_index) and (perm_wb_en(2) or ls_wb_en(2))) or 
		-- check stage 3
		(register_equal(i0_ra_index, s3_even_index) and (ma_int_wb_en(3) or ma_flt_wb_en(3))) or (register_equal(i0_ra_index, s3_odd_index) and ls_wb_en(3)) or 
		-- check stage 4
		(register_equal(i0_ra_index, s4_even_index) and (ma_int_wb_en(4) or ma_flt_wb_en(4))) or (register_equal(i0_ra_index, s4_odd_index) and ls_wb_en(4)) or 
		-- check stage 5
		(register_equal(i0_ra_index, s5_even_index) and ma_int_wb_en(5))
		) and i0_registers_used(1);
		
		i0_rb_hazard <=
		-- check RF stage
		((register_equal(i0_rb_index, rf_even_index) and rf_even_wb_en) or (register_equal(i0_rb_index, rf_odd_index) and rf_odd_wb_en) or 
		-- check stage 1
		(register_equal(i0_rb_index, s1_even_index) and (ma_int_wb_en(1) or ma_flt_wb_en(1) or sf2_wb_en or byte_wb_en)) or
		(register_equal(i0_rb_index, s1_odd_index) and (perm_wb_en(1) or ls_wb_en(1))) or 
		-- check stage 2
		(register_equal(i0_rb_index, s2_even_index) and (ma_int_wb_en(2) or ma_flt_wb_en(2))) or (register_equal(i0_rb_index, s2_odd_index) and (perm_wb_en(2) or ls_wb_en(2))) or 
		-- check stage 3
		(register_equal(i0_rb_index, s3_even_index) and (ma_int_wb_en(3) or ma_flt_wb_en(3))) or (register_equal(i0_rb_index, s3_odd_index) and ls_wb_en(3)) or 
		-- check stage 4
		(register_equal(i0_rb_index, s4_even_index) and (ma_int_wb_en(4) or ma_flt_wb_en(4))) or (register_equal(i0_rb_index, s4_odd_index) and ls_wb_en(4)) or 
		-- check stage 5
		(register_equal(i0_rb_index, s5_even_index) and ma_int_wb_en(5))
		) and i0_registers_used(2);
		
		i0_rc_hazard <=
		-- check RF stage
		((register_equal(i0_rc_index, rf_even_index) and rf_even_wb_en) or (register_equal(i0_rc_index, rf_odd_index) and rf_odd_wb_en) or 
		-- check stage 1
		(register_equal(i0_rc_index, s1_even_index) and (ma_int_wb_en(1) or ma_flt_wb_en(1) or sf2_wb_en or byte_wb_en)) or
		(register_equal(i0_rc_index, s1_odd_index) and (perm_wb_en(1) or ls_wb_en(1))) or 
		-- check stage 2
		(register_equal(i0_rc_index, s2_even_index) and (ma_int_wb_en(2) or ma_flt_wb_en(2))) or (register_equal(i0_rc_index, s2_odd_index) and (perm_wb_en(2) or ls_wb_en(2))) or 
		-- check stage 3
		(register_equal(i0_rc_index, s3_even_index) and (ma_int_wb_en(3) or ma_flt_wb_en(3))) or (register_equal(i0_rc_index, s3_odd_index) and ls_wb_en(3)) or 
		-- check stage 4
		(register_equal(i0_rc_index, s4_even_index) and (ma_int_wb_en(4) or ma_flt_wb_en(4))) or (register_equal(i0_rc_index, s4_odd_index) and ls_wb_en(4)) or 
		-- check stage 5
		(register_equal(i0_rc_index, s5_even_index) and ma_int_wb_en(5))
		) and i0_registers_used(3);
	end process i0_hazard_detect;
	
	data_hazard_i0 <= i0_ra_hazard or i0_rb_hazard or i0_rc_hazard;
	
	i1_hazard_detect: process(all)
	
	function register_equal(a, b : std_logic_vector(0 to 6)) return std_logic is
		variable	diff	: std_logic_vector(0 to 6);
	begin
		diff := a xor b;
		return not(diff(0) or diff(1) or diff(2) or diff(3) or diff(4) or diff(5) or diff(6));
	end register_equal;
	
	begin
		i1_ra_hazard <=
		-- check dependency on i0
		((register_equal(i1_ra_index, i0_rt_index) and i0_wb_en) or
		-- check RF stage
		(register_equal(i1_ra_index, rf_even_index) and rf_even_wb_en) or (register_equal(i1_ra_index, rf_odd_index) and rf_odd_wb_en) or 
		-- check stage 1
		(register_equal(i1_ra_index, s1_even_index) and (ma_int_wb_en(1) or ma_flt_wb_en(1) or sf2_wb_en or byte_wb_en)) or
		(register_equal(i1_ra_index, s1_odd_index) and (perm_wb_en(1) or ls_wb_en(1))) or 
		-- check stage 2
		(register_equal(i1_ra_index, s2_even_index) and (ma_int_wb_en(2) or ma_flt_wb_en(2))) or (register_equal(i1_ra_index, s2_odd_index) and (perm_wb_en(2) or ls_wb_en(2))) or 
		-- check stage 3
		(register_equal(i1_ra_index, s3_even_index) and (ma_int_wb_en(3) or ma_flt_wb_en(3))) or (register_equal(i1_ra_index, s3_odd_index) and ls_wb_en(3)) or 
		-- check stage 4
		(register_equal(i1_ra_index, s4_even_index) and (ma_int_wb_en(4) or ma_flt_wb_en(4))) or (register_equal(i1_ra_index, s4_odd_index) and ls_wb_en(4)) or 
		-- check stage 5
		(register_equal(i1_ra_index, s5_even_index) and ma_int_wb_en(5))
		) and i1_registers_used(1);
		
		i1_rb_hazard <=
		-- check dependency on i0
		((register_equal(i1_rb_index, i0_rt_index) and i0_wb_en) or
		-- check RF stage
		(register_equal(i1_rb_index, rf_even_index) and rf_even_wb_en) or (register_equal(i1_rb_index, rf_odd_index) and rf_odd_wb_en) or 
		-- check stage 1
		(register_equal(i1_rb_index, s1_even_index) and (ma_int_wb_en(1) or ma_flt_wb_en(1) or sf2_wb_en or byte_wb_en)) or
		(register_equal(i1_rb_index, s1_odd_index) and (perm_wb_en(1) or ls_wb_en(1))) or 
		-- check stage 2
		(register_equal(i1_rb_index, s2_even_index) and (ma_int_wb_en(2) or ma_flt_wb_en(2))) or (register_equal(i1_rb_index, s2_odd_index) and (perm_wb_en(2) or ls_wb_en(2))) or 
		-- check stage 3
		(register_equal(i1_rb_index, s3_even_index) and (ma_int_wb_en(3) or ma_flt_wb_en(3))) or (register_equal(i1_rb_index, s3_odd_index) and ls_wb_en(3)) or 
		-- check stage 4
		(register_equal(i1_rb_index, s4_even_index) and (ma_int_wb_en(4) or ma_flt_wb_en(4))) or (register_equal(i1_rb_index, s4_odd_index) and ls_wb_en(4)) or 
		-- check stage 5
		(register_equal(i1_rb_index, s5_even_index) and ma_int_wb_en(5))
		) and i1_registers_used(2);
		
		i1_rc_hazard <=	
		-- check dependency on i0
		((register_equal(i1_rc_index, i0_rt_index) and i0_wb_en) or
		-- check RF stage
		(register_equal(i1_rc_index, rf_even_index) and rf_even_wb_en) or (register_equal(i1_rc_index, rf_odd_index) and rf_odd_wb_en) or 
		-- check stage 1
		(register_equal(i1_rc_index, s1_even_index) and (ma_int_wb_en(1) or ma_flt_wb_en(1) or sf2_wb_en or byte_wb_en)) or
		(register_equal(i1_rc_index, s1_odd_index) and (perm_wb_en(1) or ls_wb_en(1))) or 
		-- check stage 2
		(register_equal(i1_rc_index, s2_even_index) and (ma_int_wb_en(2) or ma_flt_wb_en(2))) or (register_equal(i1_rc_index, s2_odd_index) and (perm_wb_en(2) or ls_wb_en(2))) or 
		-- check stage 3
		(register_equal(i1_rc_index, s3_even_index) and (ma_int_wb_en(3) or ma_flt_wb_en(3))) or (register_equal(i1_rc_index, s3_odd_index) and ls_wb_en(3)) or 
		-- check stage 4
		(register_equal(i1_rc_index, s4_even_index) and (ma_int_wb_en(4) or ma_flt_wb_en(4))) or (register_equal(i1_rc_index, s4_odd_index) and ls_wb_en(4)) or 
		-- check stage 5
		(register_equal(i1_rc_index, s5_even_index) and ma_int_wb_en(5))
		) and i1_registers_used(3);
	end process i1_hazard_detect;
	
	data_hazard_i1 <= i1_ra_hazard or i1_rb_hazard or i1_rc_hazard;
end behavioral;