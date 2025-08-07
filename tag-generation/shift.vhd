library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity shift is
  generic(tag_size : integer := 4);  -- Block size in bits
  port (
    r            : in  std_logic_vector(tag_size - 1 downto 0);  -- number of bits to rotate
    shift_block  : in  std_logic_vector(tag_size - 1 downto 0);  -- input block
    output_block : out std_logic_vector(tag_size - 1 downto 0)   -- rotated result
  );
end shift;

architecture Behavioral of shift is
begin
  process(r, shift_block)
    variable rot_amount : integer;
    variable temp_block : std_logic_vector(tag_size - 1 downto 0);
  begin
    -- Convert 'r' to integer and wrap with modulo tag_size
    rot_amount := to_integer(unsigned(r)) mod tag_size;

    -- Perform rotate-left by rot_amount bits
    for i in 0 to tag_size - 1 loop
      temp_block(i) := shift_block((i + rot_amount) mod tag_size);
    end loop;

    output_block <= temp_block;
  end process;
end Behavioral;
