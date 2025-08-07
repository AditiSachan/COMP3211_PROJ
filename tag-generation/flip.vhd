library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity flip is
  generic(tag_size : integer := 4);  -- Size of the block to flip
  port (
    flip_block   : in  std_logic_vector(tag_size - 1 downto 0);  -- input block
    output_block : out std_logic_vector(tag_size - 1 downto 0)   -- flipped (NOT) block
  );
end flip;

architecture Behavioral of flip is
begin
  -- Bitwise inversion
  output_block <= not flip_block;
end Behavioral;
