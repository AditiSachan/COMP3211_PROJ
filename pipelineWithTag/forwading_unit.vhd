
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity forwarding_unit is
    port ( ex_rs        : in std_logic_vector(3 downto 0);
           ex_rt        : in std_logic_vector(3 downto 0);
           mem_regwrite : in std_logic;
           mem_regwrite2 : in std_logic;
           mem_rd       : in std_logic_vector(3 downto 0);
           mem_rd2       : in std_logic_vector(3 downto 0);
           wb_regwrite : in std_logic;
           wb_regwrite2 : in std_logic;
           wb_rd       : in std_logic_vector(3 downto 0);
           wb_rd2       : in std_logic_vector(3 downto 0);
           alu_srcA    : out std_logic_vector(2 downto 0);
           alu_srcB    : out std_logic_vector(2 downto 0));
end forwarding_unit;

architecture behavioural of forwarding_unit is

begin

    mux_ctr: process (ex_rs, ex_rt, mem_regwrite, mem_regwrite2, mem_rd, mem_rd2, wb_regwrite, wb_regwrite2, wb_rd, wb_rd2) is
    begin

        if (mem_regwrite = '1' and mem_rd = ex_rs) then
            alu_srcA <= "001";
        elsif (mem_regwrite2 = '1' and mem_rd2 = ex_rs) then
            alu_srcA <= "010";
        elsif (wb_regwrite = '1' and wb_rd = ex_rs) then
            alu_srcA <= "011";
        elsif (wb_regwrite2 = '1' and wb_rd2 = ex_rs) then
            alu_srcA <= "100";
        else 
            alu_srcA <= "000";
        end if;


        if (mem_regwrite = '1' and mem_rd = ex_rt) then
            alu_srcB <= "001";
        elsif (mem_regwrite2 = '1' and mem_rd2 = ex_rt) then
            alu_srcB <= "010";
        elsif (wb_regwrite = '1' and wb_rd = ex_rt) then
            alu_srcB <= "011";
        elsif (wb_regwrite2 = '1' and wb_rd2 = ex_rt) then
            alu_srcB <= "100";
        else 
            alu_srcB <= "000";
        end if;

    end process;

end behavioural;


 