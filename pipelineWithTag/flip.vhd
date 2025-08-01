library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity flip is
  generic(tag_size : integer := 6);
  port (
    flip_block : in std_logic_vector(tag_size downto 0);
    output_block : out std_logic_vector(tag_size downto 0)
   );
end flip;

architecture behavioural of flip is
begin
  output_block <= not flip_block;
end behavioural;