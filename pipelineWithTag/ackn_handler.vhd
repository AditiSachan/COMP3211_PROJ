library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ackn_handler is
    generic (N: integer := 16);
    port (
        data_in     : in std_logic_vector(N-1 downto 0);
        ackn_in     : in std_logic;
        data_out    : out std_logic_vector(N-1 downto 0) );
end ackn_handler;

architecture structural of ackn_handler is
begin
    data_out <= data_in when ackn_in = '1' else (others => '0');
end structural;
