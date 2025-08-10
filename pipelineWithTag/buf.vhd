library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity election_buffer is  -- RENAMED from 'buf' to avoid conflict
    generic ( N: integer := 16;
              M: integer := 8 );
    port (  reset       : in std_logic;
            clk         : in std_logic;
            value1_in   : in std_logic_vector(N-1 downto 0);
            value2_in   : in std_logic_vector(M-1 downto 0);
            bufget      : in std_logic;
            value1_out  : out std_logic_vector(N-1 downto 0);
            value2_out  : out std_logic_vector(N-1 downto 0) );
end election_buffer;

architecture behavioral of election_buffer is
    type mem_array is array(0 to N-1) of std_logic_vector(N+M-1 downto 0);
    signal sig_data_mem : mem_array;
    signal write_head : integer := 0;
    signal read_head : integer := 0;
    signal data_count : integer := 0;
    
begin
    
    -- Memory process - use rising_edge to match pipeline
    mem_process: process (reset, clk) is
        variable var_data_mem : mem_array;
    begin
        if (reset = '1') then
            var_data_mem := (others => (others => '0'));
            write_head <= 0;
            read_head <= 0;
            data_count <= 0;
            
        elsif (rising_edge(clk)) then
            -- Write new data when value2_in indicates data is valid
            if (conv_integer(value2_in) > 0) then
                var_data_mem(write_head)(N-1 downto 0) := value1_in;
                var_data_mem(write_head)(N+M-1 downto N) := value2_in;
                write_head <= (write_head + 1) mod N;
                if data_count < N then
                    data_count <= data_count + 1;
                end if;
            end if;
            
            -- Read data when requested and data is available
            if (bufget = '1' and data_count > 0) then
                read_head <= (read_head + 1) mod N;
                data_count <= data_count - 1;
            end if;
        end if;
        
        sig_data_mem <= var_data_mem;
    end process;
    
    -- Continuous output assignment
    value1_out <= sig_data_mem(read_head)(N-1 downto 0) when data_count > 0 else (others => '0');
    value2_out <= (others => '0');
    value2_out(M-1 downto 0) <= sig_data_mem(read_head)(N+M-1 downto N) when data_count > 0 else (others => '0');
    
end behavioral;