library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mem_stage is
    Port (
        clk             : in  STD_LOGIC;
        reset           : in  STD_LOGIC;
        mem_read        : in  STD_LOGIC;
        mem_write       : in  STD_LOGIC;
        address         : in  STD_LOGIC_VECTOR(15 downto 0);
        write_data      : in  STD_LOGIC_VECTOR(15 downto 0);
        validation      : in  STD_LOGIC;
        
        -- Outputs
        read_data       : out STD_LOGIC_VECTOR(15 downto 0);
        candidate_total : out STD_LOGIC_VECTOR(10 downto 0)
    );
end mem_stage;

architecture Behavioral of mem_stage is

    -- Component Declarations
    component tally_table_memory is
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            address     : in  STD_LOGIC_VECTOR(4 downto 0); -- 5 bits for 20 locations
            write_en    : in  STD_LOGIC;
            write_data  : in  STD_LOGIC_VECTOR(15 downto 0);
            read_data   : out STD_LOGIC_VECTOR(15 downto 0);
            
            -- Direct candidate total outputs for display
            candidate0_total : out STD_LOGIC_VECTOR(15 downto 0);
            candidate1_total : out STD_LOGIC_VECTOR(15 downto 0);
            candidate2_total : out STD_LOGIC_VECTOR(15 downto 0);
            candidate3_total : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    component memory_controller is
        Port (
            mem_read        : in  STD_LOGIC;
            mem_write       : in  STD_LOGIC;
            validation      : in  STD_LOGIC;
            address_in      : in  STD_LOGIC_VECTOR(15 downto 0);
            
            -- Outputs to memory
            mem_enable      : out STD_LOGIC;
            mem_write_en    : out STD_LOGIC;
            mem_address     : out STD_LOGIC_VECTOR(4 downto 0)
        );
    end component;

    -- Internal Signals
    signal mem_enable : STD_LOGIC;
    signal mem_write_en : STD_LOGIC;
    signal mem_address : STD_LOGIC_VECTOR(4 downto 0);
    signal mem_read_data : STD_LOGIC_VECTOR(15 downto 0);
    
    -- Candidate total signals
    signal cand0_total, cand1_total, cand2_total, cand3_total : STD_LOGIC_VECTOR(15 downto 0);
    
    -- Current candidate being processed (from input data)
    signal current_candidate : STD_LOGIC_VECTOR(1 downto 0);

begin

    -- Extract current candidate from address (for output selection)
    -- Address format: candidate_id * 5 + district_id
    current_candidate <= address(2 downto 1); -- Approximate extraction

    -- Instantiate Memory Controller
    MEM_CTRL: memory_controller
        port map (
            mem_read => mem_read,
            mem_write => mem_write,
            validation => validation,
            address_in => address,
            mem_enable => mem_enable,
            mem_write_en => mem_write_en,
            mem_address => mem_address
        );

    -- Instantiate Tally Table Memory
    TALLY_MEM: tally_table_memory
        port map (
            clk => clk,
            reset => reset,
            address => mem_address,
            write_en => mem_write_en,
            write_data => write_data,
            read_data => mem_read_data,
            candidate0_total => cand0_total,
            candidate1_total => cand1_total,
            candidate2_total => cand2_total,
            candidate3_total => cand3_total
        );

    -- Output read data
    read_data <= mem_read_data when mem_enable = '1' else (others => '0');

    -- Select appropriate candidate total for output (11-bit)
    process(current_candidate, cand0_total, cand1_total, cand2_total, cand3_total)
    begin
        case current_candidate is
            when "00" => 
                candidate_total <= cand0_total(10 downto 0);
            when "01" => 
                candidate_total <= cand1_total(10 downto 0);
            when "10" => 
                candidate_total <= cand2_total(10 downto 0);
            when "11" => 
                candidate_total <= cand3_total(10 downto 0);
            when others => 
                candidate_total <= (others => '0');
        end case;
    end process;

end Behavioral;


