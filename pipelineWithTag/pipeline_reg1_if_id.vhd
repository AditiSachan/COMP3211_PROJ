
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pipeline_reg1_if_id is
    port (
           clk          : in  std_logic;
           sync_reset   : in std_logic;
           next_pc_in   : in  std_logic_vector(3 downto 0);
           insn_in      : in  std_logic_vector(15 downto 0);
           next_pc_out  : out std_logic_vector(3 downto 0);
           insn_out     : out  std_logic_vector(15 downto 0));
end pipeline_reg1_if_id;

architecture behavioral of pipeline_reg1_if_id is
begin
    update_process: process ( sync_reset, clk ) is
    begin
        if (rising_edge(clk)) then
            if (sync_reset = '1') then
                next_pc_out <= (others => '0');
                insn_out <= (others => '0');
            else
                next_pc_out <= next_pc_in;
                insn_out <= insn_in;
            end if;
       end if;
    end process;
end behavioral;
