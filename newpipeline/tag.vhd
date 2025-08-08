library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tag is
  generic(
    tag_size : integer := 6;
    bit_size : integer := 31   
  );
  Port (
    incoming_bits : in std_logic_vector(bit_size downto 0);
    output_tag : out std_logic_vector(tag_size downto 0)
   );
end tag;

--MAIN------------------------------------------------
architecture Behavioral of tag is

  constant adjustment_size: integer := (tag_size + 1) - ((bit_size + 1) mod (tag_size + 1));
  constant block_count : integer := (tag_size + bit_size + 1) / (tag_size + 1);
  constant extended_size : integer := bit_size + adjustment_size;

  -- Key constants
  constant key_bf : integer := 1;
  constant key_py : integer := 0;
  constant key_px : integer := 1;
  constant key_bx : integer := 0;
  constant key_by : integer := 1;
  constant key_s : integer := 2;
  constant key_bs : integer := 1;
  constant key_r : integer := 2;

  type block_array is array(0 to block_count - 1) of std_logic_vector(tag_size downto 0);

  procedure swap(
    variable blk_x : inout std_logic_vector;
    variable blk_y : inout std_logic_vector;
    px, py, size : integer
  ) is
    variable temp_x : std_logic_vector(size - 1 downto 0);
    variable temp_y : std_logic_vector(size - 1 downto 0);
  begin
    temp_x := blk_x(px + size - 1 downto px);
    temp_y := blk_y(py + size - 1 downto py);
    blk_x(px + size - 1 downto px) := temp_y;
    blk_y(py + size - 1 downto py) := temp_x;
  end procedure;

  procedure shift(
    variable blk : inout std_logic_vector;
    r : integer
  ) is
    variable temp : std_logic_vector(blk'range);
  begin
    temp := blk;
    for i in blk'range loop
        blk(i) := temp((i + r) mod blk'length);
    end loop;
  end procedure;

begin
  process (incoming_bits)
    variable extended_bits : std_logic_vector(extended_size downto 0);
    variable blocks        : block_array;
    variable tag : std_logic_vector(tag_size downto 0);
  begin
    -- Extend bits
    if adjustment_size > 0 then
        extended_bits := incoming_bits & std_logic_vector(to_unsigned(0, adjustment_size));
    else
        extended_bits := incoming_bits;
    end if;
    
    -- Slice blocks
    for i in 0 to block_count - 1 loop
      blocks(i) := extended_bits((i+1)*(tag_size+1) -1 downto i*(tag_size+1));
    end loop;

    -- Flip
    blocks(key_bf) := not blocks(key_bf);

    -- Swap block
    swap(blocks(key_bx), blocks(key_by), key_px, key_py, key_s);

    -- Shift one block
    shift(blocks(key_bs), key_r);

    -- XOR all blocks
    tag := (others => '0');
    for i in 0 to block_count - 1 loop
        tag := tag xor blocks(i);
    end loop;

    output_tag <= tag;
  end process;
end Behavioral;
