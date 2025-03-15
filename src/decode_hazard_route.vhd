library ieee;
use ieee.std_logic_1164.all;
library cell_spu;
use cell_spu.all;

-- this is a VHDL entity that encloses all the components related to the instruction decode stage
-- if anyone cares, this is combinational
-- this does instruction decoding, hazard detection, routing, and branch prediction
entity decode_stage is
	port(
	-- input instructions
	i0	: in std_logic_vector(0 to 31);
	i1	: in std_logic_vector(0 to 31);
	
	-- associated program counters for input instructions
	i0_pc	: in std_logic_vector(0 to 31);
	i1_pc	: in std_logic_vector(0 to 31);
	
	-- data hazard detection signals
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
	
	-- controls for instruction to be issued to the even pipe
	even_ra_index	: out std_logic_vector(0 to 6);
	even_rb_index	: out std_logic_vector(0 to 6);
	even_rc_index	: out std_logic_vector(0 to 6);
	even_rt_index	: out std_logic_vector(0 to 6);
	even_i16		: out std_logic_vector(0 to 15);	 
	even_shared_ctrl	: out std_logic_vector(0 to 7);
	even_ma_ctrl		: out std_logic_vector(0 to 9);
	even_sf1_ctrl		: out std_logic_vector(0 to 10);
	even_sf2_wb_en		: out std_logic;
	even_byte_wb_en		: out std_logic;
	even_pc				: out std_logic_vector(0 to 31);
	
	-- controls for instruction to be issued to the odd pipe
	odd_ra_index	: out std_logic_vector(0 to 6);
	odd_rb_index	: out std_logic_vector(0 to 6);
	odd_rc_index	: out std_logic_vector(0 to 6);
	odd_rt_index	: out std_logic_vector(0 to 6);
	odd_i16			: out std_logic_vector(0 to 15);	 
	odd_shared_ctrl	: out std_logic_vector(0 to 7);	 
	odd_perm_wb_en	: out std_logic;
	odd_ls_en		: out std_logic;
	odd_br_en		: out std_logic;
	odd_br_pos		: out std_logic;
	odd_pc			: out std_logic_vector(0 to 31);
	
	-- hazard control signals
	stall_i0	: out std_logic;
	stall_i1	: out std_logic;
	pc_disable	: out std_logic;	
	
	-- branch prediction outputs
	br_predict_target	: out std_logic_vector(0 to 31);
	br_predict_taken	: out std_logic;
	
	i0_stop	: out std_logic;
	i1_stop	: out std_logic
	);
end decode_stage;

architecture structural of decode_stage is
-- instruction 0 decoded signals
signal i0_ra_index			: std_logic_vector(0 to 6);
signal i0_rb_index			: std_logic_vector(0 to 6);
signal i0_rc_index			: std_logic_vector(0 to 6);
signal i0_rt_index			: std_logic_vector(0 to 6);
signal i0_i16				: std_logic_vector(0 to 15);
signal i0_shared_ctrl		: std_logic_vector(0 to 7);	   
signal i0_ma_ctrl			: std_logic_vector(0 to 9);
signal i0_sf1_ctrl			: std_logic_vector(0 to 10);
signal i0_sf2_pipe_en		: std_logic;
signal i0_byte_pipe_en		: std_logic;
signal i0_ls_pipe_en		: std_logic;
signal i0_perm_pipe_en		: std_logic;
signal i0_br_pipe_en		: std_logic;
signal i0_registers_used	: std_logic_vector(1 to 3);	-- tracks which source registers should actually prevent a stall

-- instruction 1 decoded signals															
signal i1_ra_index			: std_logic_vector(0 to 6);
signal i1_rb_index			: std_logic_vector(0 to 6);
signal i1_rc_index			: std_logic_vector(0 to 6);
signal i1_rt_index			: std_logic_vector(0 to 6);
signal i1_i16				: std_logic_vector(0 to 15);
signal i1_shared_ctrl		: std_logic_vector(0 to 7);	   
signal i1_ma_ctrl			: std_logic_vector(0 to 9);
signal i1_sf1_ctrl			: std_logic_vector(0 to 10);
signal i1_sf2_pipe_en		: std_logic;
signal i1_byte_pipe_en		: std_logic;
signal i1_ls_pipe_en		: std_logic;
signal i1_perm_pipe_en		: std_logic;
signal i1_br_pipe_en		: std_logic;
signal i1_registers_used	: std_logic_vector(1 to 3);

-- hazard signals
signal structural_hazard	: std_logic;
signal data_hazard_i0		: std_logic;
signal data_hazard_i1		: std_logic;

