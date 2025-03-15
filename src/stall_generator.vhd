library ieee;
use ieee.std_logic_1164.all;

entity stall_generator is
	port(
	structural_hazard	: in std_logic;
	i0_data_hazard		: in std_logic;
	i1_data_hazard		: in std_logic;
	
	stall_i0			: out std_logic;
	stall_i1			: out std_logic;
	pc_disable			: out std_logic	-- technically not a necessary output, since it gets the same value as stall_i1, but again, I try to keep implementation details abstracted
										-- i.e., I don't want the designer (myself) of the top level design to need to know that pc must be disabled when stall_i1 is 1
	);
end stall_generator;

architecture dataflow of stall_generator is	 
begin
	stall_i0 <= i0_data_hazard;
	stall_i1 <= i0_data_hazard or i1_data_hazard or structural_hazard; 
	pc_disable <= i0_data_hazard or i1_data_hazard or structural_hazard;
end dataflow;