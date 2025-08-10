library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tag_election is
    generic ( 
        N : integer := 15;        -- Record size 
        T : integer := 4;         -- Tag size
        -- Secret key parameters (can be changed for different elections)
        BF : std_logic_vector(7 downto 0) := "00000001";  -- Block flip mask
        BX : integer := 0;        -- Swap block X
        BY : integer := 1;        -- Swap block Y  
        PX : integer := 0;        -- Swap position X
        PY : integer := 1;        -- Swap position Y
        S  : integer := 2;        -- Swap segment size
        BS : integer := 1;        -- Shift block select
        R  : integer := 2         -- Shift amount
    );
    port ( 
        record_in : in std_logic_vector(N-1 downto 0);
        tag_out   : out std_logic_vector(T-1 downto 0);
        -- Debug outputs (optional)
        debug_padded : out std_logic_vector(((N+T-1)/T)*T-1 downto 0);
        debug_flipped : out std_logic_vector(((N+T-1)/T)*T-1 downto 0);
        debug_swapped : out std_logic_vector(((N+T-1)/T)*T-1 downto 0);
        debug_shifted : out std_logic_vector(((N+T-1)/T)*T-1 downto 0)
    );
end tag_election;

architecture structural of tag_election is
    
    constant NUM_BLOCKS : integer := (N + T - 1) / T;
    constant PADDED_SIZE : integer := NUM_BLOCKS * T;
    
    signal padded_record : std_logic_vector(PADDED_SIZE-1 downto 0);
    signal blocks_after_flip : std_logic_vector(PADDED_SIZE-1 downto 0);
    signal blocks_after_swap : std_logic_vector(PADDED_SIZE-1 downto 0);
    signal blocks_after_shift : std_logic_vector(PADDED_SIZE-1 downto 0);
    
    component flip is
        generic(tag_size : integer := 4);
        port ( flip_block : in std_logic_vector(tag_size - 1 downto 0);
               output_block : out std_logic_vector(tag_size - 1 downto 0) );
    end component;
    
    component shift is
        generic(tag_size : integer := 4);
        port ( r : in std_logic_vector(tag_size - 1 downto 0);
               shift_block : in std_logic_vector(tag_size - 1 downto 0);
               output_block : out std_logic_vector(tag_size - 1 downto 0) );
    end component;
    
    component swap is
        generic(tag_size : integer := 4);
        port ( block_x, block_y : in std_logic_vector(tag_size - 1 downto 0);
               p_x, p_y, s : in std_logic_vector(tag_size - 1 downto 0);
               output_x, output_y : out std_logic_vector(tag_size - 1 downto 0) );
    end component;
    
    component xor_blocks is
        generic(tag_size : integer := 4; num_blocks : integer := 4);
        port ( blocks : in std_logic_vector(num_blocks * tag_size - 1 downto 0);
               result : out std_logic_vector(tag_size - 1 downto 0) );
    end component;

begin
    
    -- 1. Block Partition with zero padding
    process(record_in)
    begin
        padded_record <= (others => '0');
        padded_record(N-1 downto 0) <= record_in;
    end process;
    
    -- 2. Flip operations 
    gen_flip: for i in 0 to NUM_BLOCKS-1 generate
        flip_block_i: if i < 8 and BF(i) = '1' generate
            flip_inst: flip
                generic map(tag_size => T)
                port map(
                    flip_block => padded_record((i+1)*T-1 downto i*T),
                    output_block => blocks_after_flip((i+1)*T-1 downto i*T)
                );
        end generate;
        
        no_flip_i: if i >= 8 or BF(i) = '0' generate
            blocks_after_flip((i+1)*T-1 downto i*T) <= padded_record((i+1)*T-1 downto i*T);
        end generate;
    end generate;
    
    -- 3. Swap operation (only if both blocks exist)
    gen_swap: if BX < NUM_BLOCKS and BY < NUM_BLOCKS and BX /= BY generate
        swap_inst: swap
            generic map(tag_size => T)
            port map(
                block_x => blocks_after_flip((BX+1)*T-1 downto BX*T),
                block_y => blocks_after_flip((BY+1)*T-1 downto BY*T),
                p_x => std_logic_vector(to_unsigned(PX, T)),
                p_y => std_logic_vector(to_unsigned(PY, T)),
                s => std_logic_vector(to_unsigned(S, T)),
                output_x => blocks_after_swap((BX+1)*T-1 downto BX*T),
                output_y => blocks_after_swap((BY+1)*T-1 downto BY*T)
            );
    end generate;
    
    no_swap: if not (BX < NUM_BLOCKS and BY < NUM_BLOCKS and BX /= BY) generate
        blocks_after_swap <= blocks_after_flip;
    end generate;
    
    -- Copy non-swapped blocks
    gen_copy_swap: for i in 0 to NUM_BLOCKS-1 generate
        copy_block_i: if i /= BX and i /= BY generate
            blocks_after_swap((i+1)*T-1 downto i*T) <= blocks_after_flip((i+1)*T-1 downto i*T);
        end generate;
    end generate;
    
    -- 4. Shift operation (only if block exists)
    gen_shift: if BS < NUM_BLOCKS generate
        shift_inst: shift
            generic map(tag_size => T)
            port map(
                r => std_logic_vector(to_unsigned(R, T)),
                shift_block => blocks_after_swap((BS+1)*T-1 downto BS*T),
                output_block => blocks_after_shift((BS+1)*T-1 downto BS*T)
            );
    end generate;
    
    no_shift: if not (BS < NUM_BLOCKS) generate
        blocks_after_shift <= blocks_after_swap;
    end generate;
    
    -- Copy non-shifted blocks
    gen_copy_shift: for i in 0 to NUM_BLOCKS-1 generate
        copy_shift_i: if i /= BS generate
            blocks_after_shift((i+1)*T-1 downto i*T) <= blocks_after_swap((i+1)*T-1 downto i*T);
        end generate;
    end generate;
    
    -- 5. XOR all blocks
    xor_inst: xor_blocks
        generic map(tag_size => T, num_blocks => NUM_BLOCKS)
        port map(
            blocks => blocks_after_shift,
            result => tag_out
        );
    
    -- Debug outputs
    debug_padded <= padded_record;
    debug_flipped <= blocks_after_flip;
    debug_swapped <= blocks_after_swap;
    debug_shifted <= blocks_after_shift;

end structural;