library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity instruction_memory_election is
    generic (CORE_NO: integer := 1);
    port ( reset    : in  std_logic;
           clk      : in  std_logic;
           addr_in  : in  std_logic_vector(3 downto 0);
           insn_out : out std_logic_vector(15 downto 0) );
end instruction_memory_election;

architecture behavioral of instruction_memory_election is
    type mem_array is array(0 to 15) of std_logic_vector(15 downto 0);
    signal sig_insn_mem : mem_array;
begin
    mem_process: process ( clk, addr_in ) is
        variable var_insn_mem : mem_array;
        variable var_addr     : integer;
    begin
        if (falling_edge(reset)) then
            if (CORE_NO = 1) then
                -- Election Center Program
                -- Loop: Get record -> Validate tag -> Update tally -> Acknowledge
                
                -- start:
                var_insn_mem(0)  := X"6120";  -- recget $1, $2, $0 (get record: $1=data, $2=tag)
                var_insn_mem(1)  := X"B100";  -- beqz $1, start (if no data, loop)
                var_insn_mem(2)  := X"7340";  -- taggen $3, $1 (generate tag from data)
                var_insn_mem(3)  := X"8230";  -- tagchk $2, $3 (compare received vs computed)
                var_insn_mem(4)  := X"B008";  -- beqz $0, drop (if tags don't match, drop)
                var_insn_mem(5)  := X"9120";  -- tallyupd $1, $2 (update tally table)
                var_insn_mem(6)  := X"5100";  -- ackn $1 (acknowledge)
                var_insn_mem(7)  := X"C000";  -- b start (loop back)
                -- drop:
                var_insn_mem(8)  := X"0000";  -- noop (could log error here)
                var_insn_mem(9)  := X"C000";  -- b start (continue processing)
                var_insn_mem(10) := X"0000";  -- noop
                var_insn_mem(11) := X"0000";  -- noop
                var_insn_mem(12) := X"0000";  -- noop
                var_insn_mem(13) := X"0000";  -- noop
                var_insn_mem(14) := X"0000";  -- noop
                var_insn_mem(15) := X"0000";  -- noop
                
            else 
                -- District Program (simpler - just send data with tags)
                var_insn_mem(0)  := X"1320";  -- bufget $3, $2, $0
                var_insn_mem(1)  := X"B300";  -- beqz $3, start
                var_insn_mem(2)  := X"7430";  -- taggen $4, $3 (generate tag)
                var_insn_mem(3)  := X"2340";  -- memput $3, $4 (send data + tag)
                var_insn_mem(4)  := X"C000";  -- b start
                var_insn_mem(5)  := X"0000";  -- noop
                var_insn_mem(6)  := X"0000";  -- noop
                var_insn_mem(7)  := X"0000";  -- noop
                var_insn_mem(8)  := X"0000";  -- noop
                var_insn_mem(9)  := X"0000";  -- noop
                var_insn_mem(10) := X"0000";  -- noop
                var_insn_mem(11) := X"0000";  -- noop
                var_insn_mem(12) := X"0000";  -- noop
                var_insn_mem(13) := X"0000";  -- noop
                var_insn_mem(14) := X"0000";  -- noop
                var_insn_mem(15) := X"0000";  -- noop
            end if;
        end if;
        
        var_addr := conv_integer(addr_in);
        insn_out <= var_insn_mem(var_addr);
        sig_insn_mem <= var_insn_mem;
    end process;
end behavioral;