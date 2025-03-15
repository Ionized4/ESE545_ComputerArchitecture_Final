library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity branch_prediction is
	port(
	pc	: in std_logic_vector(0 to 31);
	i16	: in std_logic_vector(0 to 15);
	br_en	: in std_logic;
	br_mode	: in std_logic;	-- 0 = relative, 1 = absolute
	-- don't need br_pos for this predictor. if predict_taken = '1', the target is used, but if predict_taken = '0', the mux in the IF stage selects the next PC
	
	target			: out std_logic_vector(0 to 31);
	predict_taken	: out std_logic
	);
end branch_prediction;

architecture always_taken of branch_prediction is	
begin
	predict_taken <= '1' and br_en;
	br_predict_address_comp: process(all)
	begin
		case br_mode is
			when '0' =>	target <= std_logic_vector(signed(pc) + resize(signed(i16 & "00"), 32));
			when '1' =>	target <= std_logic_vector(resize(signed(i16 & "00"), 32));
			when others =>	target <= (others => '0');
		end case;
	end process br_predict_address_comp;
end always_taken;