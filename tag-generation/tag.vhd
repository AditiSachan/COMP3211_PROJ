library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tag is
  generic(
    tag_size : integer := 4;
    bit_size : integer := 31
  );
  port (
    incoming_bits : in std_logic_vector(31 downto 0);
    output_tag    : out std_logic_vector(6 downto 0)  -- padded 4-bit tag
  );
end tag;

architecture Behavioral of tag is

  -- Component declarations
  component flip is
    generic(tag_size : integer := 4);
    port (
      flip_block   : in  std_logic_vector(tag_size - 1 downto 0);
      output_block : out std_logic_vector(tag_size - 1 downto 0)
    );
  end component;

  component swap is
    generic(tag_size : integer := 4);
    port (
      block_x  : in  std_logic_vector(tag_size - 1 downto 0);
      block_y  : in  std_logic_vector(tag_size - 1 downto 0);
      p_x      : in  std_logic_vector(tag_size - 1 downto 0);
      p_y      : in  std_logic_vector(tag_size - 1 downto 0);
      s        : in  std_logic_vector(tag_size - 1 downto 0);
      output_x : out std_logic_vector(tag_size - 1 downto 0);
      output_y : out std_logic_vector(tag_size - 1 downto 0)
    );
  end component;

  component shift is
    generic(tag_size : integer := 4);
    port (
      r            : in  std_logic_vector(tag_size - 1 downto 0);
      shift_block  : in  std_logic_vector(tag_size - 1 downto 0);
      output_block : out std_logic_vector(tag_size - 1 downto 0)
    );
  end component;

  component xor_block is
    generic(tag_size : integer := 4);
    port (
      block0 : in std_logic_vector(tag_size - 1 downto 0);
      block1 : in std_logic_vector(tag_size - 1 downto 0);
      block2 : in std_logic_vector(tag_size - 1 downto 0);
      block3 : in std_logic_vector(tag_size - 1 downto 0);
      block4 : in std_logic_vector(tag_size - 1 downto 0);
      result : out std_logic_vector(tag_size - 1 downto 0)
    );
  end component;

  -- Signals
  signal block0, block1, block2, block3, block4     : std_logic_vector(tag_size - 1 downto 0);
  signal flip0, flip1, flip2, flip3, flip4          : std_logic_vector(tag_size - 1 downto 0);
  signal swap0, swap1, swap2, swap3, swap4          : std_logic_vector(tag_size - 1 downto 0);
  signal shift0, shift1, shift2, shift3, shift4     : std_logic_vector(tag_size - 1 downto 0);
  signal xor_result                                 : std_logic_vector(tag_size - 1 downto 0);

  -- Constant control values (can later be passed from a secret key module)
  constant px  : std_logic_vector(tag_size - 1 downto 0) := "0000";
  constant py  : std_logic_vector(tag_size - 1 downto 0) := "0001";
  constant s   : std_logic_vector(tag_size - 1 downto 0) := "0010";  -- swap 2 bits
  constant rot : std_logic_vector(tag_size - 1 downto 0) := "0001";  -- rotate by 1

begin

  -- Block partitioning (20 LSBs of incoming_bits, divided into 5×4-bit blocks)
  block0 <= incoming_bits(3 downto 0);
  block1 <= incoming_bits(7 downto 4);
  block2 <= incoming_bits(11 downto 8);
  block3 <= incoming_bits(15 downto 12);
  block4 <= incoming_bits(19 downto 16);

  -- Flip stage
  flip0_inst : flip generic map(tag_size) port map(flip_block => block0, output_block => flip0);
  flip1_inst : flip generic map(tag_size) port map(flip_block => block1, output_block => flip1);
  flip2_inst : flip generic map(tag_size) port map(flip_block => block2, output_block => flip2);
  flip3_inst : flip generic map(tag_size) port map(flip_block => block3, output_block => flip3);
  flip4_inst : flip generic map(tag_size) port map(flip_block => block4, output_block => flip4);

  -- Swap stage (0<->1, 2<->3), block4 untouched
  swap01 : swap generic map(tag_size) port map(
    block_x => flip0, block_y => flip1, p_x => px, p_y => py, s => s,
    output_x => swap0, output_y => swap1
  );

  swap23 : swap generic map(tag_size) port map(
    block_x => flip2, block_y => flip3, p_x => px, p_y => py, s => s,
    output_x => swap2, output_y => swap3
  );

  swap4 <= flip4;  -- no swap for block4

  -- Shift stage (rotate-left by 1)
  shift0_inst : shift generic map(tag_size) port map(r => rot, shift_block => swap0, output_block => shift0);
  shift1_inst : shift generic map(tag_size) port map(r => rot, shift_block => swap1, output_block => shift1);
  shift2_inst : shift generic map(tag_size) port map(r => rot, shift_block => swap2, output_block => shift2);
  shift3_inst : shift generic map(tag_size) port map(r => rot, shift_block => swap3, output_block => shift3);
  shift4_inst : shift generic map(tag_size) port map(r => rot, shift_block => swap4, output_block => shift4);

  -- XOR tag generation
  xor_inst : xor_block generic map(tag_size) port map(
    block0 => shift0,
    block1 => shift1,
    block2 => shift2,
    block3 => shift3,
    block4 => shift4,
    result => xor_result
  );

  -- Output tag: padded to 7 bits (3 leading zeros)
  output_tag <= "000" & xor_result;

end Behavioral;
