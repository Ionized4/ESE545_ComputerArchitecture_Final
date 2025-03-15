library ieee;
use ieee.std_logic_1164.all;

-- a bit overkill to make a single boolean expression an entire component, but I'd like to keep its
-- implementation separated from the main file for the sake of abstraction, heirarchy, and modularity
entity structural_hazard_detector is
	port(
	i0_ma	: in std_logic;
	i0_sf1	: in std_logic;
	i0_sf2	: in std_logic;
	i0_byte	: in std_logic;
	i0_perm	: in std_logic;
	i0_ls	: in std_logic;
	i0_br	: in std_logic;
	
	i1_ma	: in std_logic;
	i1_sf1	: in std_logic;
	i1_sf2	: in std_logic;
	i1_byte	: in std_logic;
	i1_perm	: in std_logic;
	i1_ls	: in std_logic;
	i1_br	: in std_logic;
	
	structural_hazard	: out std_logic
	);
end structural_hazard_detector;

architecture dataflow of structural_hazard_detector is
signal even_hazard, odd_hazard	: std_logic;
begin
	even_hazard <= (i0_ma or i0_sf1 or i0_sf2 or i0_byte) and (i1_ma or i1_sf1 or i1_sf2 or i1_byte);
	odd_hazard <= (i0_perm or i0_ls or i0_br) and (i1_perm or i1_ls or i1_br);
	structural_hazard <= even_hazard or odd_hazard;
end dataflow;
	