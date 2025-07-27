--TODO: Not fully checked yet, needs to be editied to allow for selection of functions
--via opcodes, and changing of values while running
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

--FLIP---------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity flip is
  generic(tag_size : integer);
  Port (
    flip_block : in std_logic_vector(tag_size downto 0);
    output_block : out std_logic_vector(tag_size downto 0)
   );
end flip;

architecture behavioural of flip is
begin
  output_block <= not flip_block;
end behavioural;

--SWAP--------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity swap is
  generic(tag_size : integer);
  Port (
    block_x  : in  std_logic_vector(tag_size downto 0);
    block_y  : in  std_logic_vector(tag_size downto 0);
    p_x      : in  unsigned(tag_size downto 0);
    p_y      : in  unsigned(tag_size downto 0);
    s        : in  unsigned(tag_size downto 0);
    output_x : out std_logic_vector(tag_size downto 0);
    output_y : out std_logic_vector(tag_size downto 0)
  );
end swap;

architecture Behavioral of swap is
begin

process(block_x, block_y, p_x, p_y, s)
  variable temp_x : std_logic_vector(tag_size downto 0);
  variable temp_y : std_logic_vector(tag_size downto 0);
  variable pos_x  : integer;
  variable pos_y  : integer;
  variable s_int  : integer;
  variable bit_x  : std_logic;
  variable bit_y  : std_logic;
begin
  temp_x := block_x;
  temp_y := block_y;
  s_int := to_integer(s);

  for i in 0 to s_int - 1 loop
    pos_x := (to_integer(p_x) + i) mod (tag_size + 1);
    pos_y := (to_integer(p_y) + i) mod (tag_size + 1);

    bit_x := block_x(pos_x);
    bit_y := block_y(pos_y);

    temp_x(pos_x) := bit_y;
    temp_y(pos_y) := bit_x;
  end loop;

  output_x <= temp_x;
  output_y <= temp_y;
end process;

end Behavioral;

---Shift--------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity shift is
generic(tag_size : integer);
  Port (
    r : in unsigned(tag_size downto 0);
    shift_block : in std_logic_vector(tag_size downto 0);
    output_block : out std_logic_vector(tag_size downto 0)
   );
end shift;

architecture Behavioral of shift is

begin

  process(r, shift_block)
    variable temp_block : std_logic_vector(tag_size downto 0);
  begin
    temp_block := shift_block;
    
    for i in 1 to to_integer(r) loop
      temp_block := temp_block(tag_size - 1 downto 0) & temp_block(tag_size);
    end loop;
  
    output_block <= temp_block;
  end process;

end Behavioral;

--MAIN------------------------------------------------
architecture Behavioral of tag is

--Calcuating numbers needed for making vector length and teg length work
constant adjustment_size: integer := (tag_size + 1) - ((bit_size + 1) mod (tag_size + 1));
constant block_count : integer := (tag_size + bit_size + 1) / bit_size + 1;
constant half_block_count : integer := (block_count - (block_count mod 2))/2;
constant extended_size : integer := tag_size + adjustment_size;

type block_array is array(0 to block_count - 1) of std_logic_vector(tag_size downto 0);

signal extended_bits : std_logic_vector(extended_size downto 0);
signal blocks : block_array;
signal flipped : block_array;
signal swapped : block_array;
signal shifted : block_array;
signal xor_block : std_logic_vector(tag_size downto 0);

begin

extended_bits <= incoming_bits & std_logic_vector(to_unsigned(0, adjustment_size))
  when adjustment_size > 0 else
  incoming_bits;

gen_blocks: for i in 0 to block_count - 1 generate
  blocks(i) <= extended_bits((i+1)*tag_size + i downto i*tag_size + i);
end generate;

gen_flip: for i in 0 to block_count - 1 generate
  flip_instance: entity work.flip(behavioural)
    generic map(tag_size => tag_size)
    port map(
      flip_block => blocks(i),
      output_block => flipped(i)
    );
end generate;

gen_swaps: for i in 0 to half_block_count - 1 generate
  swap_instance: entity work.swap(Behavioral)
    generic map(tag_size => tag_size)
    port map (
      block_x  => flipped(2*i),
      block_y  => flipped(2*i + 1),
      p_x      => to_unsigned(0, tag_size + 1),
      p_y      => to_unsigned(0, tag_size + 1),
      s        => to_unsigned(tag_size + 1, tag_size + 1),
      output_x => swapped(2*i),
      output_y => swapped(2*i + 1)
    );
end generate;

gen_shift: for i in 0 to block_count - 1 generate
  shift_instance: entity work.shift(Behavioral)
  generic map(tag_size => tag_size)
  port map (
    r => to_unsigned(0, tag_size + 1),
    shift_block => swapped(i),
    output_block => shifted(i)
  );
end generate;

--Xor
process(shifted)
  variable temp : std_logic_vector(tag_size downto 0);
begin
  temp := (others => '0');
  for i in 0 to block_count - 1 loop
    temp := temp xor shifted(i);
  end loop;
  xor_block <= temp;
end process;

output_tag <= xor_block;

end Behavioral;