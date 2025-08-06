library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_enhanced_pipeline is
end tb_enhanced_pipeline;

architecture Behavioral of tb_enhanced_pipeline is
    -- Component declaration
    component pipelined_core is
        port (
            reset : in std_logic;
            clk   : in std_logic;
            sw    : in std_logic_vector(15 downto 0);
            led   : out std_logic_vector(15 downto 0)
        );
    end component;

    -- Test signals
    signal clk_tb    : std_logic := '0';
    signal reset_tb  : std_logic := '1';
    signal sw_tb     : std_logic_vector(15 downto 0) := (others => '0');
    signal led_tb    : std_logic_vector(15 downto 0);

    -- Clock period
    constant clk_period : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: pipelined_core
        port map (
            reset => reset_tb,
            clk   => clk_tb,
            sw    => sw_tb,
            led   => led_tb
        );

    -- Clock Generation process
    clk_process: process
    begin
        while true loop
            clk_tb <= '0';
            wait for clk_period / 2;
            clk_tb <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    -- Stimulus Process
    stimulus: process
    begin
        -- Initial Reset
        reset_tb <= '1';
        wait for clk_period * 4;
        reset_tb <= '0';

        -- Apply vote record 1 (Dist 1, Cand 2, +1 vote, valid tag)
        sw_tb <= "0100100000011001";  -- Example input with hypothetical tag
        wait for clk_period * 1;

        -- Apply vote record 2 (Dist 2, Cand 3, +2 vote, valid tag)
        sw_tb <= "1000110000101010";  -- Another example
        wait for clk_period * 1;

        -- Apply vote record 3 (Dist 1, Cand 2, +5 vote, invalid tag)
        sw_tb <= "0100100001010000";  -- Should not update tally
        wait for clk_period * 1;

        -- Continue clock cycles for pipeline to process
        wait for clk_period * 20;

        -- Simulation end
        report "Testbench finished. Check LED output and waveform.";
        wait;
    end process;

end Behavioral;
