library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
library cell_spu;
use cell_spu.all;
use cell_spu.instruction_memory_types.all;

entity model is
end model;

architecture structural of model is

signal clk, clr	: std_logic := '0';

-- INSTRUCTION FETCH SIGNALS						
signal IF_predict_addr	: std_logic_vector(0 to 31);
signal IF_next_i0_addr	: std_logic_vector(0 to 31);
signal IF_next_i1_addr	: std_logic_vector(0 to 31);
signal IF_current_PC	: std_logic_vector(0 to 31);
signal IF_next_PC		: std_logic_vector(0 to 31);

signal IF_next_i0		: std_logic_vector(0 to 31); -- the instruction that is retrieved from IMEM
signal IF_next_i1		: std_logic_vector(0 to 31);
signal IF_int_i0		: std_logic_vector(0 to 31);	-- intermediate signal between the two muxes used to select i0
												-- if i1 is stalled, a nop is inserted here with the first mux. if i0 is stalled, this will not be selected by the subsequent mux
signal IF_issued_i0		: std_logic_vector(0 to 31); -- the instruction that is sent to decode stage
signal IF_issued_i1		: std_logic_vector(0 to 31);
signal IF_int_i0_pc	: std_logic_vector(0 to 31);
signal IF_issued_i0_pc	: std_logic_vector(0 to 31); -- program counter for issued i0
signal IF_issued_i1_pc	: std_logic_vector(0 to 31);

-- inputs to the decode stage
signal ID_i0	: std_logic_vector(0 to 31);
signal ID_i0_pc	: std_logic_vector(0 to 31);
signal ID_i1	: std_logic_vector(0 to 31);
signal ID_i1_pc	: std_logic_vector(0 to 31);	

-- flushing
signal ID_even_flush	: std_logic;
signal ID_odd_flush	: std_logic;

-- ID STAGE SIGNALS

-- OUTPUTS
signal ID_even_ra_index	: std_logic_vector(0 to 6);
signal ID_even_rb_index	: std_logic_vector(0 to 6);
signal ID_even_rc_index	: std_logic_vector(0 to 6);
signal ID_even_rt_index	: std_logic_vector(0 to 6);
signal ID_even_i16		: std_logic_vector(0 to 15);
signal ID_even_shared_ctrl	: std_logic_vector(0 to 7);
signal ID_even_ma_ctrl		: std_logic_vector(0 to 9);
signal ID_even_sf1_ctrl	: std_logic_vector(0 to 10);
signal ID_even_sf2_en		: std_logic;
signal ID_even_byte_en		: std_logic;
signal ID_even_pc			: std_logic_vector(0 to 31);
													   
signal ID_odd_ra_index		: std_logic_vector(0 to 6);
signal ID_odd_rb_index		: std_logic_vector(0 to 6);
signal ID_odd_rc_index		: std_logic_vector(0 to 6);
signal ID_odd_rt_index		: std_logic_vector(0 to 6);	  
signal ID_odd_i16			: std_logic_vector(0 to 15);
signal ID_odd_shared_ctrl	: std_logic_vector(0 to 7);
signal ID_odd_perm_en		: std_logic;
signal ID_odd_ls_en		: std_logic;
signal ID_odd_br_en		: std_logic;
signal ID_odd_br_pos		: std_logic;
signal ID_odd_pc			: std_logic_vector(0 to 31);

signal stall_i0	: std_logic;
signal stall_i1	: std_logic;
signal pc_disable	: std_logic;

signal branch_predict_target	: std_logic_vector(0 to 31);
signal branch_predict_taken		: std_logic;

-- RF STAGE SIGNALS
signal RF_even_ra_index		: std_logic_vector(0 to 6);
signal RF_even_rb_index		: std_logic_vector(0 to 6);
signal RF_even_rc_index		: std_logic_vector(0 to 6);
signal RF_even_rt_index		: std_logic_vector(0 to 6);
signal RF_even_i16			: std_logic_vector(0 to 15);
signal RF_even_shared_ctrl	: std_logic_vector(0 to 7);
signal RF_even_ma_ctrl		: std_logic_vector(0 to 9);
signal RF_even_sf1_ctrl		: std_logic_vector(0 to 10);
signal RF_even_sf2_en		: std_logic;
signal RF_even_byte_en		: std_logic;
signal RF_even_pc			: std_logic_vector(0 to 31);
													   
