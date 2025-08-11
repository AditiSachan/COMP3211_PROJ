library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

entity alu_election is
    generic ( N        : integer := 16;
              T        : integer := 4;  
              b_size : integer := 31;
              secret_key_width : integer := 32 );
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

    -- Tag generation integration
    component tag is
      generic(
        tag_size  : integer := 4;    -- T
        bit_size  : integer := 31;   -- record width
        key_width : integer := 32    -- secret_key width
      );
      port(
        incoming_bits : in  std_logic_vector(bit_size-1 downto 0);
        secret_key    : in  std_logic_vector(key_width-1 downto 0);
        output_tag    : out std_logic_vector(tag_size-1 downto 0)
      );
    end component;
    
    signal gen_record : std_logic_vector(b_size-1 downto 0);
    signal p_secret_key : std_logic_vector(secret_key_width-1 downto 0) :=
                            x"003101A0";  -- 32 bits in hex
    signal tag_output : std_logic_vector(T-1 downto 0);
    signal zero : std_logic_vector(N-1 downto 0);
    
    constant OP_NOOP     : std_logic_vector(3 downto 0) := X"0";
    constant OP_BUFGET   : std_logic_vector(3 downto 0) := X"1";
    constant OP_MEMPUT   : std_logic_vector(3 downto 0) := X"2";
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
    
    -- Branch logic
    branch <= '1' when ( (opcode = OP_BEQ and src_a = src_b) or
                         (opcode = OP_BEQZ and src_a = zero) or
                         (opcode = OP_B) ) else '0';
    
    -- Tag generation integration
    gen_record <= (30 downto 12 => '0') & src_a(11 downto 0);

    tag_generation: tag port map (
        incoming_bits => gen_record,
        secret_key    => p_secret_key,
        output_tag    => tag_output
    );

    alu_process : process (opcode, src_a, src_b, tag_output) is
        variable record_data : std_logic_vector(N-1 downto 0);
        variable received_tag : std_logic_vector(T-1 downto 0);
        variable computed_tag : std_logic_vector(T-1 downto 0);
    begin
        -- Default outputs - Set defaults for ALL outputs
        ackn <= '0';
        tag_valid <= '0';
        district_id <= "00";
        candidate_id <= "00";
        tally_increment <= (others => '0');
        output <= (others => '0');
        output2 <= (others => '0');
        
        case opcode is
            when OP_TAG =>
                output(T-1 downto 0) <= tag_output;
                output(N-1 downto T) <= (others => '0');
                
            when OP_RECGET =>
                -- Extract fields from election record ONLY during RECGET
                district_id <= src_a(15 downto 14);      -- Top 2 bits
                candidate_id <= src_a(13 downto 12);     -- Next 2 bits  
                tally_increment <= src_a(11 downto 4);   -- Tally (8 bits)
                output <= X"00" & src_a(11 downto 4);    -- Tally to register
                output2 <= X"000" & src_a(3 downto 0);   -- Tag to register
                
            when OP_TAGGEN =>
                -- Generate tag using election algorithm
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