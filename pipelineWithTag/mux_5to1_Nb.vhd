---------------------------------------------------------------------------
-- mux_2to1_16b.vhd - 16-bit 2-to-1 Multiplexer Implementation
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

entity mux_5to1_Nb is
    generic (N: integer := 16);
    port ( mux_select : in  std_logic_vector(2 downto 0);
           data_a     : in  std_logic_vector(N-1 downto 0);
           data_b     : in  std_logic_vector(N-1 downto 0);
           data_c     : in  std_logic_vector(N-1 downto 0);
           data_d     : in  std_logic_vector(N-1 downto 0);
           data_e     : in  std_logic_vector(N-1 downto 0);
           data_out   : out std_logic_vector(N-1 downto 0) );
end mux_5to1_Nb;

architecture behavioral of mux_5to1_Nb is

begin
    mux_process : process (mux_select, data_a, data_b, data_c, data_d, data_e) is
    begin
        case mux_select is
            when "000" =>
                data_out <= data_a;
            when "001" =>
                data_out <= data_b;
            when "010" =>
                data_out <= data_c;
            when "011" =>
                data_out <= data_d;
            when "100" =>
                data_out <= data_e;
            when others =>
                data_out <= data_a;
        end case;
    end process;
end behavioral;
