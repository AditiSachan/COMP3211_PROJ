library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.Numeric_Std.ALL;

entity asp_no_buffer is
    generic ( N  : integer := 16;
              T  : integer := 8;
              BF : integer := 1;      
              R  : integer := 2 );
    port ( reset                : in  std_logic;
           clk                  : in  std_logic ;
           election_record_in   : in std_logic_vector(N-1 downto 0);
           record_enable        : in std_logic;
           ackn_data            : out std_logic_vector(N-1 downto 0);
           election_total_0     : out std_logic_vector(7 downto 0);
           election_total_1     : out std_logic_vector(7 downto 0);
           election_total_2     : out std_logic_vector(7 downto 0);
           election_total_3     : out std_logic_vector(7 downto 0) );
end asp_no_buffer;

architecture structural of asp_no_buffer is
    
    component core_election is
        generic ( N, T, CORE_NO, BF, R : integer );
        port ( reset, clk : in std_logic; 
               bufget : out std_logic;
               buf_value1, buf_value2 : in std_logic_vector(N-1 downto 0);
               ackn_data : out std_logic_vector(N-1 downto 0);
               total_candidate_0, total_candidate_1, 
               total_candidate_2, total_candidate_3 : out std_logic_vector(7 downto 0) );
    end component;
    
    signal sig_enable_vector : std_logic_vector(N-1 downto 0);
    signal sig_bufget : std_logic;
    
begin
    
    -- Convert enable signal to vector format
    sig_enable_vector <= (0 => record_enable, others => '0');
    
    -- Direct connection - no buffer
    election_center : core_election
    generic map (N => N, T => T, CORE_NO => 1, BF => BF, R => R ) 
    port map (
        reset  => reset,
        clk    => clk,
        bufget => sig_bufget,  -- Not used
        buf_value1 => election_record_in,     -- Direct connection
        buf_value2 => sig_enable_vector,      -- Enable as vector
        ackn_data => ackn_data,
        total_candidate_0 => election_total_0,
        total_candidate_1 => election_total_1,
        total_candidate_2 => election_total_2,
        total_candidate_3 => election_total_3 );
        
end structural;