library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;

entity tb_election_system_complete is
end tb_election_system_complete;

architecture testbench of tb_election_system_complete is
    
    -- Component declaration
    component asp_no_buffer is
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
    end component;

    -- Test signals
    signal clk, reset : std_logic := '0';
    signal election_record : std_logic_vector(15 downto 0) := (others => '0');
    signal record_enable : std_logic := '0';
    signal ackn_data : std_logic_vector(15 downto 0);
    
    -- FIXED: Proper VHDL array declaration
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
    uut : asp_no_buffer
    generic map (N => 16, T => 8, BF => 1, R => 2)
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
        type expected_totals_type is array(0 to 3) of integer;
        variable expected_totals : expected_totals_type := (others => 0);
        variable test_passed : boolean;
        variable total_tests : integer := 0;
        variable passed_tests : integer := 0;
        
        -- Procedure to send an election record
        procedure send_election_record(
            district, candidate, votes : integer; 
            description : string) is
            variable record_data : std_logic_vector(15 downto 0);
        begin
            -- Create election record: | district(2) | candidate(2) | votes(8) | tag(4) |
            record_data := std_logic_vector(to_unsigned(district, 2)) &
                          std_logic_vector(to_unsigned(candidate, 2)) &
                          std_logic_vector(to_unsigned(votes, 8)) &
                          "0000";  -- Tag will be computed by system
            
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
            
            -- Update expected totals
            expected_totals(candidate) := expected_totals(candidate) + votes;
        end procedure;
        
        -- Procedure to check current totals
        procedure check_totals is
            variable all_correct : boolean := true;
        begin
            write(l, string'("Checking totals..."));
            writeline(output, l);
            
            for i in 0 to 3 loop
                write(l, string'("  Candidate "));
                write(l, i);
                write(l, string'(": "));
                write(l, to_integer(unsigned(election_totals(i))));
                write(l, string'(" (expected: "));
                write(l, expected_totals(i));
                write(l, string'(")"));
                
                if to_integer(unsigned(election_totals(i))) = expected_totals(i) then
                    write(l, string'(" PASS"));
                    writeline(output, l);
                else
                    write(l, string'(" FAIL"));
                    writeline(output, l);
                    all_correct := false;
                end if;
            end loop;
            
            total_tests := total_tests + 1;
            if all_correct then
                passed_tests := passed_tests + 1;
                write(l, string'("Tally check PASSED"));
            else
                write(l, string'("Tally check FAILED"));
            end if;
            writeline(output, l);
            write(l, string'(""));
            writeline(output, l);
        end procedure;
        
        -- Procedure to reset the system
        procedure reset_system is
        begin
            write(l, string'("Resetting system..."));
            writeline(output, l);
            reset <= '1';
            election_record <= (others => '0');
            record_enable <= '0';
            wait for 5 * clk_period;
            reset <= '0';
            wait for 5 * clk_period;
            
            -- Reset expected totals
            for i in 0 to 3 loop
                expected_totals(i) := 0;
            end loop;
        end procedure;

    begin
        -- Test header
        write(l, string'(""));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'("    ELECTION SYSTEM COMPLETE TEST"));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'(""));
        writeline(output, l);
        
        -- Initialize system
        reset_system;
        
        -- Test 1: Basic election simulation
        write(l, string'("=== BASIC ELECTION SIMULATION ==="));
        writeline(output, l);
        
        send_election_record(0, 0, 10, "District 0 -> Candidate 0");
        send_election_record(0, 1, 15, "District 0 -> Candidate 1");
        send_election_record(1, 0, 8,  "District 1 -> Candidate 0");
        send_election_record(1, 2, 12, "District 1 -> Candidate 2");
        
        check_totals;
        
        send_election_record(2, 1, 20, "District 2 -> Candidate 1");
        send_election_record(2, 3, 5,  "District 2 -> Candidate 3");
        send_election_record(3, 0, 18, "District 3 -> Candidate 0");
        send_election_record(3, 1, 7,  "District 3 -> Candidate 1");
        
        check_totals;
        
        send_election_record(0, 2, 25, "District 0 -> Candidate 2");
        send_election_record(1, 3, 13, "District 1 -> Candidate 3");
        send_election_record(2, 0, 6,  "District 2 -> Candidate 0");
        send_election_record(3, 2, 9,  "District 3 -> Candidate 2");
        
        -- Final tally check
        write(l, string'("=== FINAL ELECTION RESULTS ==="));
        writeline(output, l);
        check_totals;
        
        -- Test 2: Boundary conditions
        write(l, string'("=== BOUNDARY CONDITIONS TEST ==="));
        writeline(output, l);
        
        -- Test zero votes
        send_election_record(0, 0, 0, "Zero votes test");
        
        -- Test maximum votes (255)
        send_election_record(1, 1, 255, "Maximum votes test (255)");
        
        check_totals;
        
        -- Test summary
        write(l, string'(""));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        write(l, string'("           TEST SUMMARY"));
        writeline(output, l);
        write(l, string'("========================================"));
        writeline(output, l);
        
        write(l, string'("Total Tests: "));
        write(l, total_tests);
        writeline(output, l);
        write(l, string'("Passed:      "));
        write(l, passed_tests);
        writeline(output, l);
        write(l, string'("Failed:      "));
        write(l, total_tests - passed_tests);
        writeline(output, l);
        
        if passed_tests = total_tests then
            write(l, string'(""));
            writeline(output, l);
            write(l, string'("? ALL TESTS PASSED! ?"));
            writeline(output, l);
            write(l, string'("Election system working correctly!"));
            writeline(output, l);
        else
            write(l, string'(""));
            writeline(output, l);
            write(l, string'("? Some tests failed."));
            writeline(output, l);
        end if;
        
        -- End simulation
        write(l, string'(""));
        writeline(output, l);
        write(l, string'("Simulation completed."));
        writeline(output, l);
        
        wait;
    end process;

end testbench;