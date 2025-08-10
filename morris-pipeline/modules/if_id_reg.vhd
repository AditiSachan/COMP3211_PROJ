library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity if_id_reg is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        stall       : in  STD_LOGIC;
        flush       : in  STD_LOGIC;
        if_instruction : in  STD_LOGIC_VECTOR(15 downto 0);
        if_pc_plus_one : in  STD_LOGIC_VECTOR(15 downto 0);
        id_instruction : out STD_LOGIC_VECTOR(15 downto 0);
        id_pc_plus_one : out STD_LOGIC_VECTOR(15 downto 0)
    );
end if_id_reg;

architecture Behavioral of if_id_reg is

    -- Internal registers to store pipeline data
    signal instruction_reg : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal pc_plus_one_reg : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

begin

    -- Pipeline Register Update Process
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset all pipeline registers to 0
            instruction_reg <= (others => '0');
            pc_plus_one_reg <= (others => '0');
            
        elsif rising_edge(clk) then
            if flush = '1' then
                -- Flush pipeline stage (insert bubble/NOP)
                instruction_reg <= "1111000000000000"; -- NOP instruction
                pc_plus_one_reg <= (others => '0');
                
            elsif stall = '0' then
                -- Normal operation: pass data through
                instruction_reg <= if_instruction;
                pc_plus_one_reg <= if_pc_plus_one;
                
            -- If stall = '1', registers hold their current values
            end if;
        end if;
    end process;

    -- Output Assignments
    id_instruction <= instruction_reg;
    id_pc_plus_one <= pc_plus_one_reg;

end Behavioral;