library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity buf is
    generic ( N: integer := 16;
              M: integer := 8 );
    port (  reset       : in std_logic;
            clk         : in std_logic;
            value1_in   : in std_logic_vector(N-1 downto 0);
            value2_in   : in std_logic_vector(M-1 downto 0);
            bufget      : in std_logic;
            value1_out  : out std_logic_vector(N-1 downto 0);
            value2_out  : out std_logic_vector(N-1 downto 0) );
end buf;

architecture behavioral of buf is
    -- FIXED: Correct array size and type
    type mem_array is array(0 to 15) of std_logic_vector(N+M-1 downto 0);  -- 16 entries max
    signal sig_data_mem : mem_array;
    signal write_head : integer range 0 to 15 := 0;  -- FIXED: Bounded range
    signal read_head : integer range 0 to 15 := 0;   -- FIXED: Bounded range
    signal zero : std_logic_vector(N-1 downto 0);
    signal value1_out_buf : std_logic_vector(N-1 downto 0);
begin
    zero <= (others => '0');
    
    mem_process: process ( reset, clk, bufget, value1_in, value2_in ) is
        variable var_data_mem : mem_array;
    begin
        
        if (reset = '1') then
            -- initial values of the data memory : reset to zero 
            var_data_mem := (others => (others => '0'));
            write_head <= 0;  -- FIXED: Reset head pointers
            read_head <= 0;
        elsif (falling_edge(clk)) then
            if (value1_in /= zero) then
                -- memory writes on the falling clock edge
                var_data_mem(write_head)(N-1 downto 0) := value1_in;
                var_data_mem(write_head)(N+M-1 downto N) := value2_in;
                -- FIXED: Wrap around properly
                if write_head = 15 then
                    write_head <= 0;
                else
                    write_head <= write_head + 1;
                end if;
            end if;
            if (bufget = '1') then
                -- memory reads on the falling clock edge
                value1_out_buf <= var_data_mem(read_head)(N-1 downto 0);
                if (value1_out_buf /= zero) then
                    -- FIXED: Wrap around properly
                    if read_head = 15 then
                        read_head <= 0;
                    else
                        read_head <= read_head + 1;
                    end if;
                end if;
            end if;
        end if;
        
        value1_out <= var_data_mem(read_head)(N-1 downto 0);
        value2_out <= (others => '0');
        value2_out(M-1 downto 0) <= var_data_mem(read_head)(N+M-1 downto N);
        -- the following are probe signals (for simulation purpose) 
        sig_data_mem <= var_data_mem;
    end process;
  
end behavioral;