library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.Numeric_Std.ALL;

entity election_fpga_32pin is
    port ( 
        -- Clock and Reset (2 pins)
        clk       : in  std_logic;
        reset     : in  std_logic;
        
        -- Input: 12 switches only (12 pins) - reduced from 16
        sw        : in  std_logic_vector(11 downto 0);  -- | dist(2) | cand(2) | tally(8) |
        
        -- Input: 3 buttons (3 pins) - reduced from 5
        btnC      : in  std_logic;  -- Input enable
        btnU      : in  std_logic;  -- Increment candidate select
        btnD      : in  std_logic;  -- Decrement candidate select
        
        -- Output: 7-segment display (11 pins)
        seg       : out std_logic_vector(6 downto 0);   -- 7 pins
        an        : out std_logic_vector(3 downto 0);   -- 4 pins
        
        -- Output: 4 LEDs only (4 pins) - reduced from 8
        led       : out std_logic_vector(3 downto 0)
    );
    -- TOTAL: 2 + 12 + 3 + 7 + 4 + 4 = 32 pins ? FITS!
end election_fpga_32pin;

architecture structural of election_fpga_32pin is

    component asp is
        generic ( N, T, BF, R : integer );
        port ( reset, clk : in std_logic;
               compsysdata_in : in std_logic_vector(N-1 downto 0);
               compsyspar_in : in std_logic;
               networkdata_in : in std_logic_vector(N-1 downto 0);
               networktag_in : in std_logic_vector(T-1 downto 0);
               compsys_ackndata, network_ackndata : out std_logic_vector(N-1 downto 0);
               election_total_0, election_total_1, election_total_2, election_total_3 : out std_logic_vector(7 downto 0) );
    end component;

    -- Internal signals
    signal election_totals : array(0 to 3) of std_logic_vector(7 downto 0);
    signal display_value : std_logic_vector(7 downto 0);
    signal candidate_select : std_logic_vector(1 downto 0) := "00";
    signal input_record : std_logic_vector(15 downto 0);
    
    -- Clock divider
    signal clk_div : std_logic_vector(19 downto 0) := (others => '0');
    signal display_clk : std_logic;
    
    -- Button debouncing
    signal btn_prev : std_logic_vector(1 downto 0) := "00";
    signal btn_curr : std_logic_vector(1 downto 0);

begin

    -- Create 16-bit record from 12-bit input + computed tag
    input_record <= sw & "0000";  -- Pad with 4-bit tag (will be computed)
    
    btn_curr <= btnD & btnU;

    -- Clock divider for display
    process(clk)
    begin
        if rising_edge(clk) then
            clk_div <= clk_div + 1;
        end if;
    end process;
    display_clk <= clk_div(19);

    -- Button processing for candidate selection
    process(clk)
    begin
        if rising_edge(clk) then
            btn_prev <= btn_curr;
            
            -- Increment candidate select on btnU rising edge
            if btn_curr(0) = '1' and btn_prev(0) = '0' then
                candidate_select <= candidate_select + 1;
            end if;
            
            -- Decrement candidate select on btnD rising edge  
            if btn_curr(1) = '1' and btn_prev(1) = '0' then
                candidate_select <= candidate_select - 1;
            end if;
        end if;
    end process;

    -- Election system instantiation
    election_core : asp
    generic map (N => 16, T => 8, BF => 1, R => 2)
    port map (
        reset => reset,
        clk => clk,
        compsysdata_in => input_record,
        compsyspar_in => btnC,
        networkdata_in => (others => '0'),
        networktag_in => (others => '0'),
        compsys_ackndata => open,  -- Not connected to save pins
        network_ackndata => open,  -- Not connected to save pins
        election_total_0 => election_totals(0),
        election_total_1 => election_totals(1),
        election_total_2 => election_totals(2),
        election_total_3 => election_totals(3)
    );

    -- Select which candidate total to display
    display_value <= election_totals(conv_integer(candidate_select));

    -- 7-segment display controller
    process(display_clk)
        variable digit_select : std_logic_vector(1 downto 0) := "00";
        variable current_digit : std_logic_vector(3 downto 0);
    begin
        if rising_edge(display_clk) then
            digit_select := digit_select + 1;
            
            case digit_select is
                when "00" => 
                    an <= "1110";
                    current_digit := display_value(3 downto 0);
                when "01" => 
                    an <= "1101";
                    current_digit := display_value(7 downto 4);
                when others =>
                    an <= "1111";
                    current_digit := "0000";
            end case;
            
            -- 7-segment decoder
            case current_digit is
                when "0000" => seg <= "1000000";  -- 0
                when "0001" => seg <= "1111001";  -- 1
                when "0010" => seg <= "0100100";  -- 2
                when "0011" => seg <= "0110000";  -- 3
                when "0100" => seg <= "0011001";  -- 4
                when "0101" => seg <= "0010010";  -- 5
                when "0110" => seg <= "0000010";  -- 6
                when "0111" => seg <= "1111000";  -- 7
                when "1000" => seg <= "0000000";  -- 8
                when "1001" => seg <= "0010000";  -- 9
                when others => seg <= "0001000";  -- A-F
            end case;
        end if;
    end process;

    -- LED outputs show current candidate selection and input
    led <= "00" & candidate_select & sw(11 downto 8);

end structural;