-- Memory Controller Implementation
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity memory_controller is
    Port (
        mem_read        : in  STD_LOGIC;
        mem_write       : in  STD_LOGIC;
        validation      : in  STD_LOGIC;
        address_in      : in  STD_LOGIC_VECTOR(15 downto 0);
        
        -- Outputs to memory
        mem_enable      : out STD_LOGIC;
        mem_write_en    : out STD_LOGIC;
        mem_address     : out STD_LOGIC_VECTOR(4 downto 0)
    );
end memory_controller;

architecture Behavioral of memory_controller is
begin

    process(mem_read, mem_write, validation, address_in)
        variable addr_int : integer;
    begin
        -- Default outputs
        mem_enable <= '0';
        mem_write_en <= '0';
        mem_address <= (others => '0');
        
        -- Convert address to integer and bounds check
        addr_int := to_integer(unsigned(address_in));
        
        if addr_int < 20 then -- Valid tally table address
            mem_address <= std_logic_vector(to_unsigned(addr_int, 5));
            
            -- Enable memory access
            if mem_read = '1' then
                mem_enable <= '1';
                mem_write_en <= '0';
            elsif mem_write = '1' and validation = '1' then
                -- Only write if validation passed
                mem_enable <= '1';
                mem_write_en <= '1';
            end if;
        end if;
    end process;

end Behavioral;


-- Tally Table Memory Implementation
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tally_table_memory is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        address     : in  STD_LOGIC_VECTOR(4 downto 0);
        write_en    : in  STD_LOGIC;
        write_data  : in  STD_LOGIC_VECTOR(15 downto 0);
        read_data   : out STD_LOGIC_VECTOR(15 downto 0);
        
        -- Direct candidate total outputs for display
        candidate0_total : out STD_LOGIC_VECTOR(15 downto 0);
        candidate1_total : out STD_LOGIC_VECTOR(15 downto 0);
        candidate2_total : out STD_LOGIC_VECTOR(15 downto 0);
        candidate3_total : out STD_LOGIC_VECTOR(15 downto 0)
    );
end tally_table_memory;

architecture Behavioral of tally_table_memory is
    
    -- Tally Table Memory Array
    -- Layout: Candidate 0 (0-4), Candidate 1 (5-9), Candidate 2 (10-14), Candidate 3 (15-19)
    -- Each candidate: [District 0, District 1, District 2, District 3, Total]
    type tally_array is array (0 to 19) of STD_LOGIC_VECTOR(15 downto 0);
    signal tally_table : tally_array := (others => (others => '0'));

begin

    -- Memory Write Process
    process(clk, reset)
        variable addr_var : integer;
    begin
        if reset = '1' then
            tally_table <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if write_en = '1' then
                -- Safe address conversion
                if address /= "UUUUUUUUUUUUUUUU" and address /= "XXXXXXXXXXXXXXXX" then
                    addr_var := to_integer(unsigned(address));
                    if addr_var >= 0 and addr_var < 20 then
                        tally_table(addr_var) <= write_data;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Memory Read Process (Asynchronous with bounds checking)
    process(address, tally_table)
        variable addr_var : integer;
    begin
        -- Safe address conversion with bounds checking
        if address = "UUUUUUUUUUUUUUUU" or address = "XXXXXXXXXXXXXXXX" then
            -- Undefined or unknown address
            read_data <= (others => '0');
        else
            addr_var := to_integer(unsigned(address));
            if addr_var >= 0 and addr_var < 20 then
                read_data <= tally_table(addr_var);
            else
                read_data <= (others => '0');  -- Out of bounds
            end if;
        end if;
    end process;

    -- Direct Candidate Total Outputs (Always Available)
    candidate0_total <= tally_table(4);   -- Candidate 0 total at address 4
    candidate1_total <= tally_table(9);   -- Candidate 1 total at address 9  
    candidate2_total <= tally_table(14);  -- Candidate 2 total at address 14
    candidate3_total <= tally_table(19);  -- Candidate 3 total at address 19

end Behavioral;