library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mux_5to1_Nb is
    generic (N: integer := 16);
    port ( mux_select : in  std_logic_vector(2 downto 0);
           data_a     : in  std_logic_vector(N-1 downto 0);
           data_b     : in  std_logic_vector(N-1 downto 0);
           data_c     : in  std_logic_vector(N-1 downto 0);
           data_d     : in  std_logic_vector(N-1 downto 0);
           data_e     : in  std_logic_vector(N-1 downto 0);
           data_out   : out std_logic_vector(N-1 downto 0) );
end mux_5to1_Nb;

architecture behavioral of mux_5to1_Nb is

begin
    mux_process : process (mux_select, data_a, data_b, data_c, data_d, data_e) is
    begin
        case mux_select is
            when "000" =>
                data_out <= data_a;
            when "001" =>
                data_out <= data_b;
            when "010" =>
                data_out <= data_c;
            when "011" =>
                data_out <= data_d;
            when "100" =>
                data_out <= data_e;
            when others =>
                data_out <= data_a;
        end case;
    end process;
end behavioral;
