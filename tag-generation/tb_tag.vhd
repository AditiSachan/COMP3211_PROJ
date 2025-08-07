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
      output_tag    : out std_logic_vector(6 downto 0)
    );
  end component;

  signal incoming_bits : std_logic_vector(31 downto 0);
  signal output_tag    : std_logic_vector(6 downto 0);

begin

  uut: tag
    generic map(tag_size => 4, bit_size => 31)
    port map(
      incoming_bits => incoming_bits,
      output_tag    => output_tag
    );

  stim_proc: process
  begin
--    wait for 10 ns;

    -- Test 1: District = 0, Candidate = 0, Tally = 0
    -- Binary: D=00, C=00, T=00000000, Tag=0000
    --        → "0000000000000000" → x"0000"
    incoming_bits <= x"00000000";
    wait for 10 ns;
--    report "Test 1: D=0, C=0, Tally=0 → Tag = " & to_hstring(output_tag);

    -- Test 2: District = 1, Candidate = 2, Tally = 3
    -- Binary: D=01, C=10, T=00000011, Tag=0000
    --        → "01_10_00000011_0000" = b"0110000000110000" = x"6030"
    incoming_bits <= x"00006030";
    wait for 10 ns;
--    report "Test 2: D=1, C=2, Tally=3 → Tag = " & to_hstring(output_tag);

    -- Test 3: District = 3, Candidate = 3, Tally = 15
    -- Binary: D=11, C=11, T=00001111, Tag=0000
    --        → "11_11_00001111_0000" = b"1111000011110000" = x"F0F0"
    incoming_bits <= x"0000F0F0";
    wait for 10 ns;
--    report "Test 3: D=3, C=3, Tally=15 → Tag = " & to_hstring(output_tag);

    wait;
  end process;

end sim;
