-----------------------------------------------------------------------------
---- instruction_memory.vhd - Implementation of A Single-Port, 16 x 16-bit
----                          Instruction Memory.
---- 
---- Notes: refer to headers in single_cycle_core.vhd for the supported ISA.
----
---- Copyright (C) 2006 by Lih Wen Koh (lwkoh@cse.unsw.edu.au)
---- All Rights Reserved. 
----
---- The single-cycle processor core is provided AS IS, with no warranty of 
---- any kind, express or implied. The user of the program accepts full 
---- responsibility for the application of the program and the use of any 
---- results. This work may be downloaded, compiled, executed, copied, and 
---- modified solely for nonprofit, educational, noncommercial research, and 
---- noncommercial scholarship purposes provided that this notice in its 
---- entirety accompanies all copies. Copies of the modified software can be 
---- delivered to persons who use it solely for nonprofit, educational, 
---- noncommercial research, and noncommercial scholarship purposes provided 
---- that this notice in its entirety accompanies all copies.
----
-----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity instruction_memory is
    port ( reset    : in  std_logic;
           clk      : in  std_logic;
           addr_in  : in  std_logic_vector(3 downto 0);
           insn_out : out std_logic_vector(15 downto 0) );
end instruction_memory;

architecture behavioral of instruction_memory is
    type mem_array is array(0 to 15) of std_logic_vector(15 downto 0);
    signal sig_insn_mem : mem_array;
begin
    mem_process: process (clk, reset)
        variable var_insn_mem : mem_array;
        variable var_addr     : integer;
    begin
        if reset = '1' then
            -- STALL TEST PROGRAM - Forces load-use hazards that require stalling
            --  0: LOAD R1, R0, 8     - Load data into R1 from mem[8]
            --  1: ADD  R2, R1, R0    - Use R1 immediately (STALL REQUIRED!)
            --  2: LOAD R3, R0, 9     - Load data into R3 from mem[9]  
            --  3: ADD  R4, R3, R1    - Use R3 immediately (STALL REQUIRED!)
            --  4: STORE R4, R0, 10   - Store result
            --  5: LOAD R5, R0, 11    - Another load
            --  6: BEQ  R5, R0, -2    - Use R5 immediately in branch (STALL REQUIRED!)
            --  7: ADD  R6, R5, R4    - More instructions
            --  8: 0x1234             - Data for first LOAD
            --  9: 0x5678             - Data for second LOAD
            -- 10: 0x0000             - Storage location
            -- 11: 0x0000             - Data for third LOAD (R5=0, so branch taken)
            
            var_insn_mem(0)  := X"1018";  -- LOAD R1, R0, 8  (opcode=1, rs=0, rt=1, imm=8)
            var_insn_mem(1)  := X"8102";  -- ADD  R2, R1, R0 (opcode=8, rs=1, rt=0, rd=2)
            var_insn_mem(2)  := X"1039";  -- LOAD R3, R0, 9  (opcode=1, rs=0, rt=3, imm=9)
            var_insn_mem(3)  := X"8314";  -- ADD  R4, R3, R1 (opcode=8, rs=3, rt=1, rd=4)
            var_insn_mem(4)  := X"304A";  -- STORE R4, R0, 10(opcode=3, rs=0, rt=4, imm=A)
            var_insn_mem(5)  := X"105B";  -- LOAD R5, R0, 11 (opcode=1, rs=0, rt=5, imm=B)
            var_insn_mem(6)  := X"450E";  -- BEQ  R5, R0, -2 (opcode=4, rs=5, rt=0, imm=E=-2)
            var_insn_mem(7)  := X"8546";  -- ADD  R6, R5, R4 (opcode=8, rs=5, rt=4, rd=6)
            var_insn_mem(8)  := X"1234";  -- Data: 0x1234
            var_insn_mem(9)  := X"5678";  -- Data: 0x5678
            var_insn_mem(10) := X"0000";  -- Storage location
            var_insn_mem(11) := X"0000";  -- Data: 0x0000
            var_insn_mem(12) := X"0000";
            var_insn_mem(13) := X"0000";
            var_insn_mem(14) := X"0000";
            var_insn_mem(15) := X"0000";
        elsif rising_edge(clk) then
            var_addr := to_integer(unsigned(addr_in));
            insn_out <= var_insn_mem(var_addr);
        end if;
        sig_insn_mem <= var_insn_mem;
    end process;
end behavioral;
