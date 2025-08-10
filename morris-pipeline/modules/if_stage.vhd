library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity if_stage is
    Port (
        clk             : in  STD_LOGIC;
        reset           : in  STD_LOGIC;
        pc_enable       : in  STD_LOGIC;
        branch_target   : in  STD_LOGIC_VECTOR(15 downto 0);
        branch_taken    : in  STD_LOGIC;
        instruction     : out STD_LOGIC_VECTOR(15 downto 0);
        pc_plus_one     : out STD_LOGIC_VECTOR(15 downto 0)
    );
end if_stage;

architecture Behavioral of if_stage is

    -- Component Declaration for Instruction Memory
    component instruction_memory is
        Port (
            address     : in  STD_LOGIC_VECTOR(15 downto 0);
            instruction : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    -- Component Declaration for PC Unit
    component pc_unit is
        Port (
            clk             : in  STD_LOGIC;
            reset           : in  STD_LOGIC;
            pc_enable       : in  STD_LOGIC;
            branch_target   : in  STD_LOGIC_VECTOR(15 downto 0);
            branch_taken    : in  STD_LOGIC;
            pc_out          : out STD_LOGIC_VECTOR(15 downto 0);
            pc_plus_one     : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    -- Internal Signals
    signal pc_current : STD_LOGIC_VECTOR(15 downto 0);

begin

    -- Instantiate PC Unit
    PC_UNIT_INST: pc_unit
        port map (
            clk => clk,
            reset => reset,
            pc_enable => pc_enable,
            branch_target => branch_target,
            branch_taken => branch_taken,
            pc_out => pc_current,
            pc_plus_one => pc_plus_one
        );

    -- Instantiate Instruction Memory
    INST_MEM: instruction_memory
        port map (
            address => pc_current,
            instruction => instruction
        );

end Behavioral;


-- PC Unit Implementation
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pc_unit is
    Port (
        clk             : in  STD_LOGIC;
        reset           : in  STD_LOGIC;
        pc_enable       : in  STD_LOGIC;
        branch_target   : in  STD_LOGIC_VECTOR(15 downto 0);
        branch_taken    : in  STD_LOGIC;
        pc_out          : out STD_LOGIC_VECTOR(15 downto 0);
        pc_plus_one     : out STD_LOGIC_VECTOR(15 downto 0)
    );
end pc_unit;

architecture Behavioral of pc_unit is
    signal pc_reg : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal pc_next : STD_LOGIC_VECTOR(15 downto 0);
begin

    -- PC Next Logic
    process(pc_reg, branch_taken, branch_target)
    begin
        if branch_taken = '1' then
            pc_next <= branch_target;
        else
            pc_next <= std_logic_vector(unsigned(pc_reg) + 1);
        end if;
    end process;

    -- PC Register Update
    process(clk, reset)
    begin
        if reset = '1' then
            pc_reg <= (others => '0');
        elsif rising_edge(clk) then
            if pc_enable = '1' then
                pc_reg <= pc_next;
            end if;
            -- If pc_enable = '0', PC holds current value (stall)
        end if;
    end process;

    -- Output Assignments
    pc_out <= pc_reg;
    pc_plus_one <= std_logic_vector(unsigned(pc_reg) + 1);

end Behavioral;


-- Instruction Memory Implementation
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity instruction_memory is
    Port (
        address     : in  STD_LOGIC_VECTOR(15 downto 0);
        instruction : out STD_LOGIC_VECTOR(15 downto 0)
    );
end instruction_memory;

architecture Behavioral of instruction_memory is
    
    -- Instruction Memory Array (256 instructions max for demo)
    type instruction_array is array (0 to 255) of STD_LOGIC_VECTOR(15 downto 0);
    
    -- Sample Program for Election Processing
    signal inst_mem : instruction_array := (
        -- Address 0: Load input record
        0 => "0000001000000000",  -- LOAD_INPUT R1 (load 16-bit input to R1)
        
        -- Address 1-4: Extract fields from input
        1 => "0001010000000001",  -- EXTRACT R2, 01 (extract tally to R2)
        2 => "0001011000000010",  -- EXTRACT R3, 10 (extract candidate to R3)  
        3 => "0001100000000011",  -- EXTRACT R4, 11 (extract district to R4)
        4 => "0001101000000000",  -- EXTRACT R5, 00 (extract received tag to R5)
        
        -- Address 5: Generate tag from record data
        5 => "0010001000110000",  -- GEN_TAG R1, R6 (generate tag to R6)
        
        -- Address 6: Validate tags
        6 => "0011110101111000",  -- VALIDATE R6, R5, R7 (compare tags, result to R7)
        
        -- Address 7: Branch if invalid (skip tally update)
        7 => "1000111000001111",  -- BRANCH_VALID R7, 15 (branch to end if invalid)
        
        -- Address 8: Calculate tally table address
        8 => "0100011100001000",  -- CALC_ADDR R3, R4, R1 (candidate*5 + district to R1)
        
        -- Address 9: Read current tally
        9 => "0101010000000000",  -- READ_TALLY R2, R1 (read current tally to R2)
        
        -- Address 10: Add incremental tally  
        10 => "0111010010010000", -- ADD R2, R2, R2 (add incremental to current)
        
        -- Address 11: Write back updated tally
        11 => "0110010000000000", -- WRITE_TALLY R2, R1 (write updated tally)
        
        -- Address 12: Calculate candidate total address  
        12 => "0100011000001000", -- CALC_ADDR R3, R0+4, R1 (candidate total address)
        
        -- Address 13: Read candidate total
        13 => "0101011000000000", -- READ_TALLY R3, R1 (read current total)
        
        -- Address 14: Add to total
        14 => "0111011010011000", -- ADD R3, R2, R3 (add increment to total)
        
        -- Address 15: Write back total
        15 => "0110011000000000", -- WRITE_TALLY R3, R1 (write updated total)
        
        -- Address 16: End/Loop back
        16 => "1110000000000000", -- BEQ R0, 0 (loop back to start)
        
        others => "1111000000000000" -- NOP for unused addresses
    );

begin

    -- Asynchronous read from instruction memory
    process(address)
        variable addr_int : integer;
    begin
        addr_int := to_integer(unsigned(address));
        if addr_int < 256 then
            instruction <= inst_mem(addr_int);
        else
            instruction <= "1111000000000000"; -- NOP for out-of-bounds
        end if;
    end process;

end Behavioral;