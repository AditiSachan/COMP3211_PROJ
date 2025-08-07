library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity swap is
  generic(tag_size : integer := 4);  -- Size of each block (e.g., 4 bits for 4-bit tag)
  port (
    block_x  : in  std_logic_vector(tag_size - 1 downto 0);
    block_y  : in  std_logic_vector(tag_size - 1 downto 0);
    p_x      : in  std_logic_vector(tag_size - 1 downto 0);  -- starting index in block_x
    p_y      : in  std_logic_vector(tag_size - 1 downto 0);  -- starting index in block_y
    s        : in  std_logic_vector(tag_size - 1 downto 0);  -- number of bits to swap
    output_x : out std_logic_vector(tag_size - 1 downto 0);
    output_y : out std_logic_vector(tag_size - 1 downto 0)
  );
end swap;

architecture Behavioral of swap is
begin
  process(block_x, block_y, p_x, p_y, s)
    variable out_x : std_logic_vector(tag_size - 1 downto 0);
    variable out_y : std_logic_vector(tag_size - 1 downto 0);
    variable px_i, py_i, s_i : integer;
  begin
    -- Start with the original blocks
    out_x := block_x;
    out_y := block_y;

    -- Convert inputs to integers with mod to ensure wraparound
    px_i := to_integer(unsigned(p_x)) mod tag_size;
    py_i := to_integer(unsigned(p_y)) mod tag_size;
    s_i  := to_integer(unsigned(s)) mod tag_size;

    -- Swap the s-bit segments with wrap-around
    for i in 0 to s_i - 1 loop
      out_x((px_i + i) mod tag_size) := block_y((py_i + i) mod tag_size);
      out_y((py_i + i) mod tag_size) := block_x((px_i + i) mod tag_size);
    end loop;

    -- Assign final outputs
    output_x <= out_x;
    output_y <= out_y;
  end process;
end Behavioral;