-- branch prediction signals (internal signals, so I make them end with the suffix _in)			
signal odd_br_en_in	: std_logic;
begin
	i0_decoder : entity instruction_decoder port map(
		instruction => i0, ra_index => i0_ra_index, rb_index => i0_rb_index, rc_index => i0_rc_index, rt_index => i0_rt_index, i16 => i0_i16, shared_ctrl => i0_shared_ctrl, ma_ctrl => i0_ma_ctrl,
		sf1_ctrl => i0_sf1_ctrl, sf2_pipe_en => i0_sf2_pipe_en, byte_pipe_en => i0_byte_pipe_en, ls_pipe_en => i0_ls_pipe_en, perm_pipe_en => i0_perm_pipe_en, br_pipe_en => i0_br_pipe_en,			
		registers_used => i0_registers_used, stop => i0_stop
	);
	
	i1_decoder : entity instruction_decoder port map(
		instruction => i1, ra_index => i1_ra_index, rb_index => i1_rb_index, rc_index => i1_rc_index, rt_index => i1_rt_index, i16 => i1_i16, shared_ctrl => i1_shared_ctrl, ma_ctrl => i1_ma_ctrl,
		sf1_ctrl => i1_sf1_ctrl, sf2_pipe_en => i1_sf2_pipe_en, byte_pipe_en => i1_byte_pipe_en, ls_pipe_en => i1_ls_pipe_en, perm_pipe_en => i1_perm_pipe_en, br_pipe_en => i1_br_pipe_en,	
		registers_used => i1_registers_used, stop => i1_stop
	);
	
	structural_hazard_detector : entity structural_hazard_detector port map(
		i0_ma => i0_ma_ctrl(0), i0_sf1 => i0_sf1_ctrl(0), i0_sf2 => i0_sf2_pipe_en, i0_byte => i0_byte_pipe_en, i0_perm => i0_perm_pipe_en, i0_ls => i0_ls_pipe_en, i0_br => i0_br_pipe_en,
		i1_ma => i1_ma_ctrl(0), i1_sf1 => i1_sf1_ctrl(0), i1_sf2 => i1_sf2_pipe_en, i1_byte => i1_byte_pipe_en, i1_perm => i1_perm_pipe_en, i1_ls => i1_ls_pipe_en, i1_br => i1_br_pipe_en,
		structural_hazard => structural_hazard
	);
	
	data_hazard_detector : entity data_hazard_detector port map(
		i0_ra_index => i0_ra_index, i0_rb_index => i0_rb_index, i0_rc_index => i0_rc_index, i0_rt_index => i0_rt_index, i0_registers_used => i0_registers_used,
		i1_ra_index => i1_ra_index, i1_rb_index => i1_rb_index, i1_rc_index => i1_rc_index, i1_registers_used => i1_registers_used,
		i0_wb_en => (i0_ma_ctrl(0) or i0_sf1_ctrl(0) or i0_sf2_pipe_en or i0_byte_pipe_en or i0_perm_pipe_en or ( /* load instruction */ i0_ls_pipe_en and (not i0_shared_ctrl(1)) )),
		rf_even_index => rf_even_index, rf_odd_index => rf_odd_index, rf_even_wb_en => rf_even_wb_en, rf_odd_wb_en => rf_odd_wb_en,
		ma_int_wb_en => ma_int_wb_en, ma_flt_wb_en => ma_flt_wb_en, sf2_wb_en => sf2_wb_en, byte_wb_en => byte_wb_en, perm_wb_en => perm_wb_en, ls_wb_en => ls_wb_en,
		s1_even_index => s1_even_index, s2_even_index => s2_even_index, s3_even_index => s3_even_index, s4_even_index => s4_even_index, s5_even_index => s5_even_index,
		s1_odd_index => s1_odd_index, s2_odd_index => s2_odd_index, s3_odd_index => s3_odd_index, s4_odd_index => s4_odd_index,
		data_hazard_i0 => data_hazard_i0, data_hazard_i1 => data_hazard_i1
	);
	
	stall_generator : entity stall_generator port map(
		structural_hazard => structural_hazard, i0_data_hazard => data_hazard_i0, i1_data_hazard => data_hazard_i1,
		stall_i0 => stall_i0, stall_i1 => stall_i1, pc_disable => pc_disable
	);
	
	instruction_route : entity instruction_route port map(
		i0_ra_index => i0_ra_index, i0_rb_index => i0_rb_index, i0_rc_index => i0_rc_index, i0_rt_index => i0_rt_index, i0_i16 => i0_i16,
		i0_shared_ctrl => i0_shared_ctrl, i0_ma_ctrl => i0_ma_ctrl, i0_sf1_ctrl => i0_sf1_ctrl, i0_sf2_en => i0_sf2_pipe_en, i0_byte_en => i0_byte_pipe_en,
		i0_perm_en => i0_perm_pipe_en, i0_ls_en => i0_ls_pipe_en, i0_br_en => i0_br_pipe_en, i0_pc => i0_pc,
		
		i1_ra_index => i1_ra_index, i1_rb_index => i1_rb_index, i1_rc_index => i1_rc_index, i1_rt_index => i1_rt_index, i1_i16 => i1_i16,
		i1_shared_ctrl => i1_shared_ctrl, i1_ma_ctrl => i1_ma_ctrl, i1_sf1_ctrl => i1_sf1_ctrl, i1_sf2_en => i1_sf2_pipe_en, i1_byte_en => i1_byte_pipe_en,
		i1_perm_en => i1_perm_pipe_en, i1_ls_en => i1_ls_pipe_en, i1_br_en => i1_br_pipe_en, i1_pc => i1_pc,
		
		stall_i0 => stall_i0, stall_i1 => stall_i1,
		
		even_ra_index => even_ra_index, even_rb_index => even_rb_index, even_rc_index => even_rc_index, even_rt_index => even_rt_index, even_i16 => even_i16,
		even_shared_ctrl => even_shared_ctrl, even_ma_ctrl => even_ma_ctrl, even_sf1_ctrl => even_sf1_ctrl, even_sf2_en => even_sf2_wb_en, even_byte_en => even_byte_wb_en, even_pc => even_pc,
		odd_ra_index => odd_ra_index, odd_rb_index => odd_rb_index, odd_rc_index => odd_rc_index, odd_rt_index => odd_rt_index, odd_i16 => odd_i16,
		odd_shared_ctrl => odd_shared_ctrl, odd_perm_en => odd_perm_wb_en, odd_ls_en => odd_ls_en, odd_br_en => odd_br_en, odd_br_pos => odd_br_pos, odd_pc => odd_pc
	);
	
	branch_predict : entity branch_prediction port map(
		pc => odd_pc, i16 => odd_i16, br_en => odd_br_en, br_mode => odd_shared_ctrl(6), target => br_predict_target, predict_taken => br_predict_taken
	);
end structural;