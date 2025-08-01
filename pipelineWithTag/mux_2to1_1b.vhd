library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux_2to1_1b is
    port ( mux_select : in  std_logic;
           data_a     : in  std_logic;
           data_b     : in  std_logic;
           data_out   : out std_logic );
end mux_2to1_1b;

architecture behavioral of mux_2to1_1b is
begin
    data_out <= data_a when mux_select = '0' else data_b;
end behavioral;