signal RF_odd_ra_index		: std_logic_vector(0 to 6);
signal RF_odd_rb_index		: std_logic_vector(0 to 6);
signal RF_odd_rc_index		: std_logic_vector(0 to 6);
signal RF_odd_rt_index		: std_logic_vector(0 to 6);	  
signal RF_odd_i16			: std_logic_vector(0 to 15);
signal RF_odd_shared_ctrl	: std_logic_vector(0 to 7);
signal RF_odd_perm_en		: std_logic;
signal RF_odd_ls_en			: std_logic;
signal RF_odd_br_en			: std_logic;
signal RF_odd_br_pos		: std_logic;
signal RF_odd_br_prediction	: std_logic;
signal RF_odd_pc			: std_logic_vector(0 to 31);

signal RF_even_wb_en	: std_logic;
signal RF_odd_wb_en	: std_logic;

-- flushing
signal RF_even_flush	: std_logic;
signal RF_odd_flush	: std_logic;

-- REGISTER FILE OUTPUTS
signal even_ra_rf	: std_logic_vector(0 to 127);
signal even_rb_rf	: std_logic_vector(0 to 127);
signal even_rc_rf	: std_logic_vector(0 to 127);
signal odd_ra_rf	: std_logic_vector(0 to 127);
signal odd_rb_rf	: std_logic_vector(0 to 127);
signal odd_rc_rf	: std_logic_vector(0 to 127);

-- FORWARDED REGISTER VALUES
signal RF_even_ra	: std_logic_vector(0 to 127);
signal RF_even_rb	: std_logic_vector(0 to 127);
signal RF_even_rc	: std_logic_vector(0 to 127);	 
signal RF_odd_ra	: std_logic_vector(0 to 127);
signal RF_odd_rb	: std_logic_vector(0 to 127);
signal RF_odd_rc	: std_logic_vector(0 to 127);

signal i0_stop	: std_logic;
signal i1_stop	: std_logic;

signal ma_float_result	: std_logic_vector(0 to 127);
signal ma_float_wb_en	: std_logic_vector(1 to 6);
signal ma_int_result	: std_logic_vector(0 to 127);
signal ma_int_wb_en		: std_logic_vector(1 to 7);				

signal sf1_result	: std_logic_vector(0 to 127);
signal sf1_wb_en	: std_logic_vector(1 to 2);

signal sf2_wb_en	: std_logic_vector(1 to 3);
signal sf2_result	: std_logic_vector(0 to 127);

signal byte_wb_en	: std_logic_vector(1 to 3);
signal byte_result	: std_logic_vector(0 to 127);

signal perm_wb_en	: std_logic_vector(1 to 3);
signal perm_result	: std_logic_vector(0 to 127);

signal ls_result	: std_logic_vector(0 to 127);
signal ls_wb_en		: std_logic_vector(1 to 6);

signal br_address		: std_logic_vector(0 to 31);
signal s1_br_pc		: std_logic_vector(0 to 31);
signal s1_br_pos		: std_logic;
signal br_taken		: std_logic;
signal br_mispredict	: std_logic; 

-- flushing
signal s1_even_pc		: std_logic_vector(0 to 31);
signal s1_even_flush	: std_logic;

-- WRITEBACK SIGNALS
signal WB_even_wb_index	: std_logic_vector(0 to 6);
signal WB_odd_wb_index	: std_logic_vector(0 to 6);

signal WB_even_wb_en	: std_logic;	-- these should probably be turned into an std_logic_vector(1 to 8) for hazard control
signal WB_odd_wb_en		: std_logic;

signal WB_even_wb_data	: std_logic_vector(0 to 127);
signal WB_odd_wb_data	: std_logic_vector(0 to 127);

-- FORWARDING SIGNALS
signal even_data_ready	: std_logic_vector(2 to 7);
signal odd_data_ready	: std_logic_vector(4 to 7);

signal s2_even_data	: std_logic_vector(0 to 127);
signal s3_even_data	: std_logic_vector(0 to 127);
signal s4_even_data	: std_logic_vector(0 to 127);
signal s5_even_data	: std_logic_vector(0 to 127);
signal s6_even_data	: std_logic_vector(0 to 127);
signal s7_even_data	: std_logic_vector(0 to 127);

