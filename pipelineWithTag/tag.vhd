
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tag is
  generic(
    tag_size : integer := 6;
    bit_size : integer := 31   
  );
  port (
    incoming_bits : in std_logic_vector(31 downto 0);
    output_tag : out std_logic_vector(6 downto 0)
   );
end tag;

architecture Behavioral of tag is

-- Explicit 7-bit signals to avoid width issues
signal block0 : std_logic_vector(6 downto 0);
signal block1 : std_logic_vector(6 downto 0);
signal block2 : std_logic_vector(6 downto 0);
signal block3 : std_logic_vector(6 downto 0);
signal block4 : std_logic_vector(6 downto 0);

signal flip0 : std_logic_vector(6 downto 0);
signal flip1 : std_logic_vector(6 downto 0);
signal flip2 : std_logic_vector(6 downto 0);
signal flip3 : std_logic_vector(6 downto 0);
signal flip4 : std_logic_vector(6 downto 0);

signal swap0 : std_logic_vector(6 downto 0);
signal swap1 : std_logic_vector(6 downto 0);
signal swap2 : std_logic_vector(6 downto 0);
signal swap3 : std_logic_vector(6 downto 0);
signal swap4 : std_logic_vector(6 downto 0);

signal shift0 : std_logic_vector(6 downto 0);
signal shift1 : std_logic_vector(6 downto 0);
signal shift2 : std_logic_vector(6 downto 0);
signal shift3 : std_logic_vector(6 downto 0);
signal shift4 : std_logic_vector(6 downto 0);

signal temp_result : std_logic_vector(6 downto 0);

begin

-- Block partitioning with explicit assignments
block_partition: process(incoming_bits)
begin
    -- Block 0: bits 6 downto 0 (7 bits)
    block0 <= incoming_bits(6 downto 0);
    
    -- Block 1: bits 13 downto 7 (7 bits)
    block1 <= incoming_bits(13 downto 7);
    
    -- Block 2: bits 20 downto 14 (7 bits)
    block2 <= incoming_bits(20 downto 14);
    
    -- Block 3: bits 27 downto 21 (7 bits)
    block3 <= incoming_bits(27 downto 21);
    
    -- Block 4: bits 31 downto 28 (4 bits) + padding (3 bits) = 7 bits total
    block4(3 downto 0) <= incoming_bits(31 downto 28);  -- 4 bits of data
    block4(6 downto 4) <= "000";                        -- 3 bits of padding
end process;

-- FLIP operation: Invert all bits
flip_operation: process(block0, block1, block2, block3, block4)
begin
    flip0 <= not block0;
    flip1 <= not block1;
    flip2 <= not block2;
    flip3 <= not block3;
    flip4 <= not block4;
end process;

-- SWAP operation: Pairwise block exchange
swap_operation: process(flip0, flip1, flip2, flip3, flip4)
begin
    swap0 <= flip1;  -- Block 0 gets Block 1's data
    swap1 <= flip0;  -- Block 1 gets Block 0's data
    swap2 <= flip3;  -- Block 2 gets Block 3's data
    swap3 <= flip2;  -- Block 3 gets Block 2's data
    swap4 <= flip4;  -- Block 4 unchanged (no pair)
end process;

-- SHIFT operation: Left rotate by 1 bit
shift_operation: process(swap0, swap1, swap2, swap3, swap4)
begin
    -- Left rotate: move MSB to LSB, shift others left
    shift0 <= swap0(5 downto 0) & swap0(6);
    shift1 <= swap1(5 downto 0) & swap1(6);
    shift2 <= swap2(5 downto 0) & swap2(6);
    shift3 <= swap3(5 downto 0) & swap3(6);
    shift4 <= swap4(5 downto 0) & swap4(6);
end process;

-- XOR operation: Combine all blocks
xor_operation: process(shift0, shift1, shift2, shift3, shift4)
begin
    temp_result <= shift0 xor shift1 xor shift2 xor shift3 xor shift4;
end process;

-- Output assignment
output_tag <= temp_result;

end Behavioral;