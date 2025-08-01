library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity swap is
  generic(tag_size : integer := 6);
  port (
    block_x  : in  std_logic_vector(tag_size downto 0);
    block_y  : in  std_logic_vector(tag_size downto 0);
    p_x      : in  std_logic_vector(tag_size downto 0);  -- Changed from unsigned
    p_y      : in  std_logic_vector(tag_size downto 0);  -- Changed from unsigned
    s        : in  std_logic_vector(tag_size downto 0);  -- Changed from unsigned
    output_x : out std_logic_vector(tag_size downto 0);
    output_y : out std_logic_vector(tag_size downto 0)
  );
end swap;

architecture Behavioral of swap is
begin
  -- Simple swap for now - just exchange the blocks
  output_x <= block_y;
  output_y <= block_x;
end Behavioral;