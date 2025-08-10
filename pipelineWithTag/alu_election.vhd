library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;

entity alu_election is
    generic ( N        : integer := 16;
              T        : integer := 8;
              BF       : integer;      
              R        : integer );
    port ( opcode    : in  std_logic_vector(3 downto 0);
           src_a     : in  std_logic_vector(N-1 downto 0);
           src_b     : in  std_logic_vector(N-1 downto 0);
           output    : out std_logic_vector(N-1 downto 0);
           output2   : out std_logic_vector(N-1 downto 0);
           branch    : out std_logic;
           ackn      : out std_logic;
           -- Election-specific outputs
           district_id  : out std_logic_vector(1 downto 0);
           candidate_id : out std_logic_vector(1 downto 0);
           tally_increment : out std_logic_vector(7 downto 0);
           tag_valid    : out std_logic );
end alu_election;

architecture behavioural of alu_election is

    component tag_election is
        generic ( N : integer := 16; T : integer := 8;
                  BF : std_logic_vector(7 downto 0) := "00000001";
                  BX, BY, PX, PY, S, BS, R : integer );
        port ( record_in : in  std_logic_vector(N-1 downto 0);
               tag_out   : out std_logic_vector(T-1 downto 0);
               debug_padded : out std_logic_vector(((N+T-1)/T)*T-1 downto 0);
               debug_flipped : out std_logic_vector(((N+T-1)/T)*T-1 downto 0);
               debug_swapped : out std_logic_vector(((N+T-1)/T)*T-1 downto 0);
               debug_shifted : out std_logic_vector(((N+T-1)/T)*T-1 downto 0) );
    end component;

    signal tag_output : std_logic_vector(T-1 downto 0);
    signal zero : std_logic_vector(N-1 downto 0);
    signal debug_padded, debug_flipped, debug_swapped, debug_shifted : std_logic_vector(((N+T-1)/T)*T-1 downto 0);
    
    -- Instruction opcodes (keeping your existing ones + new election ones)
    constant OP_NOOP     : std_logic_vector(3 downto 0) := X"0";
    constant OP_BUFGET   : std_logic_vector(3 downto 0) := X"1";
    constant OP_MEMPUT   : std_logic_vector(3 downto 0) := X"2";
    constant OP_PAR      : std_logic_vector(3 downto 0) := X"3";
    constant OP_TAG      : std_logic_vector(3 downto 0) := X"4";
    constant OP_ACKN     : std_logic_vector(3 downto 0) := X"5";
    constant OP_RECGET   : std_logic_vector(3 downto 0) := X"6"; -- Get record fields
    constant OP_TAGGEN   : std_logic_vector(3 downto 0) := X"7"; -- Generate election tag
    constant OP_TAGCHK   : std_logic_vector(3 downto 0) := X"8"; -- Check tag validity
    constant OP_TALLYUPD : std_logic_vector(3 downto 0) := X"9"; -- Update tally
    constant OP_BEQ      : std_logic_vector(3 downto 0) := X"A";
    constant OP_BEQZ     : std_logic_vector(3 downto 0) := X"B";
    constant OP_B        : std_logic_vector(3 downto 0) := X"C";

begin
    zero <= (others => '0');
    
    -- Branch logic (same as your original)
    branch <= '1' when ( (opcode = OP_BEQ and src_a = src_b) or
                         (opcode = OP_BEQZ and src_a = zero) or
                         (opcode = OP_B) ) else '0';

    -- Enhanced tag generator using your components with election parameters
    tag_generator : tag_election 
    generic map ( N => N, T => T, 
                  BF => "00000001",  -- Example: flip block 0
                  BX => 0, BY => 1,  -- Swap blocks 0 and 1
                  PX => 0, PY => 1,  -- Swap positions
                  S => 2,            -- Segment size
                  BS => 1, R => R )  -- Shift block 1 by R
    port map ( record_in => src_a, 
               tag_out => tag_output,
               debug_padded => debug_padded,
               debug_flipped => debug_flipped,
               debug_swapped => debug_swapped,
               debug_shifted => debug_shifted );

    alu_process : process (opcode, src_a, src_b, tag_output) is
        variable record_data : std_logic_vector(N-1 downto 0);
        variable received_tag : std_logic_vector(T-1 downto 0);
        variable computed_tag : std_logic_vector(T-1 downto 0);
    begin
        -- Default outputs
        ackn <= '0';
        tag_valid <= '0';
        district_id <= "00";
        candidate_id <= "00";
        tally_increment <= (others => '0');
        output <= (others => '0');
        output2 <= (others => '0');
        
        case opcode is
            when OP_PAR =>
                -- Parity calculation (your original)
                output(N-1 downto 1) <= (others => '0');
                output(0) <= xor_reduce(src_a);
                
            when OP_TAG =>
                -- Legacy tag operation (your original, keeping for compatibility)
                output(T-1 downto 0) <= tag_output;
                output(N-1 downto T) <= (others => '0');
                
            when OP_RECGET =>
                -- Extract fields from election record
                -- Format: | district_id(2) | candidate_id(2) | tally(8) | tag(4) |
                district_id <= src_a(15 downto 14);      -- Top 2 bits
                candidate_id <= src_a(13 downto 12);     -- Next 2 bits  
                tally_increment <= src_a(11 downto 4);   -- Tally (8 bits)
                output <= X"00" & src_a(11 downto 4);    -- Tally to register
                output2 <= X"000" & src_a(3 downto 0);   -- Tag to register
                
            when OP_TAGGEN =>
                -- Generate tag using new election algorithm
                output(T-1 downto 0) <= tag_output;
                output(N-1 downto T) <= (others => '0');
                
            when OP_TAGCHK =>
                -- Compare tags: src_a = received tag, src_b = computed tag
                received_tag := src_a(T-1 downto 0);
                computed_tag := src_b(T-1 downto 0);
                
                if received_tag = computed_tag then
                    output(0) <= '1';   -- Tags match
                    tag_valid <= '1';
                else
                    output(0) <= '0';   -- Tags don't match
                    tag_valid <= '0';
                end if;
                output(N-1 downto 1) <= (others => '0');
                
            when OP_TALLYUPD =>
                -- Prepare data for tally table update
                district_id <= src_a(15 downto 14);
                candidate_id <= src_a(13 downto 12);
                tally_increment <= src_b(7 downto 0);    -- Increment from src_b
                output <= src_b;  -- Pass through increment value
                tag_valid <= '1'; -- Signal to update tally
                
            when OP_ACKN =>
                ackn <= '1';
                output <= src_a;
                
            when others =>
                output <= src_a;
                output2 <= src_b;
        end case;
    end process;
    
end behavioural;