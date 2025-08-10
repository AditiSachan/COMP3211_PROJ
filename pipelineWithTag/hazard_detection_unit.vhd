---------------------------------------------------------------------------
-- control_unit.vhd - Control Unit Implementation
--
-- Notes: refer to headers in single_cycle_core.vhd for the supported ISA.
--
--  control signals:
--     reg_dst    : asserted for ADD instructions, so that the register
--                  destination number for the 'write_register' comes from
--                  the rd field (bits 3-0). 
--     reg_write  : asserted for ADD and LOAD instructions, so that the
--                  register on the 'write_register' input is written with
--                  the value on the 'write_data' port.
--     alu_src    : asserted for LOAD and STORE instructions, so that the
--                  second ALU operand is the sign-extended, lower 4 bits
--                  of the instruction.
--     mem_write  : asserted for STORE instructions, so that the data 
--                  memory contents designated by the address input are
--                  replaced by the value on the 'write_data' input.
--     mem_to_reg : asserted for LOAD instructions, so that the value fed
--                  to the register 'write_data' input comes from the
--                  data memory.
--
--
-- Copyright (C) 2006 by Lih Wen Koh (lwkoh@cse.unsw.edu.au)
-- All Rights Reserved. 
--
-- The single-cycle processor core is provided AS IS, with no warranty of 
-- any kind, express or implied. The user of the program accepts full 
-- responsibility for the application of the program and the use of any 
-- results. This work may be downloaded, compiled, executed, copied, and 
-- modified solely for nonprofit, educational, noncommercial research, and 
-- noncommercial scholarship purposes provided that this notice in its 
-- entirety accompanies all copies. Copies of the modified software can be 
-- delivered to persons who use it solely for nonprofit, educational, 
-- noncommercial research, and noncommercial scholarship purposes provided 
-- that this notice in its entirety accompanies all copies.
--
---------------------------------------------------------------------------
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
    constant OP_PAR      : std_logic_vector(3 downto 0) := X"3";
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
