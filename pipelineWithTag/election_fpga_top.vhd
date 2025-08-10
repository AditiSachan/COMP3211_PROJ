library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.Numeric_Std.ALL;

entity election_fpga_top is
    port ( 
        -- Clock and Reset
        clk       : in  std_logic;                     -- 100MHz board clock
        reset     : in  std_logic;                     -- Reset button
        
        -- Input: 16 switches for tally record
        sw        : in  std_logic_vector(15 downto 0);
        
        -- Input: Buttons for control
        btnC      : in  std_logic;                     -- Center button (input control)
        btnU      : in  std_logic;                     -- Up button (candidate 0 display)
        btnD      : in  std_logic;                     -- Down button (candidate 1 display)
        btnL      : in  std_logic;                     -- Left button (candidate 2 display)
        btnR      : in  std_logic;                     -- Right button (candidate 3 display)
        
        -- Output: 7-segment display
        seg       : out std_logic_vector(6 downto 0);  -- 7-segment segments
        an        : out std_logic_vector(3 downto 0);  -- 7-segment anodes
        dp        : out std_logic;                     -- Decimal point
        
        -- Output: LEDs for debugging
        led       : out std_logic_vector(15 downto 0)
    );
end election_fpga_top;

architecture structural of election_fpga_top is

    component asp is
        generic ( N  : integer := 16; T  : integer := 8; BF : integer := 1; R  : integer := 2 );
        port ( reset : in  std_logic; clk : in  std_logic;
               compsysdata_in : in std_logic_vector(N-1 downto 0);
               compsyspar_in : in std_logic;
               networkdata_in : in std_logic_vector(N-1 downto 0);
               networktag_in : in std_logic_vector(T-1 downto 0);
               compsys_ackndata : out std_logic_vector(N-1 downto 0);
               network_ackndata : out std_logic_vector(N-1 downto 0);
               election_total_0 : out std_logic_vector(7 downto 0);
               election_total_1 : out std_logic_vector(7 downto 0);
               election_total_2 : out std_logic_vector(7 downto 0);
               election_total_3 : out std_logic_vector(7 downto 0) );
    end component;

    -- FIXED: Correct VHDL array declaration
    type candidate_totals_array is array(0 to 3) of std_logic_vector(7 downto 0);
    signal election_totals : candidate_totals_array;
    
    signal display_value : std_logic_vector(7 downto 0);
    signal button_pressed : std_logic_vector(3 downto 0);
    signal input_record : std_logic_vector(15 downto 0);
    signal input_tag : std_logic_vector(7 downto 0);
    
    -- Clock divider for 7-segment display
    signal clk_div : std_logic_vector(19 downto 0) := (others => '0');
    signal display_clk : std_logic;

begin

    -- Clock divider for display refresh
    process(clk)
    begin
        if rising_edge(clk) then
            clk_div <= clk_div + 1;
        end if;
    end process;
    display_clk <= clk_div(19);  -- ~190Hz refresh rate

    -- Input processing
    input_record <= sw;  -- 16 switches: | district(2) | candidate(2) | tally(8) | tag(4) |
    input_tag <= X"0" & sw(3 downto 0);  -- Extract tag from switches

    -- Button processing
    button_pressed <= btnR & btnL & btnD & btnU;

    -- Election system instantiation
    election_core : asp
    generic map (N => 16, T => 8, BF => 1, R => 2)
    port map (
        reset => reset,
        clk => clk,
        compsysdata_in => input_record,
        compsyspar_in => btnC,  -- Use center button as input enable
        networkdata_in => (others => '0'),
        networktag_in => (others => '0'),
        compsys_ackndata => open,
        network_ackndata => open,
        election_total_0 => election_totals(0),
        election_total_1 => election_totals(1),
        election_total_2 => election_totals(2),
        election_total_3 => election_totals(3)
    );

    -- Display selection based on buttons
    process(button_pressed, election_totals)
    begin
        case button_pressed is
            when "0001" => display_value <= election_totals(0);  -- btnU pressed
            when "0010" => display_value <= election_totals(1);  -- btnD pressed
            when "0100" => display_value <= election_totals(2);  -- btnL pressed
            when "1000" => display_value <= election_totals(3);  -- btnR pressed
            when others => display_value <= election_totals(0);  -- Default to candidate 0
        end case;
    end process;

    -- 7-segment display controller (simplified)
    process(display_clk)
        variable digit_select : std_logic_vector(1 downto 0) := "00";
        variable current_digit : std_logic_vector(3 downto 0);
    begin
        if rising_edge(display_clk) then
            digit_select := digit_select + 1;
            
            case digit_select is
                when "00" => 
                    an <= "1110";  -- Enable rightmost digit
                    current_digit := display_value(3 downto 0);
                when "01" => 
                    an <= "1101";  -- Enable second digit
                    current_digit := display_value(7 downto 4);
                when others =>
                    an <= "1111";  -- All off
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
                when "1010" => seg <= "0001000";  -- A
                when "1011" => seg <= "0000011";  -- b
                when "1100" => seg <= "1000110";  -- C
                when "1101" => seg <= "0100001";  -- d
                when "1110" => seg <= "0000110";  -- E
                when "1111" => seg <= "0001110";  -- F
                when others => seg <= "1111111";  -- Off
            end case;
        end if;
    end process;

    dp <= '1';  -- Decimal point off

    -- LED outputs for debugging
    led <= input_record;

end structural;