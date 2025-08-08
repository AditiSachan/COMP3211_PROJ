
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity Pipelined_core_TB_VHDL is
end Pipelined_core_TB_VHDL;


architecture behave of Pipelined_core_TB_VHDL is
 
  -- 1 GHz = 2 nanoseconds period
  constant c_CLOCK_PERIOD : time := 2 ns; 


 signal r_CLOCK     : std_logic := '0';
 signal r_reset    : std_logic := '0';
 
 signal s_sw : std_logic_vector(15 downto 0);
 signal s_led : std_logic_vector(15 downto 0);
 signal s_seg : std_logic_vector(6 downto 0);
 signal s_an : std_logic_vector(3 downto 0);

-- Component declaration for the Unit Under Test (UUT)
component pipelined_core is
    port ( reset  : in  std_logic;
           b_clk    : in  std_logic;
           sw     : in  std_logic_vector(15 downto 0);
           btnC   : in  std_logic;
           an    : out std_logic_vector(3 downto 0);
           seg   : out std_logic_vector(6 downto 0);
           led  : out std_logic_vector(15 downto 0));
      end component ;
      
      
      begin
       
        -- Instantiate the Unit Under Test (UUT)
        UUT : pipelined_core
          port map (
            reset  => r_reset,
           b_clk  => r_CLOCK, 
           sw    => s_sw, 
           btnC  => r_CLOCK, 
           an   => s_an, 
           seg  => s_seg, 
           led  => s_led
            );
       
        p_CLK_GEN : process is
        begin
          wait for c_CLOCK_PERIOD/2;
          r_CLOCK <= not r_CLOCK;
        end process p_CLK_GEN; 
         
        process                               -- main testing
        begin
          r_reset <= '0';
       
             wait for 2*c_CLOCK_PERIOD ;
        r_reset <= '1';
           
           wait for 2*c_CLOCK_PERIOD ;
                r_reset <= '0';         
          
          wait for 2 sec;
           
        end process;
         
      end behave;
      
      
      
      
      
      
      