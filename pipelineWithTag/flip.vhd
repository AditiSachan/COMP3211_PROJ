library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity flip is
    generic(tag_size : integer := 4);
    port ( flip_block : in std_logic_vector(tag_size - 1 downto 0);
           output_block : out std_logic_vector(tag_size - 1 downto 0) );
end flip;

architecture Behavioral of flip is
begin
    output_block <= not flip_block;
end Behavioral;
