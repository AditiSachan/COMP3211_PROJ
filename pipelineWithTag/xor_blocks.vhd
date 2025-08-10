library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity xor_blocks is
    generic(tag_size : integer := 4;
            num_blocks : integer := 4);
    port ( blocks : in std_logic_vector(num_blocks * tag_size - 1 downto 0);
           result : out std_logic_vector(tag_size - 1 downto 0) );
end xor_blocks;

architecture Behavioral of xor_blocks is
begin
    process(blocks)
        variable temp_result : std_logic_vector(tag_size - 1 downto 0);
    begin
        temp_result := (others => '0');
        
        for i in 0 to num_blocks - 1 loop
            temp_result := temp_result xor blocks((i+1)*tag_size - 1 downto i*tag_size);
        end loop;
        
        result <= temp_result;
    end process;
end Behavioral;
