library ieee;
use ieee.std_logic_1164.all;

entity instruction_route is
	port(
	i0_ra_index		: in std_logic_vector(0 to 6);
	i0_rb_index		: in std_logic_vector(0 to 6);
	i0_rc_index		: in std_logic_vector(0 to 6);
	i0_rt_index		: in std_logic_vector(0 to 6);
	i0_i16			: in std_logic_vector(0 to 15);
	i0_shared_ctrl	: in std_logic_vector(0 to 7);
	i0_ma_ctrl		: in std_logic_vector(0 to 9);
	i0_sf1_ctrl		: in std_logic_vector(0 to 10);
	i0_sf2_en		: in std_logic;
	i0_byte_en		: in std_logic;
	i0_perm_en		: in std_logic;
	i0_ls_en		: in std_logic;
	i0_br_en		: in std_logic;
	i0_pc			: in std_logic_vector(0 to 31);
	
	i1_ra_index		: in std_logic_vector(0 to 6);
	i1_rb_index		: in std_logic_vector(0 to 6);
	i1_rc_index		: in std_logic_vector(0 to 6);
	i1_rt_index		: in std_logic_vector(0 to 6);
	i1_i16			: in std_logic_vector(0 to 15);
	i1_shared_ctrl	: in std_logic_vector(0 to 7);
	i1_ma_ctrl		: in std_logic_vector(0 to 9);
	i1_sf1_ctrl		: in std_logic_vector(0 to 10);
	i1_sf2_en		: in std_logic;
	i1_byte_en		: in std_logic;
	i1_perm_en		: in std_logic;
	i1_ls_en		: in std_logic;
	i1_br_en		: in std_logic;
	i1_pc			: in std_logic_vector(0 to 31);
	
	stall_i0		: in std_logic;
	stall_i1		: in std_logic;
	
	even_ra_index		: out std_logic_vector(0 to 6);
	even_rb_index		: out std_logic_vector(0 to 6);
	even_rc_index		: out std_logic_vector(0 to 6);
	even_rt_index		: out std_logic_vector(0 to 6);
	even_i16			: out std_logic_vector(0 to 15);
	even_shared_ctrl	: out std_logic_vector(0 to 7);
	even_ma_ctrl		: out std_logic_vector(0 to 9);
	even_sf1_ctrl		: out std_logic_vector(0 to 10);
	even_sf2_en			: out std_logic;
	even_byte_en		: out std_logic;
	even_pc				: out std_logic_vector(0 to 31);
	
	odd_ra_index		: out std_logic_vector(0 to 6);
	odd_rb_index		: out std_logic_vector(0 to 6);
	odd_rc_index		: out std_logic_vector(0 to 6);
	odd_rt_index		: out std_logic_vector(0 to 6);
	odd_i16			: out std_logic_vector(0 to 15);
	odd_shared_ctrl		: out std_logic_vector(0 to 7);
	odd_perm_en			: out std_logic;
	odd_ls_en			: out std_logic;
	odd_br_en			: out std_logic;
	odd_br_pos			: out std_logic;
	odd_pc				: out std_logic_vector(0 to 31)
	);
end instruction_route;

