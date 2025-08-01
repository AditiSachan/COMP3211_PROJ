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
use IEEE.NUMERIC_STD.ALL;

entity data_memory is
    port ( reset        : in  std_logic;
           clk          : in  std_logic;
           write_enable : in  std_logic;
           write_data   : in  std_logic_vector(15 downto 0);
           addr_in      : in  std_logic_vector(3 downto 0);
           data_out     : out std_logic_vector(15 downto 0) );
end data_memory;

architecture behavioral of data_memory is
    type mem_array is array(0 to 15) of std_logic_vector(15 downto 0);
    signal memory : mem_array;
begin
    process (clk, reset)
        variable addr : integer;
    begin
        addr := to_integer(unsigned(addr_in));
        if reset = '1' then
            -- Initialize all memory to zero
            for i in 0 to 15 loop
                memory(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            if write_enable = '1' then
                memory(addr) <= write_data;
            end if;
            data_out <= memory(addr);
        end if;
    end process;
end behavioral;

