library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity enhanced_control_unit is
    port ( opcode     : in  std_logic_vector(3 downto 0);
           reg_dst    : out std_logic;
           reg_write  : out std_logic;
           alu_src    : out std_logic;
           mem_write  : out std_logic;
           mem_to_reg : out std_logic;
           sw_to_reg  : out std_logic;
           tag_enable : out std_logic );
end enhanced_control_unit;

architecture behavioral of enhanced_control_unit is
    -- Your existing opcodes (copied from your control_unit.vhd)
    constant OP_LOAD    : std_logic_vector(3 downto 0) := "0001";
    constant OP_STORE   : std_logic_vector(3 downto 0) := "0011";
    constant OP_BEQ     : std_logic_vector(3 downto 0) := "0100";
    constant OP_LOADLED : std_logic_vector(3 downto 0) := "0101";
    constant OP_READSW  : std_logic_vector(3 downto 0) := "0110";
    constant OP_ADD     : std_logic_vector(3 downto 0) := "1000";
    
    -- NEW: Tag validation opcodes
    constant OP_FLIP    : std_logic_vector(3 downto 0) := "1101";
    constant OP_SWAP    : std_logic_vector(3 downto 0) := "1110";
    constant OP_SHIFT   : std_logic_vector(3 downto 0) := "1111";
    constant OP_BXOR    : std_logic_vector(3 downto 0) := "1100";
    
begin
    -- Your existing control logic + tag extensions
    reg_dst    <= '1' when (opcode = OP_ADD or 
                           opcode = OP_FLIP or opcode = OP_SWAP or 
                           opcode = OP_SHIFT or opcode = OP_BXOR) else '0';
    
    reg_write  <= '1' when (opcode = OP_ADD or opcode = OP_LOAD or opcode = OP_READSW or
                           opcode = OP_FLIP or opcode = OP_SWAP or 
                           opcode = OP_SHIFT or opcode = OP_BXOR) else '0';
    
    alu_src    <= '1' when (opcode = OP_LOAD or opcode = OP_STORE or opcode = OP_LOADLED) else '0';
    
    mem_write  <= '1' when opcode = OP_STORE else '0';
    
    mem_to_reg <= '1' when opcode = OP_LOAD else '0';
    
    sw_to_reg  <= '1' when opcode = OP_READSW else '0';
    
    -- NEW: Tag operation enable
    tag_enable <= '1' when (opcode = OP_FLIP or opcode = OP_SWAP or 
                           opcode = OP_SHIFT or opcode = OP_BXOR) else '0';
    
end behavioral;