signal s4_odd_data	: std_logic_vector(0 to 127);
signal s5_odd_data	: std_logic_vector(0 to 127);
signal s6_odd_data	: std_logic_vector(0 to 127);
signal s7_odd_data	: std_logic_vector(0 to 127);

signal s1_even_index	: std_logic_vector(0 to 6);
signal s2_even_index	: std_logic_vector(0 to 6);
signal s3_even_index	: std_logic_vector(0 to 6);
signal s4_even_index	: std_logic_vector(0 to 6);
signal s5_even_index	: std_logic_vector(0 to 6);
signal s6_even_index	: std_logic_vector(0 to 6);
signal s7_even_index	: std_logic_vector(0 to 6);

signal s1_odd_index	: std_logic_vector(0 to 6);
signal s2_odd_index	: std_logic_vector(0 to 6);
signal s3_odd_index	: std_logic_vector(0 to 6);
signal s4_odd_index	: std_logic_vector(0 to 6);
signal s5_odd_index	: std_logic_vector(0 to 6);
signal s6_odd_index	: std_logic_vector(0 to 6);
signal s7_odd_index	: std_logic_vector(0 to 6);

-- FORWARDING REGISTER OUTPUTS
signal s23_fwreg_data_out	: std_logic_vector(0 to 127);
signal s56_fwreg_data_out	: std_logic_vector(0 to 127);
signal s56_oddfwreg_data_out	: std_logic_vector(0 to 127);
signal s67_fwreg_data_out	: std_logic_vector(0 to 127);

signal s23_fwreg_data_ready_out	: std_logic;
signal s56_fwreg_data_ready_out	: std_logic;
signal s56_oddfwreg_data_ready_out	: std_logic;
signal s67_fwreg_data_ready_out	: std_logic;

signal instruction_memory	: instruction_memory_array;	-- 4KB instruction memory (just using the same data type as the LOAD/STORE element from that package)

constant period	: time := 20ns;

