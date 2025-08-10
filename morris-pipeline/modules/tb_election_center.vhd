-- tb_election_center.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_election_center is end tb_election_center;

architecture sim of tb_election_center is
  -- Clock period
  constant CLK_PERIOD : time := 1000 ns;
  
  -- Timing constants for pipelined processor
  constant RESET_TIME : time := CLK_PERIOD * 20;     -- Long reset for pipeline initialization
  constant PROCESS_TIME : time := CLK_PERIOD * 50;   -- Time to complete full program (50 cycles)
  constant SETTLE_TIME : time := CLK_PERIOD * 10;    -- Time between tests
  
  -- Test input constants (tag|tally|candidate|district format)
  constant TEST1_INPUT : integer := 16#F000#;  -- tag=1111, tally=0,   cand=0, dist=0
  constant TEST2_INPUT : integer := 16#5567#;  -- tag=0101, tally=86,  cand=1, dist=3  
  constant TEST3_INPUT : integer := 16#B001#;  -- tag=1011, tally=0,   cand=0, dist=1
  constant TEST4_INPUT : integer := 16#55A5#;  -- tag=0101, tally=90,  cand=1, dist=1
  constant TEST5_INPUT : integer := 16#8FFF#;  -- tag=1000, tally=255, cand=3, dist=3

  -- Signals
  signal clk         : std_logic := '0';
  signal reset       : std_logic := '1';
  signal input_data  : std_logic_vector(15 downto 0);
  signal output_data : std_logic_vector(15 downto 0);

  component election_center
    port (
      clk         : in  std_logic;
      reset       : in  std_logic;
      input_data  : in  std_logic_vector(15 downto 0);
      output_data : out std_logic_vector(15 downto 0)
    );
  end component;

begin
  dut: election_center
    port map (
      clk         => clk,
      reset       => reset,
      input_data  => input_data,
      output_data => output_data
    );

  -- Clock generation
  clk <= not clk after CLK_PERIOD/2;

  stim: process
  begin
    -- Extended reset phase for pipelined processor
    reset <= '1';
    input_data <= (others => '0');
    wait for RESET_TIME;          -- 20 cycles for pipeline to clear
    reset <= '0';
    wait for SETTLE_TIME;         -- 10 cycles for startup
    
    -- Test 1: District 0, Candidate 0, Tally 0, Tag 1111
    -- Keep input stable while processor runs its full program
    input_data <= std_logic_vector(to_unsigned(TEST1_INPUT, 16));
    wait for PROCESS_TIME;        -- 50 cycles for complete processing
    
    -- Test 2: District 3, Candidate 1, Tally 86, Tag 0101  
    input_data <= std_logic_vector(to_unsigned(TEST2_INPUT, 16));
    wait for PROCESS_TIME;
    
    -- Test 3: District 1, Candidate 0, Tally 0, Tag 1011
    input_data <= std_logic_vector(to_unsigned(TEST3_INPUT, 16));
    wait for PROCESS_TIME;
    
    -- Test 4: District 1, Candidate 1, Tally 90, Tag 0101
    input_data <= std_logic_vector(to_unsigned(TEST4_INPUT, 16));
    wait for PROCESS_TIME;
    
    -- Test 5: District 3, Candidate 3, Tally 255, Tag 1000
    input_data <= std_logic_vector(to_unsigned(TEST5_INPUT, 16));
    wait for PROCESS_TIME;
    
    -- Final observation period
    input_data <= (others => '0');
    wait for PROCESS_TIME;        -- Let final processing complete
    
    wait;
  end process;

end architecture;