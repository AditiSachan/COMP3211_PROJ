library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;

entity tb_simple is
end tb_simple;

architecture testbench of tb_simple is
    
    -- Component declaration - matches asp_simple
    component asp_simple is
        generic ( N  : integer := 16;
                  T  : integer := 4;
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
    end component;

    -- Test signals
    signal clk, reset : std_logic := '0';
    signal election_record : std_logic_vector(15 downto 0) := (others => '0');
    signal record_enable : std_logic := '0';
    signal ackn_data : std_logic_vector(15 downto 0);
    
    -- Election totals
    type candidate_totals_type is array(0 to 3) of std_logic_vector(7 downto 0);
    signal election_totals : candidate_totals_type;
    
    -- Clock period
    constant clk_period : time := 10 ns;

begin
    
    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Unit Under Test instantiation
    uut : asp_simple
    generic map (N => 16, T => 4, BF => 1, R => 2)
    port map (
        reset => reset,
        clk => clk,
        election_record_in => election_record,
        record_enable => record_enable,
        ackn_data => ackn_data,
        election_total_0 => election_totals(0),
        election_total_1 => election_totals(1),
        election_total_2 => election_totals(2),
        election_total_3 => election_totals(3)
    );

    -- Main test process
    stimulus_process : process
        variable l : line;
        
        -- Procedure to send an election record
        procedure send_election_record(district, candidate, votes : integer; description : string) is
            variable record_data : std_logic_vector(15 downto 0);
        begin
            -- Create election record: | district(2) | candidate(2) | votes(8) | tag(4) |
            record_data := std_logic_vector(to_unsigned(district, 2)) &
                          std_logic_vector(to_unsigned(candidate, 2)) &
                          std_logic_vector(to_unsigned(votes, 8)) &
                          "0000";  -- Dummy tag for now
            
            -- Send the record
            election_record <= record_data;
            record_enable <= '1';
            wait for clk_period;
            record_enable <= '0';
            
            write(l, string'("Sending: "));
            write(l, description);
            write(l, string'(" ("));
            write(l, votes);
            write(l, string'(" votes)"));
            writeline(output, l);
            
            -- Wait for processing
            wait for 50 * clk_period;
        end procedure;

    begin
        -- Test header
        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'("    SIMPLE ELECTION SYSTEM TEST"));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        
        -- Reset system
        reset <= '1';
        wait for 5 * clk_period;
        reset <= '0';
        wait for 5 * clk_period;
        
        -- Test basic election simulation
        send_election_record(0, 0, 10, "District 0 -> Candidate 0");
        send_election_record(0, 1, 15, "District 0 -> Candidate 1");
        send_election_record(1, 0, 8,  "District 1 -> Candidate 0");
        send_election_record(1, 2, 12, "District 1 -> Candidate 2");
        
        -- Print current totals
        write(l, string'("Current Totals:"));
        writeline(output, l);
        write(l, string'("  Candidate 0: "));
        write(l, to_integer(unsigned(election_totals(0))));
        writeline(output, l);
        write(l, string'("  Candidate 1: "));
        write(l, to_integer(unsigned(election_totals(1))));
        writeline(output, l);
        write(l, string'("  Candidate 2: "));
        write(l, to_integer(unsigned(election_totals(2))));
        writeline(output, l);
        write(l, string'("  Candidate 3: "));
        write(l, to_integer(unsigned(election_totals(3))));
        writeline(output, l);
        
        write(l, string'("Simulation completed."));
        writeline(output, l);
        
        wait;
    end process;

end testbench;