library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity id_ex_reg is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        stall       : in  STD_LOGIC;
        
        -- ID stage inputs
        id_opcode       : in  STD_LOGIC_VECTOR(3 downto 0);
        id_rs_addr      : in  STD_LOGIC_VECTOR(2 downto 0);
        id_rt_addr      : in  STD_LOGIC_VECTOR(2 downto 0);
        id_rd_addr      : in  STD_LOGIC_VECTOR(2 downto 0);
        id_rs_data      : in  STD_LOGIC_VECTOR(15 downto 0);
        id_rt_data      : in  STD_LOGIC_VECTOR(15 downto 0);
        id_immediate    : in  STD_LOGIC_VECTOR(8 downto 0);
        id_reg_write    : in  STD_LOGIC;
        id_mem_read     : in  STD_LOGIC;
        id_mem_write    : in  STD_LOGIC;
        id_alu_src      : in  STD_LOGIC;
        
        -- EX stage outputs
        ex_opcode       : out STD_LOGIC_VECTOR(3 downto 0);
        ex_rs_addr      : out STD_LOGIC_VECTOR(2 downto 0);
        ex_rt_addr      : out STD_LOGIC_VECTOR(2 downto 0);
        ex_rd_addr      : out STD_LOGIC_VECTOR(2 downto 0);
        ex_rs_data      : out STD_LOGIC_VECTOR(15 downto 0);
        ex_rt_data      : out STD_LOGIC_VECTOR(15 downto 0);
        ex_immediate    : out STD_LOGIC_VECTOR(8 downto 0);
        ex_reg_write    : out STD_LOGIC;
        ex_mem_read     : out STD_LOGIC;
        ex_mem_write    : out STD_LOGIC;
        ex_alu_src      : out STD_LOGIC
    );
end id_ex_reg;

architecture Behavioral of id_ex_reg is

    -- Internal registers to store pipeline data
    signal opcode_reg       : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal rs_addr_reg      : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal rt_addr_reg      : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal rd_addr_reg      : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal rs_data_reg      : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal rt_data_reg      : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal immediate_reg    : STD_LOGIC_VECTOR(8 downto 0) := (others => '0');
    
    -- Control signal registers
    signal reg_write_reg    : STD_LOGIC := '0';
    signal mem_read_reg     : STD_LOGIC := '0';
    signal mem_write_reg    : STD_LOGIC := '0';
    signal alu_src_reg      : STD_LOGIC := '0';

begin

    -- Pipeline Register Update Process
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset all pipeline registers to safe defaults
            opcode_reg <= "1111";       -- NOP opcode
            rs_addr_reg <= (others => '0');
            rt_addr_reg <= (others => '0');
            rd_addr_reg <= (others => '0');
            rs_data_reg <= (others => '0');
            rt_data_reg <= (others => '0');
            immediate_reg <= (others => '0');
            
            -- Reset control signals (disable all operations)
            reg_write_reg <= '0';
            mem_read_reg <= '0';
            mem_write_reg <= '0';
            alu_src_reg <= '0';
            
        elsif rising_edge(clk) then
            if stall = '0' then
                -- Normal operation: pass data from ID to EX
                opcode_reg <= id_opcode;
                rs_addr_reg <= id_rs_addr;
                rt_addr_reg <= id_rt_addr;
                rd_addr_reg <= id_rd_addr;
                rs_data_reg <= id_rs_data;
                rt_data_reg <= id_rt_data;
                immediate_reg <= id_immediate;
                
                -- Pass control signals
                reg_write_reg <= id_reg_write;
                mem_read_reg <= id_mem_read;
                mem_write_reg <= id_mem_write;
                alu_src_reg <= id_alu_src;
                
            else
                -- Stall condition: insert NOP to prevent unwanted operations
                -- This is crucial when tag generation is busy
                opcode_reg <= "1111";       -- NOP opcode
                reg_write_reg <= '0';       -- Disable register write
                mem_read_reg <= '0';        -- Disable memory read
                mem_write_reg <= '0';       -- Disable memory write
                
                -- Keep address and data registers unchanged for debugging
                -- rs_addr_reg, rt_addr_reg, rd_addr_reg hold previous values
                -- rs_data_reg, rt_data_reg hold previous values
                -- immediate_reg holds previous value
                -- alu_src_reg holds previous value
            end if;
        end if;
    end process;

    -- Output Assignments
    ex_opcode <= opcode_reg;
    ex_rs_addr <= rs_addr_reg;
    ex_rt_addr <= rt_addr_reg;
    ex_rd_addr <= rd_addr_reg;
    ex_rs_data <= rs_data_reg;
    ex_rt_data <= rt_data_reg;
    ex_immediate <= immediate_reg;
    ex_reg_write <= reg_write_reg;
    ex_mem_read <= mem_read_reg;
    ex_mem_write <= mem_write_reg;
    ex_alu_src <= alu_src_reg;

end Behavioral;