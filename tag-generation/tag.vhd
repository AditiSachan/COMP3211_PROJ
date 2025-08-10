-- tag.vhd (simple slices + debug taps)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tag is
  generic(
    tag_size  : integer := 4;    -- T
    bit_size  : integer := 31;   -- record width
    key_width : integer := 32    -- secret_key width
  );
  port(
    incoming_bits : in  std_logic_vector(bit_size-1 downto 0);
    secret_key    : in  std_logic_vector(key_width-1 downto 0);
    output_tag    : out std_logic_vector(tag_size-1 downto 0)
  );
end tag;

architecture rtl of tag is
  ------------------------------------------------------------------------------
  -- Parameters / types
  ------------------------------------------------------------------------------
  constant NUM_BLOCKS : integer := (bit_size + tag_size - 1) / tag_size; -- ceil
  subtype block_t is std_logic_vector(tag_size-1 downto 0);
  type block_arr_t is array (0 to NUM_BLOCKS-1) of block_t;

  -- Decoded key fields (probe these in the wave)
  signal k_bf, k_by, k_bx, k_bs : integer := 0; -- block indices
  signal k_px, k_py, k_s, k_r   : integer := 0; -- positions/length/rotate

  -- Debug taps: packed blocks after each stage (add to waveform)
  signal stage0, stage1, stage2, stage3 : std_logic_vector(NUM_BLOCKS*tag_size-1 downto 0);

  -- convenience
  constant HI : integer := key_width - 1;

  ------------------------------------------------------------------------------
  -- Helpers
  ------------------------------------------------------------------------------
  -- Pack block array into a single vector (A0 goes in bits [3:0], A1 in [7:4], ...)
  function pack_blocks(b : block_arr_t) return std_logic_vector is
    variable v : std_logic_vector(NUM_BLOCKS*tag_size-1 downto 0);
  begin
    for i in 0 to NUM_BLOCKS-1 loop
      v((i+1)*tag_size-1 downto i*tag_size) := b(i);
    end loop;
    return v;
  end function;

  -- rotate-left by r bits
  function rotl(v : block_t; r_in : integer) return block_t is
    variable n : integer := v'length;
    variable r : integer := r_in mod n;
  begin
    if r = 0 then
      return v;
    else
      return v(n-1-r downto 0) & v(n-1 downto n-r);
    end if;
  end function;

begin
  ------------------------------------------------------------------------------
  -- SIMPLE key decode (top 20 bits, MSB→LSB = [bf(3)|by(3)|bx(3)|py(2)|px(2)|s(2)|r(2)|bs(3)])
  -- For TAG_SIZE=4 → px/py/s/r are 2 bits; NUM_BLOCKS=8 → bf/by/bx/bs are 3 bits.
  ------------------------------------------------------------------------------
  k_bf <= to_integer(unsigned(secret_key(HI      downto HI-2)))  mod NUM_BLOCKS;
  k_by <= to_integer(unsigned(secret_key(HI-3    downto HI-5)))  mod NUM_BLOCKS;
  k_bx <= to_integer(unsigned(secret_key(HI-6    downto HI-8)))  mod NUM_BLOCKS;
  k_py <= to_integer(unsigned(secret_key(HI-9    downto HI-10))) mod tag_size;
  k_px <= to_integer(unsigned(secret_key(HI-11   downto HI-12))) mod tag_size;
  k_s  <= to_integer(unsigned(secret_key(HI-13   downto HI-14))) mod tag_size; -- 0 => full block (handled below)
  k_r  <= to_integer(unsigned(secret_key(HI-15   downto HI-16))) mod tag_size;
  k_bs <= to_integer(unsigned(secret_key(HI-17   downto HI-19))) mod NUM_BLOCKS;

  ------------------------------------------------------------------------------
  -- Main combinational datapath
  ------------------------------------------------------------------------------
  process(incoming_bits, k_bf, k_by, k_bx, k_py, k_px, k_s, k_r, k_bs)
    variable padded : std_logic_vector(NUM_BLOCKS*tag_size-1 downto 0);
    variable blks   : block_arr_t;
    variable acc    : unsigned(tag_size-1 downto 0);
    variable i      : integer;

    -- swap segments between two blocks; px/py count from LSB (rightmost)
    procedure swap_segments(
      variable bx : inout block_t;
      variable by : inout block_t;
      px_in, py_in, s_in : in integer
    ) is
      variable n  : integer := tag_size;
      variable s  : integer := s_in mod n;
      variable px : integer := px_in mod n;
      variable py : integer := py_in mod n;
      variable xi, yi : integer;
      variable tmp : std_logic;
    begin
      if s = 0 then s := n; end if;  -- interpret s=0 as full-block swap
      for k in 0 to s-1 loop
        -- Convert LSB-based position to MSB..LSB string index
        xi := (n - 1) - ((px + k) mod n);
        yi := (n - 1) - ((py + k) mod n);
        tmp    := bx(xi);
        bx(xi) := by(yi);
        by(yi) := tmp;
      end loop;
    end procedure;

  begin
    -- Left-pad MSBs with zeros to a multiple of tag_size
    padded := (others => '0');
    padded(bit_size-1 downto 0) := incoming_bits;

    -- Partition: A0 is the RIGHTMOST 4 bits (LSB side)
    for i in 0 to NUM_BLOCKS-1 loop
      blks(i) := padded((i+1)*tag_size-1 downto i*tag_size);  -- i=0 => bits(3 downto 0)
    end loop;
    stage0 <= pack_blocks(blks);

    -- Flip
    blks(k_bf) := not blks(k_bf);
    stage1 <= pack_blocks(blks);

    -- Swap
    swap_segments(blks(k_bx), blks(k_by), k_px, k_py, k_s);
    stage2 <= pack_blocks(blks);

    -- Shift (rotate-left)
    blks(k_bs) := rotl(blks(k_bs), k_r);
    stage3 <= pack_blocks(blks);

    -- XOR -> tag
    acc := (others => '0');
    for i in 0 to NUM_BLOCKS-1 loop
      acc := acc xor unsigned(blks(i));
    end loop;
    output_tag <= std_logic_vector(acc);
  end process;

end rtl;
