library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity xor_block is
  generic(
    tag_size : integer := 4  -- Bit-width of each block and the final tag
  );
  port (
    block0 : in std_logic_vector(tag_size - 1 downto 0);
    block1 : in std_logic_vector(tag_size - 1 downto 0);
    block2 : in std_logic_vector(tag_size - 1 downto 0);
    block3 : in std_logic_vector(tag_size - 1 downto 0);
    block4 : in std_logic_vector(tag_size - 1 downto 0);
    result : out std_logic_vector(tag_size - 1 downto 0)  -- Final XOR result (tag)
  );
end xor_block;

architecture Behavioral of xor_block is
begin
  result <= block0 xor block1 xor block2 xor block3 xor block4;
end Behavioral;
