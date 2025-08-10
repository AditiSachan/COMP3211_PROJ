library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity forwarding_unit is
    Port (
        -- Current instruction register addresses (from ID/EX register)
        id_ex_rs        : in  STD_LOGIC_VECTOR(2 downto 0);
        id_ex_rt        : in  STD_LOGIC_VECTOR(2 downto 0);
        
        -- Previous instruction information
        ex_mem_rd       : in  STD_LOGIC_VECTOR(2 downto 0);
        ex_mem_reg_write: in  STD_LOGIC;
        mem_wb_rd       : in  STD_LOGIC_VECTOR(2 downto 0);
        mem_wb_reg_write: in  STD_LOGIC;
        
        -- Forwarding control signals
        forward_a       : out STD_LOGIC_VECTOR(1 downto 0);
        forward_b       : out STD_LOGIC_VECTOR(1 downto 0)
    );
end forwarding_unit;

architecture Behavioral of forwarding_unit is
begin

    -- Forwarding Logic for Operand A (Rs)
    process(id_ex_rs, ex_mem_rd, ex_mem_reg_write, mem_wb_rd, mem_wb_reg_write)
    begin
        -- Default: no forwarding
        forward_a <= "00";
        
        -- EX/MEM stage forwarding (higher priority - more recent)
        if (ex_mem_reg_write = '1') and 
           (ex_mem_rd /= "000") and 
           (ex_mem_rd = id_ex_rs) then
            forward_a <= "10"; -- Forward from MEM stage
            
        -- MEM/WB stage forwarding (lower priority - less recent)
        elsif (mem_wb_reg_write = '1') and 
              (mem_wb_rd /= "000") and 
              (mem_wb_rd = id_ex_rs) then
            forward_a <= "01"; -- Forward from WB stage
        end if;
    end process;

    -- Forwarding Logic for Operand B (Rt)
    process(id_ex_rt, ex_mem_rd, ex_mem_reg_write, mem_wb_rd, mem_wb_reg_write)
    begin
        -- Default: no forwarding
        forward_b <= "00";
        
        -- EX/MEM stage forwarding (higher priority - more recent)
        if (ex_mem_reg_write = '1') and 
           (ex_mem_rd /= "000") and 
           (ex_mem_rd = id_ex_rt) then
            forward_b <= "10"; -- Forward from MEM stage
            
        -- MEM/WB stage forwarding (lower priority - less recent)
        elsif (mem_wb_reg_write = '1') and 
              (mem_wb_rd /= "000") and 
              (mem_wb_rd = id_ex_rt) then
            forward_b <= "01"; -- Forward from WB stage
        end if;
    end process;

end Behavioral;