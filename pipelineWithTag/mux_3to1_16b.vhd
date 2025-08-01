library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux_3to1_16b is
    port ( sel      : in  std_logic_vector(1 downto 0);
           data_a   : in  std_logic_vector(15 downto 0);
           data_b   : in  std_logic_vector(15 downto 0);
           data_c   : in  std_logic_vector(15 downto 0);
           data_out : out std_logic_vector(15 downto 0) );
end mux_3to1_16b;

architecture behavioral of mux_3to1_16b is
begin
    process(sel, data_a, data_b, data_c)
    begin
        case sel is
            when "00" => data_out <= data_a;
            when "01" => data_out <= data_b;
            when "10" => data_out <= data_c;
            when others => data_out <= data_a;
        end case;
    end process;
end behavioral;



