library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_tag is
end tb_tag;

architecture sim of tb_tag is

  component tag
    generic(
      tag_size : integer := 4;
      bit_size : integer := 31
    );
    port (
      incoming_bits : in std_logic_vector(31 downto 0);
      output_tag    : out std_logic_vector(tag_size - 1 downto 0)
    );
  end component;

  signal incoming_bits : std_logic_vector(31 downto 0);
  signal output_tag    : std_logic_vector(3 downto 0);  -- 4-bit tag

begin

  -- Instantiate the DUT
  uut: tag
    generic map(tag_size => 4, bit_size => 31)
    port map(
      incoming_bits => incoming_bits,
      output_tag    => output_tag
    );

  -- Stimulus process
  stim_proc: process
  begin
    wait for 10 ns;

    -- Test 1: D=0, C=0, T=0
    -- Bits: [Tally=00000000][C=00][D=00] → 00000000_00_00 = x"000"
    incoming_bits <= (others => '0');  -- zero everything
    wait for 10 ns;
--    report "Test 1: D=0, C=0, T=0 => Tag = " & to_hstring(output_tag);

    -- Test 2: D=1, C=2, T=3
    -- Tally=00000011, C=10, D=01 → binary: 00000011_10_01 = b"000000111001" = x"039"
    incoming_bits <= (31 downto 12 => '0') & "000000111001";
    wait for 10 ns;
--    report "Test 2: D=1, C=2, T=3 => Tag = " & to_hstring(output_tag);

    -- Test 3: D=3, C=3, T=15
    -- Tally=00001111, C=11, D=11 → b"000011111111" = x"3FF"
    incoming_bits <= (31 downto 12 => '0') & "000011111111";
    wait for 10 ns;
--    report "Test 3: D=3, C=3, T=15 => Tag = " & to_hstring(output_tag);

    wait;
  end process;

end sim;
