library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tag_tb is
end tag_tb;

architecture behavioral of tag_tb is
    constant c_tag_size : integer := 3;
    constant c_bit_size : integer := 14;
    -- Component declaration
    component tag is
    generic(
        tag_size : integer := 3;
        bit_size : integer := 14   
    );
    Port (
        incoming_bits : in std_logic_vector(bit_size downto 0);
        output_tag : out std_logic_vector(tag_size downto 0)
    );
    end component;
    
    -- Clock period
    constant clk_period : time := 10 ns;
    
    -- Test tracking


    signal sig_incoming_bits : std_logic_vector(c_bit_size downto 0);
    signal sig_output_tag : std_logic_vector(c_tag_size downto 0);
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: tag
        generic map (
            tag_size => c_tag_size,
            bit_size => c_bit_size
        )
        port map (
            incoming_bits => sig_incoming_bits,
            output_tag => sig_output_tag
        );
    
    -- Main test process
    stimulus_process: process
    begin
        sig_incoming_bits <= "010000111001100";
        wait for 10 ns;
    end process;
    
end behavioral;