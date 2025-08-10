
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity register_file is
    generic (N: integer := 16);
    port ( reset           : in  std_logic;
           clk             : in  std_logic;
           read_register_a : in  std_logic_vector(3 downto 0);
           read_register_b : in  std_logic_vector(3 downto 0);
           write_enable    : in  std_logic;
           write_enable2   : in  std_logic;
           write_register  : in  std_logic_vector(3 downto 0);
           write_register2 : in  std_logic_vector(3 downto 0);
           write_data      : in  std_logic_vector(N-1 downto 0);
           write_data2     : in  std_logic_vector(N-1 downto 0);
           read_data_a     : out std_logic_vector(N-1 downto 0);
           read_data_b     : out std_logic_vector(N-1 downto 0) );
end register_file;

architecture behavioral of register_file is

type reg_file is array(0 to 15) of std_logic_vector(N-1 downto 0);
signal sig_regfile : reg_file;

begin

    mem_process : process ( reset,
                            clk,
                            read_register_a,
                            read_register_b,
                            write_enable,
                            write_enable2,
                            write_register,
                            write_register2,
                            write_data,
                            write_data2 ) is

    variable var_regfile     : reg_file;
    variable var_read_addr_a : integer;
    variable var_read_addr_b : integer;
    variable var_write_addr  : integer;
    variable var_write_addr2  : integer;
    
    begin
    
        var_read_addr_a := conv_integer(read_register_a);
        var_read_addr_b := conv_integer(read_register_b);
        var_write_addr  := conv_integer(write_register);
        var_write_addr2  := conv_integer(write_register2);
        
        if (reset = '1') then
            -- initial values of the registers - reset to zeroes
            var_regfile := (others => (others => '0'));

            elsif (falling_edge(clk)) then
                -- register write on the falling clock edge
                if (write_enable = '1') then
                    var_regfile(var_write_addr) := write_data;
                end if;
                if (write_enable2 = '1') then
                    var_regfile(var_write_addr2) := write_data2;
                end if;
        end if;
        var_regfile(0) := (others => '0');
        var_regfile(1) := (others => '1');

        -- continuous read of the registers at location read_register_a
        -- and read_register_b
        read_data_a <= var_regfile(var_read_addr_a); 
        read_data_b <= var_regfile(var_read_addr_b);

        -- the following are probe signals (for simulation purpose)
        sig_regfile <= var_regfile;

    end process; 
end behavioral;
