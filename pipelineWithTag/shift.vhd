library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity shift is
  generic(tag_size : integer := 6);
  port (
    r : in std_logic_vector(tag_size downto 0);        -- Changed from unsigned
    shift_block : in std_logic_vector(tag_size downto 0);
    output_block : out std_logic_vector(tag_size downto 0)
   );
end shift;

architecture Behavioral of shift is
begin
  -- Simple left shift by 1 for now
  output_block <= shift_block(tag_size-1 downto 0) & shift_block(tag_size);
end Behavioral;