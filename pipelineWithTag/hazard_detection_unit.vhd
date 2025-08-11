library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity hazard_detection_unit is
    port (  opcode           : in  std_logic_vector(3 downto 0);
            pc_stall         : out std_logic;
            reg1_sync_reset  : out std_logic);
end hazard_detection_unit;

architecture structural of hazard_detection_unit is

    constant OP_BUFGET   : std_logic_vector(3 downto 0) := X"1";
    constant OP_MEMPUT   : std_logic_vector(3 downto 0) := X"2";
    constant OP_TAG      : std_logic_vector(3 downto 0) := X"4";
    constant OP_SUCCESS  : std_logic_vector(3 downto 0) := X"5";
    constant OP_FAIL     : std_logic_vector(3 downto 0) := X"6";
    constant OP_BEQ      : std_logic_vector(3 downto 0) := X"A";
    constant OP_BEQZ     : std_logic_vector(3 downto 0) := X"B";
    constant OP_B        : std_logic_vector(3 downto 0) := X"C";

begin

    pc_stall <= '1' when (opcode = OP_BEQ or opcode = OP_BEQZ or opcode = OP_B) else '0';
    reg1_sync_reset <= '1' when (opcode = OP_BEQ or opcode = OP_BEQZ or opcode = OP_B) else '0';

end structural;