architecture behavioral of instruction_route is
begin
	route_process: process(all)
	begin
		if stall_i0 = '1' and stall_i1 = '1' then
			-- issue nop to even pipe
			even_ra_index <= (others => '0');
			even_rb_index <= (others => '0');
			even_rc_index <= (others => '0');
			even_rt_index <= (others => '0');
			even_i16 <= (others => '0');
			even_shared_ctrl <= (others => '0');
			even_ma_ctrl <= (others => '0');
			even_sf1_ctrl <= (others => '0');
			even_sf2_en <= '0';
			even_byte_en <= '0';
			even_pc <= (others => '0');
			
			-- issue lnop to odd pipe
			odd_ra_index <= (others => '0');
			odd_rb_index <= (others => '0');
			odd_rc_index <= (others => '0');
			odd_rt_index <= (others => '0');
			odd_i16 <= (others => '0');
			odd_shared_ctrl <= (others => '0');
			odd_perm_en <= '0';
			odd_ls_en <= '0';
			odd_br_en <= '0';
			odd_br_pos <= '0';
			odd_pc <= (others => '0');
		elsif stall_i1 = '1' then
			if (i0_ma_ctrl(0) = '1' or i0_sf1_ctrl(0) = '1' or i0_sf2_en = '1' or i0_byte_en = '1') then
				-- issue i0 even control signals to even instruction
				even_ra_index <= i0_ra_index;
				even_rb_index <= i0_rb_index;
				even_rc_index <= i0_rc_index;
				even_rt_index <= i0_rt_index;
				even_i16 <= i0_i16;
				even_shared_ctrl <= i0_shared_ctrl;
				even_ma_ctrl <= i0_ma_ctrl;
				even_sf1_ctrl <= i0_sf1_ctrl;
				even_sf2_en <= i0_sf2_en;
				even_byte_en <= i0_byte_en;
				even_pc <= i0_pc;
				
				-- issue lnop to odd pipe
				odd_ra_index <= (others => '0');
				odd_rb_index <= (others => '0');
				odd_rc_index <= (others => '0');
				odd_rt_index <= (others => '0');
				odd_i16 <= (others => '0');
				odd_shared_ctrl <= (others => '0');
				odd_perm_en <= '0';
				odd_ls_en <= '0';
				odd_br_en <= '0';
				odd_br_pos <= '0';
				odd_pc <= (others => '0');
			elsif (i0_perm_en = '1' or i0_ls_en = '1' or i0_br_en = '1') then	-- i0 is to be issued to the odd pipe
				-- issue nop to even pipe
				even_ra_index <= (others => '0');
				even_rb_index <= (others => '0');
				even_rc_index <= (others => '0');
				even_rt_index <= (others => '0');
				even_i16 <= (others => '0');
				even_shared_ctrl <= (others => '0');
				even_ma_ctrl <= (others => '0');
				even_sf1_ctrl <= (others => '0');
				even_sf2_en <= '0';
				even_byte_en <= '0';
				even_pc <= (others => '0');
				
				-- issue i0 to odd pipe
				odd_ra_index <= i0_ra_index;
				odd_rb_index <= i0_rb_index;
				odd_rc_index <= i0_rc_index;
				odd_rt_index <= i0_rt_index;
				odd_i16 <= i0_i16;
				odd_shared_ctrl <= i0_shared_ctrl;
				odd_perm_en <= i0_perm_en;
				odd_ls_en <= i0_ls_en;
				odd_br_en <= i0_br_en;
				odd_br_pos <= '1';
				odd_pc <= i0_pc;
			else	-- i0 is a nop
				-- issue nop to even pipe
				even_ra_index <= (others => '0');
				even_rb_index <= (others => '0');
				even_rc_index <= (others => '0');
				even_rt_index <= (others => '0');
				even_i16 <= (others => '0');
				even_shared_ctrl <= (others => '0');
				even_ma_ctrl <= (others => '0');
				even_sf1_ctrl <= (others => '0');
				even_sf2_en <= '0';
				even_byte_en <= '0';
				even_pc <= (others => '0');
				
				-- issue lnop to odd pipe
				odd_ra_index <= (others => '0');
				odd_rb_index <= (others => '0');
				odd_rc_index <= (others => '0');
				odd_rt_index <= (others => '0');
				odd_i16 <= (others => '0');
				odd_shared_ctrl <= (others => '0');
				odd_perm_en <= '0';
				odd_ls_en <= '0';
				odd_br_en <= '0';
				odd_br_pos <= '0';
				odd_pc <= (others => '0');
			end if;
		else	-- no hazards - both instructions can be issued - neither instruction will attempt to use the same pipe
			if (i0_ma_ctrl(0) = '1' or i0_sf1_ctrl(0) = '1' or i0_sf2_en = '1' or i0_byte_en = '1') then	-- i0 needs to be issued into the even pipe
				-- issue i0 even control signals to even instruction
				even_ra_index <= i0_ra_index;
				even_rb_index <= i0_rb_index;
				even_rc_index <= i0_rc_index;
				even_rt_index <= i0_rt_index;
				even_i16 <= i0_i16;
				even_shared_ctrl <= i0_shared_ctrl;
				even_ma_ctrl <= i0_ma_ctrl;
				even_sf1_ctrl <= i0_sf1_ctrl;
				even_sf2_en <= i0_sf2_en;
				even_byte_en <= i0_byte_en;
				even_pc <= i0_pc;
			elsif (i1_ma_ctrl(0) = '1' or i1_sf1_ctrl(0) = '1' or i1_sf2_en = '1' or i1_byte_en = '1') then
				-- issue i1 even control signals to even instruction
				even_ra_index <= i1_ra_index;
				even_rb_index <= i1_rb_index;
				even_rc_index <= i1_rc_index;
				even_rt_index <= i1_rt_index;
				even_i16 <= i1_i16;
				even_shared_ctrl <= i1_shared_ctrl;
				even_ma_ctrl <= i1_ma_ctrl;
				even_sf1_ctrl <= i1_sf1_ctrl;
				even_sf2_en <= i1_sf2_en;
				even_byte_en <= i1_byte_en;
				even_pc <= i1_pc;
			else	-- neither instruction was to use an even pipe, and there are no hazards, so issue an even nop		   
				even_ra_index <= (others => '0');
				even_rb_index <= (others => '0');
				even_rc_index <= (others => '0');
				even_rt_index <= (others => '0');
				even_i16 <= (others => '0');
				even_shared_ctrl <= (others => '0');
				even_ma_ctrl <= (others => '0');
				even_sf1_ctrl <= (others => '0');
				even_sf2_en <= '0';
				even_byte_en <= '0';
				even_pc <= (others => '0');
			end if;
			
			if (i0_perm_en = '1' or i0_ls_en = '1' or i0_br_en = '1') then	-- i0 is to be issued to the odd pipe
				odd_ra_index <= i0_ra_index;
				odd_rb_index <= i0_rb_index;
				odd_rc_index <= i0_rc_index;
				odd_rt_index <= i0_rt_index;
				odd_i16 <= i0_i16;
				odd_shared_ctrl <= i0_shared_ctrl;
				odd_perm_en <= i0_perm_en;
				odd_ls_en <= i0_ls_en;
				odd_br_en <= i0_br_en;
				odd_br_pos <= '0';	-- if it's a branch instruction, it came from i0
				odd_pc <= i0_pc;
			elsif (i1_perm_en = '1' or i1_ls_en = '1' or i1_br_en = '1') then	-- i1 is to be issued to the odd pipe
				odd_ra_index <= i1_ra_index;
				odd_rb_index <= i1_rb_index;
				odd_rc_index <= i1_rc_index;
				odd_rt_index <= i1_rt_index; 
				odd_i16 <= i1_i16;
				odd_shared_ctrl <= i1_shared_ctrl;
				odd_perm_en <= i1_perm_en;
				odd_ls_en <= i1_ls_en;
				odd_br_en <= i1_br_en;
				odd_br_pos <= '1';	-- if it's a branch instruction, it came from i1
				odd_pc <= i1_pc;
			else	-- neither instruction was to use the even pipe, and there are no hazards, so issue an odd nop
				odd_ra_index <= i0_ra_index;
				odd_rb_index <= i0_rb_index;
				odd_rc_index <= i0_rc_index;
				odd_rt_index <= i0_rt_index;
				odd_i16 <= (others => '0');
				odd_shared_ctrl <= i0_shared_ctrl;
				odd_perm_en <= i0_perm_en;
				odd_ls_en <= i0_ls_en;
				odd_br_en <= i0_br_en;
				odd_br_pos <= '0';
				odd_pc <= (others => '0');
			end if;
		end if;
	end process route_process;
end behavioral;