begin
	-- INSTRUCTION FETCH STAGE
	pc : entity program_counter port map(
		clk => clk, clr => clr, pc_in => IF_next_PC, pc_out => IF_current_PC 
	);
	
	pc_en_mux : entity mux_32 port map(
		a => std_logic_vector(signed(IF_next_i0_addr) + to_signed(8, 32)), b => IF_next_i0_addr, sel => (pc_disable and not br_mispredict), y => IF_next_PC
	);
	
	predict_mux : entity mux_32 port map(																
		a => IF_current_PC, b => branch_predict_target, sel => branch_predict_taken, y => IF_predict_addr
	);
	
	branch_mux : entity mux_32 port map(
		a => IF_predict_addr, b => br_address, sel => br_mispredict, y => IF_next_i0_addr
	);
	
	IF_next_i1_addr <= std_logic_vector(signed(IF_next_i0_addr) + to_signed(4, 32));
	
	IF_next_i0 <= instruction_memory(to_integer(unsigned(IF_next_i0_addr)));
	IF_next_i1 <= instruction_memory(to_integer(unsigned(IF_next_i1_addr)));
	
	-- this is the mux that inserts a nop if i1 is stalled
	IF_i0_stall_i1_mux : entity mux_32 port map(
		a => IF_next_i0, b => (1 | 10 => '1', others => '0') /* this is an execute nop */, sel => (stall_i1 and not br_mispredict), y => IF_int_i0 
	);
	
	IF_i0_stall_i0_mux : entity mux_32 port map(
		a => IF_int_i0, b => ID_i0, sel => (stall_i0 and not br_mispredict), y => IF_issued_i0 
	);
	
	IF_i0_pc_stall_i1_mux : entity mux_32 port map(
		a => IF_next_i0_addr, b => (others => '0') /* arbitrary pc for an execute nop */, sel => (stall_i1 and not br_mispredict), y => IF_int_i0_pc 
	);
	
	IF_i0_pc_stall_i0_mux : entity mux_32 port map(
		a => IF_int_i0_pc, b => ID_i0_pc, sel => (stall_i0 and not br_mispredict), y => IF_issued_i0_pc 
	);
	
	IF_i1_mux : entity mux_32 port map(
		a => IF_next_i1, b => ID_i1, sel => (stall_i1 and not br_mispredict), y => IF_issued_i1
	);
	
	IF_i1_pc_mux : entity mux_32 port map(
		a => IF_next_i1_addr, b => ID_i1_pc, sel => (stall_i1 and not br_mispredict), y => IF_issued_i1_pc
	);
	
	IF_ID_pipeline_register : entity IF_ID_pipeline_register port map(
		clk => clk, clr => clr,
		IF_i0 => IF_issued_i0, IF_i1 => IF_issued_i1, IF_i0_pc => IF_issued_i0_pc, IF_i1_pc => IF_issued_i1_pc,
		ID_i0 => ID_i0, ID_i1 => ID_i1, ID_i0_pc => ID_i0_pc, ID_i1_pc => ID_i1_pc
	);
	
	decode_stage : entity decode_stage port map(
		i0 => ID_i0, i1 => ID_i1, i0_pc => ID_i0_pc, i1_pc => ID_i1_pc, rf_even_index => RF_even_rt_index, rf_odd_index => RF_odd_rt_index, rf_even_wb_en => RF_even_wb_en, rf_odd_wb_en => RF_odd_wb_en,
		ma_int_wb_en => ma_int_wb_en(1 to 5), ma_flt_wb_en => ma_float_wb_en(1 to 4), sf2_wb_en => sf2_wb_en(1), byte_wb_en => byte_wb_en(1), perm_wb_en => perm_wb_en(1 to 2), ls_wb_en => ls_wb_en(1 to 4),
		
		s1_even_index => s1_even_index, s2_even_index => s2_even_index, s3_even_index => s3_even_index, s4_even_index => s4_even_index, s5_even_index => s5_even_index,
		s1_odd_index => s1_odd_index, s2_odd_index => s2_odd_index, s3_odd_index => s3_odd_index, s4_odd_index => s4_odd_index,
		
		even_ra_index => ID_even_ra_index, even_rb_index => ID_even_rb_index, even_rc_index => ID_even_rc_index, even_rt_index => ID_even_rt_index, even_i16 => ID_even_i16,
		even_shared_ctrl => ID_even_shared_ctrl,
		even_ma_ctrl => ID_even_ma_ctrl, even_sf1_ctrl => ID_even_sf1_ctrl, even_sf2_wb_en => ID_even_sf2_en, even_byte_wb_en => ID_even_byte_en, even_pc => ID_even_pc,
		odd_ra_index => ID_odd_ra_index, odd_rb_index => ID_odd_rb_index, odd_rc_index => ID_odd_rc_index, odd_rt_index => ID_odd_rt_index, odd_i16 => ID_odd_i16,
		odd_shared_ctrl => ID_odd_shared_ctrl, odd_perm_wb_en => ID_odd_perm_en, odd_ls_en => ID_odd_ls_en, odd_br_en => ID_odd_br_en, odd_br_pos => ID_odd_br_pos, odd_pc => ID_odd_pc,
		stall_i0 => stall_i0, stall_i1 => stall_i1, pc_disable => pc_disable,
		br_predict_target => branch_predict_target, br_predict_taken => branch_predict_taken,
		i0_stop => i0_stop, i1_stop => i1_stop
	);
	
	ID_RF_pipeline_register: process (clk, clr)
	begin
		if rising_edge(clk) then
			if clr = '1' or ID_even_flush = '1' then
				RF_even_ra_index <= (others => '0');
				RF_even_rb_index <= (others => '0');
				RF_even_rc_index <= (others => '0');
				RF_even_rt_index <= (others => '0');
				RF_even_i16 <= (others => '0');
				RF_even_shared_ctrl <= (others => '0');
				RF_even_ma_ctrl <= (others => '0');		  
				RF_even_sf1_ctrl <= (others => '0');
				RF_even_sf2_en <= '0';
				RF_even_byte_en <= '0';
				RF_even_pc <= (others => '0');
			else
				RF_even_ra_index <= ID_even_ra_index;
				RF_even_rb_index <= ID_even_rb_index;
				RF_even_rc_index <= ID_even_rc_index;
				RF_even_rt_index <= ID_even_rt_index;
				RF_even_i16 <= ID_even_i16;
				RF_even_shared_ctrl <= ID_even_shared_ctrl;
				RF_even_ma_ctrl <= ID_even_ma_ctrl;		  
				RF_even_sf1_ctrl <= ID_even_sf1_ctrl;
				RF_even_sf2_en <= ID_even_sf2_en;
				RF_even_byte_en <= ID_even_byte_en;
				RF_even_pc <= ID_even_pc;
			end if;
			
			if clr = '1' or ID_odd_flush = '1' then
				RF_odd_ra_index <= (others => '0');
				RF_odd_rb_index <= (others => '0');
				RF_odd_rc_index <= (others => '0');
				RF_odd_rt_index <= (others => '0');
				RF_odd_i16 <= (others => '0');
				RF_odd_shared_ctrl <= (others => '0');
				RF_odd_perm_en <= '0';
				RF_odd_ls_en <= '0';
				RF_odd_br_en <= '0';
				RF_odd_br_pos <= '0';
				RF_odd_br_prediction <= '0';
				RF_odd_pc <= (others => '0');
			else		  								   
				RF_odd_ra_index <= ID_odd_ra_index;
				RF_odd_rb_index <= ID_odd_rb_index;
				RF_odd_rc_index <= ID_odd_rc_index;
				RF_odd_rt_index <= ID_odd_rt_index;
				RF_odd_i16 <= ID_odd_i16;
				RF_odd_shared_ctrl <= ID_odd_shared_ctrl;
				RF_odd_perm_en <= ID_odd_perm_en;
				RF_odd_ls_en <= ID_odd_ls_en;
				RF_odd_br_en <= ID_odd_br_en;
				RF_odd_br_pos <= ID_odd_br_pos;
				RF_odd_br_prediction <= branch_predict_taken;
				RF_odd_pc <= ID_odd_pc;
			end if;
		end if;
	end process ID_RF_pipeline_register;
	
	RF_even_wb_en <= RF_even_ma_ctrl(0) or RF_even_sf1_ctrl(0) or RF_even_sf2_en or RF_even_byte_en;
	RF_odd_wb_en <= RF_odd_perm_en or (RF_odd_ls_en and (not RF_odd_shared_ctrl(1)));
	
	rf : entity register_file port map(
		clk => clk, clr => clr, even_ra_index => RF_even_ra_index, even_rb_index => RF_even_rb_index, even_rc_index => RF_even_rc_index,
		odd_ra_index => RF_odd_ra_index, odd_rb_index => RF_odd_rb_index, odd_rc_index => RF_odd_rc_index,
		even_wb_en => WB_even_wb_en, even_wb_index => WB_even_wb_index, even_wb_data => WB_even_wb_data,
		odd_wb_en => WB_odd_wb_en, odd_wb_index => WB_odd_wb_index, odd_wb_data => WB_odd_wb_data,
		even_ra => even_ra_rf, even_rb => even_rb_rf, even_rc => even_rc_rf, odd_ra => odd_ra_rf, odd_rb => odd_rb_rf, odd_rc => odd_rc_rf
	);
	
	fwd_sel : entity forwarding_select port map(					
		even_ra_in => even_ra_rf, even_rb_in => even_rb_rf, even_rc_in => even_rc_rf, odd_ra_in => odd_ra_rf, odd_rb_in => odd_rb_rf, odd_rc_in => odd_rc_rf,
		even_ra_index => RF_even_ra_index, even_rb_index => RF_even_rb_index, even_rc_index => RF_even_rc_index,
		odd_ra_index => RF_odd_ra_index, odd_rb_index => RF_odd_rb_index, odd_rc_index => RF_odd_rc_index,
		even_data_ready => even_data_ready, odd_data_ready => odd_data_ready, even_wb_en => WB_even_wb_en, odd_wb_en => WB_odd_wb_en,
		
		s2_even_data => s2_even_data, s2_even_index => s2_even_index,
		s3_even_data => s3_even_data, s3_even_index => s3_even_index,
		s4_even_data => s4_even_data, s4_even_index => s4_even_index, s4_odd_data => s4_odd_data, s4_odd_index => s4_odd_index,
		s5_even_data => s5_even_data, s5_even_index => s5_even_index, s5_odd_data => s5_odd_data, s5_odd_index => s5_odd_index,
		s6_even_data => s6_even_data, s6_even_index => s6_even_index, s6_odd_data => s6_odd_data, s6_odd_index => s6_odd_index,
		s7_even_data => s7_even_data, s7_even_index => s7_even_index, s7_odd_data => s7_odd_data, s7_odd_index => s7_odd_index,
		
		wb_even_data => WB_even_wb_data, wb_even_index => WB_even_wb_index, wb_odd_data => WB_odd_wb_data, wb_odd_index => WB_odd_wb_index,
		
		even_ra => RF_even_ra, even_rb => RF_even_rb, even_rc => RF_even_rc, odd_ra => RF_odd_ra, odd_rb => RF_odd_rb, odd_rc => RF_odd_rc
	);
	
	ma : entity pipe_ma port map(
		clk => clk, clr => clr,
		ra => Rf_even_ra, rb => RF_even_rb, rc => RF_even_rc, imm => RF_even_i16(0 to 9),
		source => RF_even_shared_ctrl(0), ma_ctrl_in => RF_even_ma_ctrl, flush => RF_even_flush & s1_even_flush, float_result_data => ma_float_result, float_wb_en => ma_float_wb_en,
		int_result_data => ma_int_result, int_wb_en => ma_int_wb_en
	);
	
	sf1 : entity pipe_sf1 port map(
		clk => clk, clr => clr, ra => RF_even_ra, rb => RF_even_rb, rc => RF_even_rc, i16 => RF_even_i16, shared_ctrl => RF_even_shared_ctrl, sf1_ctrl => RF_even_sf1_ctrl,
		flush => RF_even_flush & s1_even_flush,
		result_data => sf1_result, wb_en => sf1_wb_en 
	);
	
	sf2 : entity pipe_sf2 port map(
		clk => clk, clr => clr, shared_ctrl => RF_even_shared_ctrl, sf2_pipe_en => RF_even_sf2_en, flush => RF_even_flush & s1_even_flush, ra => RF_even_ra, rb => RF_even_rb,
		i7 => RF_even_i16(0 to 6),
		pipe_en_out => sf2_wb_en, result_data => sf2_result 
	);
	
	byte : entity pipe_byte port map(
		clk => clk, clr => clr, pipe_en_in => RF_even_byte_en, shared_ctrl => RF_even_shared_ctrl, flush => RF_even_flush & s1_even_flush, ra => RF_even_ra, rb => RF_even_rb,
		pipe_en_out => byte_wb_en, result_data => byte_result
	);
	
	perm : entity pipe_permute(model) port map(
		clk => clk, clr => clr, shared_ctrl => RF_odd_shared_ctrl, pipe_en_in => RF_odd_perm_en, ra => RF_odd_ra, rb => RF_odd_rb, rc => RF_odd_rc, i7 => RF_odd_i16(0 to 6),
		wb_en => perm_wb_en, result => perm_result 
	);
	
	ls : entity pipe_ls port map(
		clk => clk, clr => clr, shared_ctrl => RF_odd_shared_ctrl, pipe_en_in => RF_odd_ls_en, ra => RF_odd_ra, rb => RF_odd_rb, rc => RF_odd_rc, i16 => RF_odd_i16,
		wb_en_out => ls_wb_en, result_data => ls_result 
	);
	
	br : entity pipe_branch port map(
		clk => clk, clr => clr, shared_ctrl => RF_odd_shared_ctrl, pipe_en_in => RF_odd_br_en, br_pos => RF_odd_br_pos, prediction => RF_odd_br_prediction, pc => RF_odd_PC,
		ra => RF_odd_ra, i16 => RF_odd_i16, address => br_address, pc_out => s1_br_pc, br_pos_out => s1_br_pos, branch_taken => br_taken, mispredict => br_mispredict 
	);
	
	-- forwarding assignments, components, and processes
	-- even stage 2
	s2_even_data <= sf1_result;
	even_data_ready(2) <= sf1_wb_en(2);
	
	-- even stage 2 to stage 3 forwarding register
	even_s2_s3_fwd_reg : entity forwarding_register port map(
		clk => clk, clr => clr, data_in => s2_even_data, data_ready_in => even_data_ready(2), data_out => s23_fwreg_data_out, data_ready_out => s23_fwreg_data_ready_out
	);
	
	-- even stage 3 data selection
	even_s3_fwd_select: process(all)
	begin
		if s23_fwreg_data_ready_out = '1' then
			s3_even_data <= s23_fwreg_data_out;
			even_data_ready(3) <= s23_fwreg_data_ready_out;
		elsif sf2_wb_en(3) = '1' then
			s3_even_data <= sf2_result;
			even_data_ready(3) <= sf2_wb_en(3);
		elsif byte_wb_en(3) = '1' then
			s3_even_data <= byte_result;
			even_data_ready(3) <= byte_wb_en(3);
		else
			s3_even_data <= (others => '0');
			even_data_ready(3) <= '0';
		end if;
	end process even_s3_fwd_select;
	
	-- even stage 3 to stage 4 forwarding register
	even_s3_s4_fwd_reg : entity forwarding_register port map(
		clk => clk, clr => clr, data_in => s3_even_data, data_ready_in => even_data_ready(3), data_out => s4_even_data, data_ready_out => even_data_ready(4)
	);
	
	-- even stage 4 to stage 5 forwarding register
	even_s4_s5_fwd_reg : entity forwarding_register port map(
		clk => clk, clr => clr, data_in => s4_even_data, data_ready_in => even_data_ready(4), data_out => s5_even_data, data_ready_out => even_data_ready(5)
	);
	
	-- even stage 5 to stage 6 forwarding register
	even_s5_s6_fwd_reg : entity forwarding_register port map(
		clk => clk, clr => clr, data_in => s5_even_data, data_ready_in => even_data_ready(5), data_out => s56_fwreg_data_out, data_ready_out => s56_fwreg_data_ready_out
	);
	
	-- even stage 6 data selection
	even_s6_fwd_select: process(all)
	begin
		if s56_fwreg_data_ready_out = '1' then
			s6_even_data <= s56_fwreg_data_out;
			even_data_ready(6) <= s56_fwreg_data_ready_out;
		elsif ma_float_wb_en(6) = '1' then
			s6_even_data <= ma_float_result;
			even_data_ready(6) <= ma_float_wb_en(6);
		else
			s6_even_data <= (others => '0');
			even_data_ready(6) <= '0';
		end if;
	end process even_s6_fwd_select;
	
	-- even stage 6 to stage 7 forwarding register
	even_s6_s7_fwd_reg : entity forwarding_register port map(
		clk => clk, clr => clr, data_in => s6_even_data, data_ready_in => even_data_ready(6), data_out => s67_fwreg_data_out, data_ready_out => s67_fwreg_data_ready_out
	);
	
	-- even stage 7 data selection
	even_s7_fwd_select: process(all)
	begin
		if s67_fwreg_data_ready_out = '1' then
			s7_even_data <= s67_fwreg_data_out;
			even_data_ready(7) <= s67_fwreg_data_ready_out;
		elsif ma_int_wb_en(7) = '1' then
			s7_even_data <= ma_int_result;
			even_data_ready(7) <= ma_int_wb_en(7);
		else
			s7_even_data <= (others => '0');
			even_data_ready(7) <= '0';
		end if;
	end process even_s7_fwd_select;
	
	-- even stage 7 to writeback stage forwarding register
	even_s7_wb_fwd_reg : entity forwarding_register port map(
		clk => clk, clr => clr, data_in => s7_even_data, data_ready_in => even_data_ready(7), data_out => WB_even_wb_data, data_ready_out => WB_even_wb_en
	);
	
	-- rt index shift register
	even_rt_index_shifter : entity rt_index_shifter port map(
		clk => clk, clr => clr, rt_index_in => RF_even_rt_index,
		s1_rt_index => s1_even_index, s2_rt_index => s2_even_index, s3_rt_index => s3_even_index, s4_rt_index => s4_even_index,
		s5_rt_index => s5_even_index, s6_rt_index => s6_even_index, s7_rt_index => s7_even_index, wb_rt_index => WB_even_wb_index
	);
	
	odd_s3_s4_fwd_reg : entity forwarding_register port map(
		clk => clk, clr => clr, data_in => perm_result, data_ready_in => perm_wb_en(3), data_out => s4_odd_data, data_ready_out => odd_data_ready(4)
	);
	
	odd_s4_s5_fwd_reg : entity forwarding_register port map(
		clk => clk, clr => clr, data_in => s4_odd_data, data_ready_in => odd_data_ready(4), data_out => s5_odd_data, data_ready_out => odd_data_ready(5)
	);
	
	odd_s5_s6_fwd_reg : entity forwarding_register port map(
		clk => clk, clr => clr, data_in => s5_odd_data, data_ready_in => odd_data_ready(5), data_out => s56_oddfwreg_data_out, data_ready_out => s56_oddfwreg_data_ready_out
	);
	
	-- odd stage 6 data selection
	odd_s6_fwd_select: process(all)
	begin
		if s56_oddfwreg_data_ready_out = '1' then
			s6_odd_data <= s56_oddfwreg_data_out;
			odd_data_ready(6) <= s56_oddfwreg_data_ready_out;
		elsif ls_wb_en(6) = '1' then
			s6_odd_data <= ls_result;
			odd_data_ready(6) <= ls_wb_en(6);
		else
			s6_odd_data <= (others => '0');
			odd_data_ready(6) <= '0';
		end if;
	end process odd_s6_fwd_select;
	
	odd_s6_s7_fwd_reg : entity forwarding_register port map(
		clk => clk, clr => clr, data_in => s6_odd_data, data_ready_in => odd_data_ready(6), data_out => s7_odd_data, data_ready_out => odd_data_ready(7)
	);
	
	odd_s7_wb_fwd_reg : entity forwarding_register port map(
		clk => clk, clr => clr, data_in => s7_odd_data, data_ready_in => odd_data_ready(7), data_out => WB_odd_wb_data, data_ready_out => WB_odd_wb_en
	);
	
	odd_rt_index_shifter : entity rt_index_shifter port map(
		clk => clk, clr => clr, rt_index_in => RF_odd_rt_index,
		s1_rt_index => s1_odd_index, s2_rt_index => s2_odd_index, s3_rt_index => s3_odd_index, s4_rt_index => s4_odd_index,
		s5_rt_index => s5_odd_index, s6_rt_index => s6_odd_index, s7_rt_index => s7_odd_index, wb_rt_index => WB_odd_wb_index
	);
	
	s1_even_pc_reg : entity program_counter port map(
		clk => clk, clr => clr, pc_in => RF_even_PC, pc_out => s1_even_pc
	);
	
	flush_generator : entity flush_generator port map(
		ID_even_pc => ID_even_pc, ID_odd_pc => ID_odd_pc, RF_even_pc => RF_even_pc, RF_odd_pc => RF_odd_pc, s1_even_pc => s1_even_pc,
		br_pc => s1_br_pc, br_pos => s1_br_pos, br_taken => br_taken, br_mispredict => br_mispredict,
		ID_even_flush => ID_even_flush, ID_odd_flush => ID_odd_flush, RF_even_flush => RF_even_flush, RF_odd_flush => RF_odd_flush, s1_even_flush => s1_even_flush
	);
	
	-- associated testbench process
	clk_proc: process
	begin
		wait for period / 2;
		clk <= not clk;
	end process clk_proc;
	
	load_instructions : process
	file input 				: text;
	variable L, reg_line		: line;	 
	variable instruction		: std_logic_vector(0 to 31);	-- variable to read the instruction into. read only allows to write to a variable, not a signal	  
	variable instruction_num	: integer := 0;
	variable errors			: integer := 0;
	begin
		-- load instruction buffer contents
		FILE_OPEN(input, "instructions.txt", READ_MODE);
		while not endfile(input) and instruction_num < instruction_memory_size loop
			-- read the next instruction and put it in IB_instruction
			readline(input, L);
			read(L, instruction);	    			  						   
			instruction_memory(instruction_num) <= instruction;
			instruction_num := instruction_num + 4;
		end loop;
		
		while instruction_num < instruction_memory_size loop
			instruction_memory(instruction_num) <= (1 | 10 => '1', others => '0');
			instruction_num := instruction_num + 4;	  
		end loop;
		
		wait;
	end process load_instructions;
	
	testbench: process
	begin
		clr <= '1';
		wait for period;
		clr <= '0';

		wait for period * 70;
		std.env.finish;
	end process testbench;
	
end structural;