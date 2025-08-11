library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tally_table is
    generic ( N_DISTRICTS : integer := 4;
              N_CANDIDATES: integer := 4;
              TALLY_WIDTH : integer := 8 );
    port ( clk          : in  std_logic;
           reset        : in  std_logic;
           write_enable : in  std_logic;
           district_id  : in  std_logic_vector(1 downto 0);
           candidate_id : in  std_logic_vector(1 downto 0);
           increment    : in  std_logic_vector(TALLY_WIDTH-1 downto 0);
           -- Debug outputs 
           total_candidate_0 : out std_logic_vector(TALLY_WIDTH-1 downto 0);
           total_candidate_1 : out std_logic_vector(TALLY_WIDTH-1 downto 0);
           total_candidate_2 : out std_logic_vector(TALLY_WIDTH-1 downto 0);
           total_candidate_3 : out std_logic_vector(TALLY_WIDTH-1 downto 0) );
end tally_table;

architecture behavioral of tally_table is
    type district_array is array(0 to N_CANDIDATES-1) of std_logic_vector(TALLY_WIDTH-1 downto 0);
    type tally_array is array(0 to N_DISTRICTS-1) of district_array;
    signal tally_mem : tally_array;
begin
    

    process(clk, reset)
        variable district_idx, candidate_idx : integer;
    begin
        if reset = '1' then
            for i in 0 to N_DISTRICTS-1 loop
                for j in 0 to N_CANDIDATES-1 loop
                    tally_mem(i)(j) <= (others => '0');
                end loop;
            end loop;
        elsif rising_edge(clk) then
            if write_enable = '1' then
                district_idx := conv_integer(district_id);
                candidate_idx := conv_integer(candidate_id);
                
                if district_idx < N_DISTRICTS and candidate_idx < N_CANDIDATES then
                    tally_mem(district_idx)(candidate_idx) <= 
                        tally_mem(district_idx)(candidate_idx) + increment;
                end if;
            end if;
        end if;
    end process;
    
    -- Continuous calculation of totals (for display/debugging)
    process(tally_mem)
        variable total_0, total_1, total_2, total_3 : std_logic_vector(TALLY_WIDTH-1 downto 0);
    begin
        total_0 := (others => '0');
        total_1 := (others => '0');
        total_2 := (others => '0');
        total_3 := (others => '0');
        
        for i in 0 to N_DISTRICTS-1 loop
            if N_CANDIDATES > 0 then total_0 := total_0 + tally_mem(i)(0); end if;
            if N_CANDIDATES > 1 then total_1 := total_1 + tally_mem(i)(1); end if;
            if N_CANDIDATES > 2 then total_2 := total_2 + tally_mem(i)(2); end if;
            if N_CANDIDATES > 3 then total_3 := total_3 + tally_mem(i)(3); end if;
        end loop;
        
        total_candidate_0 <= total_0;
        total_candidate_1 <= total_1;
        total_candidate_2 <= total_2;
        total_candidate_3 <= total_3;
    end process;

end behavioral;