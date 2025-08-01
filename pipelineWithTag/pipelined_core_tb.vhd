library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_simple_pipeline is
end tb_simple_pipeline;

architecture behavioral of tb_simple_pipeline is
    -- Component declaration
    component pipelined_core is
        port ( 
            reset    : in  std_logic;
            clk      : in  std_logic;
            sw       : in  std_logic_vector(15 downto 0);
            led      : out std_logic_vector(15 downto 0)
        );
    end component;
    
    -- Test signals
    signal clk_tb    : std_logic := '0';
    signal reset_tb  : std_logic := '1';
    signal sw_tb     : std_logic_vector(15 downto 0) := (others => '0');
    signal led_tb    : std_logic_vector(15 downto 0);
    
    -- Clock period
    constant clk_period : time := 10 ns;
    
    -- Test tracking
    signal cycle_count : integer := 0;
    signal test_phase : integer := 0;
    
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: pipelined_core 
        port map (
            reset => reset_tb,
            clk   => clk_tb,
            sw    => sw_tb,
            led   => led_tb
        );
    
    -- Clock generation process
    clk_process: process
    begin
        clk_tb <= '0';
        wait for clk_period/2;
        clk_tb <= '1';
        wait for clk_period/2;
    end process;
    
    -- Cycle counter
    cycle_counter: process(clk_tb)
    begin
        if rising_edge(clk_tb) then
            if reset_tb = '1' then
                cycle_count <= 0;
            else
                cycle_count <= cycle_count + 1;
            end if;
        end if;
    end process;
    
    -- Main test process
    stimulus_process: process
    begin
        -- Phase 0: Reset
        test_phase <= 0;
        reset_tb <= '1';
        wait for clk_period * 4;
        
        -- Phase 1: Start pipeline execution
        test_phase <= 1;
        reset_tb <= '0';
        report "PIPELINE TEST STARTED";
        report "Expected: PC should increment 0->1->2->3->4->5 then loop 3->4->5";
        
        -- Wait for pipeline to fill
        wait for clk_period * 10;
        
        -- Phase 2: First execution
        test_phase <= 2;
        report "PHASE 2: First program execution";
        wait for clk_period * 15;
        
        -- Phase 3: Loop verification
        test_phase <= 3;
        report "PHASE 3: Branch loop should be active";
        wait for clk_period * 20;
        
        -- Phase 4: Complete
        test_phase <= 4;
        report "PHASE 4: Test completed";
        report "Check waveform for PC pattern: 0->1->2->3->4->5->3->4->5->3...";
        
        wait for clk_period * 10;
        report "SIMULATION FINISHED - Check PC behavior in waveform";
        wait;
    end process;
    
    -- Simple progress monitor
    progress_monitor: process(clk_tb)
    begin
        if rising_edge(clk_tb) and reset_tb = '0' then
            -- Report every 10 cycles
            if (cycle_count mod 10) = 0 and cycle_count > 0 then
                report "Cycle " & integer'image(cycle_count) & " - Pipeline running";
            end if;
            
            -- Key milestones
            case cycle_count is
                when 5 => report "Milestone: Pipeline should be filled";
                when 10 => report "Milestone: First instructions should complete";
                when 20 => report "Milestone: Branch loop should be established";
                when 40 => report "Milestone: Steady state operation";
                when others => null;
            end case;
        end if;
    end process;
    
end behavioral;