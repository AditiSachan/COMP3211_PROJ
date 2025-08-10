library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity wb_stage is
    Port (
        mem_to_reg      : in  STD_LOGIC;
        alu_result      : in  STD_LOGIC_VECTOR(15 downto 0);
        mem_data        : in  STD_LOGIC_VECTOR(15 downto 0);
        writeback_data  : out STD_LOGIC_VECTOR(15 downto 0)
    );
end wb_stage;

architecture Behavioral of wb_stage is

    -- Component Declaration for Writeback Multiplexer
    component writeback_mux is
        Port (
            mem_to_reg      : in  STD_LOGIC;
            alu_result      : in  STD_LOGIC_VECTOR(15 downto 0);
            mem_data        : in  STD_LOGIC_VECTOR(15 downto 0);
            writeback_data  : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

begin

    -- Instantiate Writeback Multiplexer
    WB_MUX: writeback_mux
        port map (
            mem_to_reg => mem_to_reg,
            alu_result => alu_result,
            mem_data => mem_data,
            writeback_data => writeback_data
        );

end Behavioral;


-- Writeback Multiplexer Implementation
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity writeback_mux is
    Port (
        mem_to_reg      : in  STD_LOGIC;
        alu_result      : in  STD_LOGIC_VECTOR(15 downto 0);
        mem_data        : in  STD_LOGIC_VECTOR(15 downto 0);
        writeback_data  : out STD_LOGIC_VECTOR(15 downto 0)
    );
end writeback_mux;

architecture Behavioral of writeback_mux is
begin

    -- Writeback Data Selection
    process(mem_to_reg, alu_result, mem_data)
    begin
        if mem_to_reg = '1' then
            writeback_data <= mem_data;     -- Write back memory data (for load instructions)
        else
            writeback_data <= alu_result;   -- Write back ALU result (for compute instructions)
        end if;
    end process;

end Behavioral;