-- tb_tag.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_tag is end tb_tag;

architecture sim of tb_tag is
  constant TAG_SIZE  : integer := 4;    -- tag width T
  constant BIT_SIZE  : integer := 31;   -- record width (we use low12 bits)
  constant KEY_WIDTH : integer := 32;   -- width of secret_key port on DUT

  -- 32-bit secret key with 0x3211 in the upper 16 bits: 0011 0010 0001 0001 0000 0000 0000 0000
  constant SECRET_KEY_HEX : integer := 16#32110000#;

  -- [ tally(8) | cand(2) | dist(2) ] in the 12 LSBs
  signal incoming_bits : std_logic_vector(BIT_SIZE-1 downto 0);
  signal secret_key    : std_logic_vector(KEY_WIDTH-1 downto 0);
  signal output_tag    : std_logic_vector(TAG_SIZE-1 downto 0);

  component tag
    generic (
      tag_size  : integer := 4;
      bit_size  : integer := 31;
      key_width : integer := 32
    );
    port (
      incoming_bits : in  std_logic_vector(bit_size-1 downto 0);
      secret_key    : in  std_logic_vector(key_width-1 downto 0);
      output_tag    : out std_logic_vector(tag_size-1 downto 0)
    );
  end component;
begin
  dut: tag
    generic map (
      tag_size  => TAG_SIZE,
      bit_size  => BIT_SIZE,
      key_width => KEY_WIDTH
    )
    port map (
      incoming_bits => incoming_bits,
      secret_key    => secret_key,
      output_tag    => output_tag
    );

  stim: process
  begin
    -- Secret key = 0x32110000 (MSB-half = 0x3211)
    secret_key <= std_logic_vector(to_unsigned(SECRET_KEY_HEX, KEY_WIDTH));

    -- Test 1
    -- low12 = 0x000 -> tally=0x00, cand=0, dist=0
    incoming_bits <= (others => '0'); wait for 10 ns;

    -- Test 2
    -- low12 = 0x567 -> tally=0x56 (86), cand=1, dist=3
    incoming_bits <= std_logic_vector(to_unsigned(16#1234567#, BIT_SIZE)); wait for 10 ns;

    -- Test 3
    -- low12 = 0x001 -> tally=0x00, cand=0, dist=1
    incoming_bits <= std_logic_vector(to_unsigned(16#0000001#, BIT_SIZE)); wait for 10 ns;

    -- Test 4
    -- low12 = 0x5A5 -> tally=0x5A (90), cand=1, dist=1
    incoming_bits <= std_logic_vector(to_unsigned(16#5A5A5A5#, BIT_SIZE)); wait for 10 ns;

    -- Test 5
    -- low12 = 0xFFF -> tally=0xFF (255), cand=3, dist=3
    incoming_bits <= std_logic_vector(to_unsigned(16#7FFFFFF#, BIT_SIZE)); wait for 10 ns;

    wait;
  end process;
end architecture;
