---------------------------------------------------------------------------
-- instruction_memory.vhd - Implementation of A Single-Port, 16 x 16-bit
--                          Instruction Memory.
-- 
-- Notes: refer to headers in single_cycle_core.vhd for the supported ISA.
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
    mem_process: process ( clk,
                           addr_in ) is
  
    variable var_insn_mem : mem_array;
    variable var_addr     : integer;
  
    begin
        if (reset = '1') then
            var_insn_mem(0)  := "0011000000000101";
            var_insn_mem(1)  := "0010000000000101";
            var_insn_mem(2)  := "0001000000000101";
            var_insn_mem(3)  := "0000000000000101";
            var_insn_mem(4)  := "0011000000000101";
            var_insn_mem(5)  := "0011000000000101";
            var_insn_mem(6)  := "0011011100000000";
            var_insn_mem(7)  := "0011000110000000";
            var_insn_mem(8)  := "0011000001000000";
            var_insn_mem(9)  := "0011000100000000";
            var_insn_mem(10) := "0011001000000000";
            var_insn_mem(11) := "0011010000000000";
            var_insn_mem(12) := "0011100000000000";
            var_insn_mem(13) := "0011000000000000";
            var_insn_mem(14) := "0011000000000000";
            var_insn_mem(15) := "0011000000000000";
        
        elsif (rising_edge(clk)) then
            -- read instructions on the rising clock edge
            var_addr := conv_integer(addr_in);
            insn_out <= var_insn_mem(var_addr);
        end if;

        -- the following are probe signals (for simulation purpose)
        sig_insn_mem <= var_insn_mem;

    end process;
  
end behavioral;
