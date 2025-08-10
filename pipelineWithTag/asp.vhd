library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.Numeric_Std.ALL;

entity asp is
    generic ( N  : integer := 16;
              T  : integer := 8;
              BF : integer := 1;      -- Provide default values
              R  : integer := 2 );
    port ( reset                : in  std_logic;
           clk                  : in  std_logic ;
           compsysdata_in       : in std_logic_vector(N-1 downto 0);
           compsyspar_in        : in std_logic;
           networkdata_in       : in std_logic_vector(N-1 downto 0);
           networktag_in        : in std_logic_vector(T-1 downto 0);
           compsys_ackndata     : out std_logic_vector(N-1 downto 0);
           network_ackndata     : out std_logic_vector(N-1 downto 0);
           -- NEW: Election outputs
           election_total_0     : out std_logic_vector(7 downto 0);
           election_total_1     : out std_logic_vector(7 downto 0);
           election_total_2     : out std_logic_vector(7 downto 0);
           election_total_3     : out std_logic_vector(7 downto 0) );
end asp;

architecture structural of asp is
    component buf is
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
    
    -- IMPORTANT: Component declaration must EXACTLY match your core_election.vhd entity
    component core_election is
        generic ( N        : integer := 16;
                  T        : integer := 8;
                  CORE_NO  : integer := 1;
                  BF       : integer := 1;      
                  R        : integer := 2 );
        port ( reset         : in  std_logic;
               clk           : in  std_logic; 
               bufget        : out std_logic;
               buf_value1    : in std_logic_vector(N-1 downto 0);
               buf_value2    : in std_logic_vector(N-1 downto 0);
               ackn_data     : out std_logic_vector(N-1 downto 0);
               -- Make sure these port names EXACTLY match your core_election.vhd
               total_candidate_0 : out std_logic_vector(7 downto 0);
               total_candidate_1 : out std_logic_vector(7 downto 0);
               total_candidate_2 : out std_logic_vector(7 downto 0);
               total_candidate_3 : out std_logic_vector(7 downto 0) );
    end component;
    
    signal sig_buf1get                       : std_logic;
    signal sig_buf2get                       : std_logic;
    signal sig_compsysdata                   : std_logic_vector(N-1 downto 0);
    signal sig_compsyspar                    : std_logic_vector(N-1 downto 0);
    signal sig_networkdata                   : std_logic_vector(N-1 downto 0);
    signal sig_networktag                    : std_logic_vector(N-1 downto 0);
    signal sig_par                           : std_logic_vector(0 downto 0);
begin
    sig_par(0) <= compsyspar_in;
    
    buffer1 : buf
    generic map (N => N, M => 1) 
    port map (
        reset => reset,
        clk => clk,
        value1_in => compsysdata_in,
        value2_in => sig_par,
        bufget => sig_buf1get,
        value1_out => sig_compsysdata,
        value2_out => sig_compsyspar );
    
    core1 : core_election
    generic map (N => N, T => T, CORE_NO => 1, BF => BF, R => R ) 
    port map (
        reset  => reset,
        clk    => clk,
        bufget => sig_buf1get,
        buf_value1 => sig_compsysdata,
        buf_value2 => sig_compsyspar,
        ackn_data => compsys_ackndata,
        -- Connect election outputs
        total_candidate_0 => election_total_0,
        total_candidate_1 => election_total_1,
        total_candidate_2 => election_total_2,
        total_candidate_3 => election_total_3 );
    
    buffer2 : buf
    generic map (N => N, M => T) 
    port map (
        reset => reset,
        clk => clk,
        value1_in => networkdata_in,
        value2_in => networktag_in,
        bufget => sig_buf2get,
        value1_out => sig_networkdata,
        value2_out => sig_networktag );
    
    core2 : core_election
    generic map (N => N, T => T, CORE_NO => 2, BF => BF, R => R ) 
    port map (
        reset  => reset,
        clk    => clk,
        bufget => sig_buf2get,
        buf_value1 => sig_networkdata,
        buf_value2 => sig_networktag,
        ackn_data => network_ackndata,
        -- For core2, you can leave unconnected if not needed
        total_candidate_0 => open,
        total_candidate_1 => open,
        total_candidate_2 => open,
        total_candidate_3 => open );
end structural;