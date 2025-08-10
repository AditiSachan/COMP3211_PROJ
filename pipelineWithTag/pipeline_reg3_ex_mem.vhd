
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pipeline_reg3_ex_mem is
    generic (N: integer := 16);
    port ( stall            : in  std_logic;
           clk              : in  std_logic;

           memput_in        : in std_logic;
           bufget_in        : in std_logic;
           regwrite_in      : in std_logic;
           regwrite2_in     : in std_logic;
           buftoreg_in      : in std_logic;
           result_in        : in  std_logic_vector(N-1 downto 0);
           write_data2_in   : in  std_logic_vector(N-1 downto 0);
           write_reg_in     : in  std_logic_vector(3 downto 0);
           write_reg2_in    : in  std_logic_vector(3 downto 0);
           insn_in          : in  std_logic_vector(15 downto 0);
           insn_out         : out  std_logic_vector(15 downto 0);

           memput_out        : out std_logic;
           bufget_out        : out std_logic;
           regwrite_out      : out std_logic;
           regwrite2_out     : out std_logic;
           buftoreg_out      : out std_logic;
           result_out        : out  std_logic_vector(N-1 downto 0);
           write_data2_out   : out  std_logic_vector(N-1 downto 0);
           write_reg_out     : out  std_logic_vector(3 downto 0);
           write_reg2_out    : out  std_logic_vector(3 downto 0) );
end pipeline_reg3_ex_mem;

architecture behavioral of pipeline_reg3_ex_mem is
begin
    update_process: process ( stall, clk ) is
    begin
       if (stall = '0') then
            if (rising_edge(clk)) then
                memput_out      <= memput_in;      
                bufget_out      <= bufget_in;      
                regwrite_out    <= regwrite_in;    
                regwrite2_out   <= regwrite2_in;   
                buftoreg_out    <= buftoreg_in;    
                result_out      <= result_in;      
                write_data2_out <= write_data2_in; 
                write_reg_out   <= write_reg_in;   
                write_reg2_out  <= write_reg2_in;  
                insn_out         <= insn_in;    

            end if;
       end if;
    end process;
end behavioral;
