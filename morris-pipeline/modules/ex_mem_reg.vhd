library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ex_mem_reg is
    Port (
        clk             : in  STD_LOGIC;
        reset           : in  STD_LOGIC;
        
        -- EX stage inputs
        ex_alu_result   : in  STD_LOGIC_VECTOR(15 downto 0);
        ex_rt_data      : in  STD_LOGIC_VECTOR(15 downto 0);
        ex_rd_addr      : in  STD_LOGIC_VECTOR(2 downto 0);
        ex_validation   : in  STD_LOGIC;
        ex_reg_write    : in  STD_LOGIC;
        ex_mem_read     : in  STD_LOGIC;
        ex_mem_write    : in  STD_LOGIC;
        
        -- MEM stage outputs
        mem_alu_result  : out STD_LOGIC_VECTOR(15 downto 0);
        mem_rt_data     : out STD_LOGIC_VECTOR(15 downto 0);
        mem_rd_addr     : out STD_LOGIC_VECTOR(2 downto 0);
        mem_validation  : out STD_LOGIC;
        mem_reg_write   : out STD_LOGIC;
        mem_mem_read    : out STD_LOGIC;
        mem_mem_write   : out STD_LOGIC
    );
end ex_mem_reg;

architecture Behavioral of ex_mem_reg is

    -- Internal registers to store pipeline data
    signal alu_result_reg   : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal rt_data_reg      : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal rd_addr_reg      : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal validation_reg   : STD_LOGIC := '0';
    
    -- Control signal registers
    signal reg_write_reg    : STD_LOGIC := '0';
    signal mem_read_reg     : STD_LOGIC := '0';
    signal mem_write_reg    : STD_LOGIC := '0';

begin

    -- Pipeline Register Update Process
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset all pipeline registers to safe defaults
            alu_result_reg <= (others => '0');
            rt_data_reg <= (others => '0');
            rd_addr_reg <= (others => '0');
            validation_reg <= '0';
            
            -- Reset control signals (disable all operations)
            reg_write_reg <= '0';
            mem_read_reg <= '0';
            mem_write_reg <= '0';
            
        elsif rising_edge(clk) then
            -- Normal operation: pass data from EX to MEM
            -- No stall logic needed here as stalls are handled earlier
            alu_result_reg <= ex_alu_result;
            rt_data_reg <= ex_rt_data;
            rd_addr_reg <= ex_rd_addr;
            validation_reg <= ex_validation;
            
            -- Pass control signals
            reg_write_reg <= ex_reg_write;
            mem_read_reg <= ex_mem_read;
            mem_write_reg <= ex_mem_write;
        end if;
    end process;

    -- Output Assignments
    mem_alu_result <= alu_result_reg;
    mem_rt_data <= rt_data_reg;
    mem_rd_addr <= rd_addr_reg;
    mem_validation <= validation_reg;
    mem_reg_write <= reg_write_reg;
    mem_mem_read <= mem_read_reg;
    mem_mem_write <= mem_write_reg;

end Behavioral;