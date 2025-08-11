library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.Numeric_Std.ALL;

entity asp_simple is
    generic ( N  : integer := 16;
              T  : integer := 4;
              BF : integer := 1;      
              R  : integer := 2 );
    port ( reset                : in  std_logic;
           clk                  : in  std_logic ;
           -- Single election record input
           election_record_in   : in std_logic_vector(N-1 downto 0);
           record_enable        : in std_logic;
           -- Outputs
           ackn_data            : out std_logic_vector(N-1 downto 0);
           election_total_0     : out std_logic_vector(7 downto 0);
           election_total_1     : out std_logic_vector(7 downto 0);
           election_total_2     : out std_logic_vector(7 downto 0);
           election_total_3     : out std_logic_vector(7 downto 0) );
end asp_simple;

architecture structural of asp_simple is
    
    -- Use renamed buffer component
    component election_buffer is
        generic ( N: integer := 16;
                  M: integer := 8 );
        port (  reset       : in std_logic;
                clk         : in std_logic;
                value1_in   : in std_logic_vector(N-1 downto 0);
                value2_in   : in std_logic_vector(M-1 downto 0);
                bufget      : in std_logic;
                value1_out  : out std_logic_vector(N-1 downto 0);
                value2_out  : out std_logic_vector(N-1 downto 0) );
    end component;    
    
    component core_election is
        generic ( N        : integer := 16;
                  T        : integer := 4;
                  CORE_NO  : integer := 1;
                  BF       : integer := 1;      
                  R        : integer := 2 );
        port ( reset         : in  std_logic;
               clk           : in  std_logic; 
               bufget        : out std_logic;
               buf_value1    : in std_logic_vector(N-1 downto 0);
               buf_value2    : in std_logic_vector(N-1 downto 0);
               ackn_data     : out std_logic_vector(N-1 downto 0);
               total_candidate_0 : out std_logic_vector(7 downto 0);
               total_candidate_1 : out std_logic_vector(7 downto 0);
               total_candidate_2 : out std_logic_vector(7 downto 0);
               total_candidate_3 : out std_logic_vector(7 downto 0) );
    end component;
    
    -- Internal signals
    signal sig_bufget                        : std_logic;
    signal sig_record_data                   : std_logic_vector(N-1 downto 0);
    signal sig_enable_data                   : std_logic_vector(N-1 downto 0);
    signal sig_enable_vector                 : std_logic_vector(0 downto 0);
    
begin
    
    -- Convert single bit enable to vector
    sig_enable_vector(0) <= record_enable;
    
    -- Single buffer for election records
    buffer1 : election_buffer
    generic map (N => N, M => 1) 
    port map (
        reset => reset,
        clk => clk,
        value1_in => election_record_in,     -- Election record input
        value2_in => sig_enable_vector,      -- Enable signal
        bufget => sig_bufget,                -- Request from core
        value1_out => sig_record_data,       -- Buffered data to core
        value2_out => sig_enable_data        -- Buffered enable to core
    );
    
    -- Single core for election processing
    election_core : core_election
    generic map (N => N, T => T, CORE_NO => 1, BF => BF, R => R)
    port map (
        reset  => reset,
        clk    => clk,
        bufget => sig_bufget,                -- Request data from buffer
        buf_value1 => sig_record_data,       -- Election record data
        buf_value2 => sig_enable_data,       -- Enable/control data
        ackn_data => ackn_data,              -- Acknowledgment output
        -- Election tallies
        total_candidate_0 => election_total_0,
        total_candidate_1 => election_total_1,
        total_candidate_2 => election_total_2,
        total_candidate_3 => election_total_3
    );
    
end structural;