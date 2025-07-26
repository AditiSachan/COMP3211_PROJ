
--Simplest Specific implementation of tag generation:
--TODO: Ability to change black size via single variable
--all of block partition: Ability to seperate incoming bits into blocks dynamically
--Fix hardcoded values
--May need to change away from using signals in main function and pass sections of the vector instead
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tag is
  Port (
    incoming_bits : in std_logic_vector(15 downto 0);
    output_tag : out std_logic_vector(3 downto 0)
   );
end tag;

architecture Behavioral of tag is

component flip is
  Port (
      flip_block : in std_logic_vector(3 downto 0);
      output_block : out std_logic_vector(3 downto 0)
  );
end component;

component swap is
  Port (
    block_x : in std_logic_vector(3 downto 0);
    block_y : in std_logic_vector(3 downto 0);
    p_x : in unsigned(1 downto 0);
    p_y : in unsigned(1 downto 0);
    s : in unsigned(3 downto 0);
    output_x : out std_logic_vector(3 downto 0);
    output_y : out std_logic_vector(3 downto 0)
   );
end component;

component shift is
  Port (
    r : in unsigned(3 downto 0);
    shift_block : in std_logic_vector(3 downto 0);
    output_block : out std_logic_vector(3 downto 0)
   );
end component;

--May need to reconfigure into doing operations on the vector instead of signals
--To allow dynamicly resized block size
signal block1, block2, block3, block4 : std_logic_vector(3 downto 0);
signal flipped1, flipped2, flipped3, flipped4 : std_logic_vector(3 downto 0);
signal swapped1, swapped2, swapped3, swapped4 : std_logic_vector(3 downto 0);
signal shifted1, shifted2, shifted3, shifted4 : std_logic_vector(3 downto 0);
signal xor_block : std_logic_vector(3 downto 0); 

begin

block1 <= incoming_bits(3 downto 0);
block2 <= incoming_bits(7 downto 4);
block3 <= incoming_bits(11 downto 8);
block4 <= incoming_bits(15 downto 12);

flip1: flip port map ( flip_block => block1, output_block=>flipped1);
flip2: flip port map ( flip_block => block2, output_block=>flipped2);
flip3: flip port map ( flip_block => block3, output_block=>flipped3);
flip4: flip port map ( flip_block => block4, output_block=>flipped4);

swap1: swap port map (
    block_x => flipped1,
    block_y => flipped2,
    p_x => "10",
    p_y => "00",
    s => "11",
    output_x => swapped1,
    output_y => swapped2
);

swap2: swap port map (
    block_x => flipped3,
    block_y => flipped4,
    p_x => "01",
    p_y => "01",
    s => "01",
    output_x => swapped3,
    output_y => swapped4
);

shift1: shift port map (r=>"0001", shift_block => swapped1, output_block => shifted1);
shift2: shift port map (r=>"0010", shift_block => swapped2, output_block => shifted2);
shift3: shift port map (r=>"0100", shift_block => swapped3, output_block => shifted3);
shift4: shift port map (r=>"1011", shift_block => swapped4, output_block => shifted4);

xor_block <= shifted1 xor shifted2 xor shifted3 xor shifted4;

output_tag <= xor_block;

end Behavioral;

---Flip
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity flip is
  Port (
    flip_block : in std_logic_vector(3 downto 0);
    output_block : out std_logic_vector(3 downto 0)
   );
end flip;

architecture Behavioral of flip is

begin

output_block <= not flip_block;

end Behavioral;

---Swap
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--NOTE: 's' must be less than or equal to the size of blocks, or you get an error
--because we're reading from block x and y but making changes to tempx and tempy
entity swap is
  Port (
    block_x : in std_logic_vector(3 downto 0);
    block_y : in std_logic_vector(3 downto 0);
    p_x : in unsigned(1 downto 0);
    p_y : in unsigned(1 downto 0);
    s : in unsigned(3 downto 0);
    output_x : out std_logic_vector(3 downto 0);
    output_y : out std_logic_vector(3 downto 0)
   );
end swap;

architecture Behavioral of swap is

signal result : std_logic_vector(3 downto 0);

begin

  process(block_x, block_y, p_x, p_y, s)
    variable pos_x : integer;
    variable pos_y : integer;
    variable temp_x_bit : std_logic;
    variable temp_y_bit : std_logic;
    variable temp_x : std_logic_vector(3 downto 0);
    variable temp_y : std_logic_vector(3 downto 0);        
  begin
    temp_x := block_x;
    temp_y := block_y;
    
    for i in 0 to to_integer(s) - 1 loop
      pos_x := (to_integer(p_x) + i) mod 4;
      pos_y := (to_integer(p_y) + i) mod 4;
        
      temp_x_bit := block_x(pos_x);
      temp_y_bit := block_y(pos_y);
        
      temp_x(pos_x) := temp_y_bit;
      temp_y(pos_y) := temp_x_bit;
    end loop;
    
    output_x <= temp_x;
    output_y <= temp_y;    
  end process; 
end Behavioral;

---Shift
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity shift is
  Port (
    r : in unsigned(3 downto 0);
    shift_block : in std_logic_vector(3 downto 0);
    output_block : out std_logic_vector(3 downto 0)
   );
end shift;

architecture Behavioral of shift is

begin

  process(r, shift_block)
    variable temp_block : std_logic_vector(3 downto 0);
  begin
    temp_block := shift_block;
    
    for i in 1 to to_integer(r) loop
      temp_block := temp_block(2 downto 0) & temp_block(3);
    end loop;
  
    output_block <= temp_block;
  end process;

end Behavioral;
