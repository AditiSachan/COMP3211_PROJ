library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mem_wb_reg is
    Port (
        clk             : in  STD_LOGIC;
        reset           : in  STD_LOGIC;
        
        -- MEM stage inputs
        mem_alu_result  : in  STD_LOGIC_VECTOR(15 downto 0);
        mem_read_data   : in  STD_LOGIC_VECTOR(15 downto 0);
        mem_rd_addr     : in  STD_LOGIC_VECTOR(2 downto 0);
        mem_reg_write   : in  STD_LOGIC;
        
        -- WB stage outputs
        wb_alu_result   : out STD_LOGIC_VECTOR(15 downto 0);
        wb_read_data    : out STD_LOGIC_VECTOR(15 downto 0);
        wb_rd_addr      : out STD_LOGIC_VECTOR(2 downto 0);
        wb_reg_write    : out STD_LOGIC
    );
end mem_wb_reg;

architecture Behavioral of mem_wb_reg is

    -- Internal registers to store pipeline data
    signal alu_result_reg   : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal read_data_reg    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal rd_addr_reg      : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    
    -- Control signal register
    signal reg_write_reg    : STD_LOGIC := '0';

begin

    -- Pipeline Register Update Process
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset all pipeline registers to safe defaults
            alu_result_reg <= (others => '0');
            read_data_reg <= (others => '0');
            rd_addr_reg <= (others => '0');
            
            -- Reset control signal (disable register write)
            reg_write_reg <= '0';
            
        elsif rising_edge(clk) then
            -- Normal operation: pass data from MEM to WB
            -- No stall logic needed - this is the final pipeline stage
            alu_result_reg <= mem_alu_result;
            read_data_reg <= mem_read_data;
            rd_addr_reg <= mem_rd_addr;
            
            -- Pass control signal
            reg_write_reg <= mem_reg_write;
        end if;
    end process;

    -- Output Assignments
    wb_alu_result <= alu_result_reg;
    wb_read_data <= read_data_reg;
    wb_rd_addr <= rd_addr_reg;
    wb_reg_write <= reg_write_reg;

end Behavioral;