
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity program_counter is
    port ( reset    : in  std_logic;
           stall    : in std_logic;
           clk      : in  std_logic;
           addr_in  : in  std_logic_vector(3 downto 0);
           addr_out : out std_logic_vector(3 downto 0) );
end program_counter;

architecture behavioral of program_counter is
begin

    update_process: process ( reset, 
                              clk ) is
    begin
        if (falling_edge(clk)) then
            if (stall = '0') then
                addr_out <= addr_in;
            end if; 
        end if;
        
        if (falling_edge(reset)) then
           addr_out <= (others => '0'); 
        end if;

    end process;
end behavioral;
