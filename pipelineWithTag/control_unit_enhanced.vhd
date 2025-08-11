library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity control_unit_enhanced is
    port ( opcode     : in  std_logic_vector(3 downto 0);
           buf_get    : out std_logic;
           mem_put    : out std_logic;
           reg_write  : out std_logic;
           reg_write2 : out std_logic;
           buf_to_reg : out std_logic;
           -- Election signals
           tally_read : out std_logic;
           tally_write: out std_logic );
end control_unit_enhanced;

architecture structural of control_unit_enhanced is
    constant OP_NOOP     : std_logic_vector(3 downto 0) := X"0";
    constant OP_BUFGET   : std_logic_vector(3 downto 0) := X"1";
    constant OP_MEMPUT   : std_logic_vector(3 downto 0) := X"2";
    constant OP_TAG      : std_logic_vector(3 downto 0) := X"4";
    constant OP_ACKN     : std_logic_vector(3 downto 0) := X"5";
    constant OP_RECGET   : std_logic_vector(3 downto 0) := X"6";
    constant OP_TAGGEN   : std_logic_vector(3 downto 0) := X"7";
    constant OP_TAGCHK   : std_logic_vector(3 downto 0) := X"8";
    constant OP_TALLYUPD : std_logic_vector(3 downto 0) := X"9";
    constant OP_BEQ      : std_logic_vector(3 downto 0) := X"A";
    constant OP_BEQZ     : std_logic_vector(3 downto 0) := X"B";
    constant OP_B        : std_logic_vector(3 downto 0) := X"C";
begin
    buf_get    <= '1' when (opcode = OP_BUFGET or opcode = OP_RECGET) else '0';
    mem_put    <= '1' when opcode = OP_MEMPUT else '0';
    buf_to_reg <= '1' when (opcode = OP_BUFGET or opcode = OP_RECGET) else '0';
    
    tally_read  <= '0';  
    tally_write <= '1' when opcode = OP_TALLYUPD else '0';
    
    reg_write  <= '1' when ( opcode = OP_BUFGET or opcode = OP_RECGET or
                            opcode = OP_TAG or
                            opcode = OP_TAGGEN or opcode = OP_TAGCHK ) else '0';
                            
    reg_write2 <= '1' when (opcode = OP_BUFGET or opcode = OP_RECGET) else '0';
end structural;