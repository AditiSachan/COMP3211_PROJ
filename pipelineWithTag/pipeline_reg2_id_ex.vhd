
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pipeline_reg2_id_ex is
    generic (N: integer := 16);
    port ( stall            : in  std_logic;
           clk              : in  std_logic;
           opcode_in        : in std_logic_vector(3 downto 0);
           bufget_in        : in std_logic;
           memput_in        : in std_logic;
           regwrite_in      : in std_logic;
           regwrite2_in     : in std_logic;
           buftoreg_in      : in std_logic;
           next_pc_in       : in  std_logic_vector(3 downto 0);
           dataA_in         : in  std_logic_vector(N-1 downto 0);
           dataB_in         : in  std_logic_vector(N-1 downto 0);
           rs_in            : in  std_logic_vector(3 downto 0);
           rt_in            : in  std_logic_vector(3 downto 0);
           rd_in            : in  std_logic_vector(3 downto 0);
           insn_in          : in  std_logic_vector(15 downto 0);
           
           opcode_out        : out std_logic_vector(3 downto 0);
           bufget_out        : out std_logic;
           memput_out        : out std_logic;
           regwrite_out      : out std_logic;
           regwrite2_out     : out std_logic;
           buftoreg_out      : out std_logic;
           next_pc_out       : out  std_logic_vector(3 downto 0);
           dataA_out         : out  std_logic_vector(N-1 downto 0);
           dataB_out         : out  std_logic_vector(N-1 downto 0);
           rs_out            : out  std_logic_vector(3 downto 0);
           rt_out            : out  std_logic_vector(3 downto 0);
           rd_out            : out  std_logic_vector(3 downto 0);
           insn_out         : out  std_logic_vector(15 downto 0) );
    end pipeline_reg2_id_ex;

architecture behavioral of pipeline_reg2_id_ex is
begin
    update_process: process ( stall, clk ) is
    begin
       if (stall = '0') then
            if (rising_edge(clk)) then
                opcode_out       <= opcode_in;       
                bufget_out       <= bufget_in;       
                memput_out       <= memput_in;       
                regwrite_out     <= regwrite_in;     
                regwrite2_out    <= regwrite2_in;    
                buftoreg_out     <= buftoreg_in;     
                next_pc_out      <= next_pc_in;      
                dataA_out        <= dataA_in;        
                dataB_out        <= dataB_in;        
                rs_out           <= rs_in;           
                rt_out           <= rt_in;           
                rd_out           <= rd_in;           
                insn_out         <= insn_in;    
            end if;
       end if;
    end process;
end behavioral;
