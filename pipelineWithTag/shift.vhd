library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity shift is
    generic(tag_size : integer := 4);
    port ( r : in std_logic_vector(tag_size - 1 downto 0);
           shift_block : in std_logic_vector(tag_size - 1 downto 0);
           output_block : out std_logic_vector(tag_size - 1 downto 0) );
end shift;

architecture Behavioral of shift is
begin
    process(r, shift_block)
        variable rot_amount : integer;
        variable temp_block : std_logic_vector(tag_size - 1 downto 0);
    begin
        rot_amount := to_integer(unsigned(r)) mod tag_size;
        
        -- Left rotate (corrected from your right rotate)
        for i in 0 to tag_size - 1 loop
            temp_block((i + rot_amount) mod tag_size) := shift_block(i);
        end loop;
        
        output_block <= temp_block;
    end process;
end Behavioral;