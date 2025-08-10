---------------------------------------------------------------------------
-- data_memory.vhd - Implementation of A Single-Port, 16 x 16-bit Data
--                   Memory.
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

entity mem is
    generic (N: integer := 16; CORE_NO: integer := 1);
    port ( clk          : in  std_logic;
           reset          : in  std_logic;
           memput       : in  std_logic;
           data1_in     : in std_logic_vector(N-1 downto 0);
           data2_in     : in std_logic_vector(N-1 downto 0) );
end mem;

architecture behavioral of mem is

type mem_array is array(0 to 2*N) of std_logic_vector(N-1 downto 0);
signal sig_data_mem : mem_array;
signal write_head : integer:= 0;

begin
    mem_process: process ( clk,
                            memput,
                            data1_in,
                            data2_in ) is
  
    variable var_data_mem : mem_array;
  
    begin
        
        if (reset = '1') then
            -- initial values of the data memory : reset to zero 
            var_data_mem := (others => (others => '0'));

        elsif (falling_edge(clk) and memput = '1') then
            -- memory writes on the falling clock edge
            var_data_mem(write_head) := data1_in;
            var_data_mem(write_head + 1) := data2_in;
            write_head <= write_head + 2;

        end if;
 
        -- the following are probe signals (for simulation purpose) 
        sig_data_mem <= var_data_mem;

    end process;
  
end behavioral;
