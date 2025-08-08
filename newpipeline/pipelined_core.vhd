library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pipelined_core is
    port ( reset  : in  std_logic;
           b_clk    : in  std_logic;
           sw     : in  std_logic_vector(15 downto 0);
           btnC   : in  std_logic;
           btnL   : in  std_logic;
           btnU   : in  std_logic;
           btnD   : in  std_logic;
           an    : out std_logic_vector(3 downto 0);
           seg   : out std_logic_vector(6 downto 0);
           led  : out std_logic_vector(15 downto 0));
end pipelined_core;

architecture structural of pipelined_core is

component program_counter is
    port ( reset    : in  std_logic;
           clk      : in  std_logic;
           addr_in  : in  std_logic_vector(3 downto 0);
           addr_out : out std_logic_vector(3 downto 0) );
end component;

component instruction_memory is
    port ( reset    : in  std_logic;
           clk      : in  std_logic;
           addr_in  : in  std_logic_vector(3 downto 0);
           insn_out : out std_logic_vector(15 downto 0) );
end component;

component mux_2to1_4b is
    port ( mux_select : in  std_logic;
           data_a     : in  std_logic_vector(3 downto 0);
           data_b     : in  std_logic_vector(3 downto 0);
           data_out   : out std_logic_vector(3 downto 0) );
end component;

component mux_2to1_16b is
    port ( mux_select : in  std_logic;
           data_a     : in  std_logic_vector(15 downto 0);
           data_b     : in  std_logic_vector(15 downto 0);
           data_out   : out std_logic_vector(15 downto 0) );
end component;

component register_file is
    port ( reset           : in  std_logic;
           b_clk             : in  std_logic;
           clk             : in  std_logic;
           read_register : in  std_logic_vector(1 downto 0);
           write_enable    : in  std_logic;
           write_register  : in  std_logic_vector(1 downto 0);
           write_data      : in  std_logic_vector(15 downto 0);
           read_data     : out std_logic_vector(15 downto 0);
           led : out std_logic_vector(15 downto 0);
            an : out STD_LOGIC_VECTOR(3 downto 0);
            seg : out STD_LOGIC_VECTOR(6 downto 0));
end component;

component adder_4b is
    port ( src_a     : in  std_logic_vector(3 downto 0);
           src_b     : in  std_logic_vector(3 downto 0);
           sum       : out std_logic_vector(3 downto 0);
           carry_out : out std_logic );
end component;

component adder_16b is
    port ( src_a     : in  std_logic_vector(15 downto 0);
           src_b     : in  std_logic_vector(15 downto 0);
           sum       : out std_logic_vector(15 downto 0);
           carry_out : out std_logic );
end component;

component tag is
generic(
    tag_size : integer := 3;
    bit_size : integer := 7   
);
port (
    incoming_bits : in std_logic_vector(bit_size downto 0);
    output_tag : out std_logic_vector(tag_size downto 0)
);
end component;

component debounce IS
    PORT( clk : IN std_logic;
          noisy_sig : IN std_logic;
          clean_sig : OUT std_logic);
END component;

constant c_tag_size : integer := 3;
constant c_bit_size : integer := 7;
constant c_cand_size : integer := 2;

type if_id_reg is record 
    instruction : std_logic_vector(15 downto 0);
end record;

type id_ex_reg is record 
    instruction : std_logic_vector(15 downto 0);
    cand_total: std_logic_vector(15 downto 0);
end record;

type ex_wb_reg is record 
    instruction : std_logic_vector(15 downto 0);
    wr : std_logic;
    cand_total: std_logic_vector(15 downto 0);
end record;

signal sig_next_pc              : std_logic_vector(3 downto 0);
signal sig_curr_pc              : std_logic_vector(3 downto 0);
signal sig_one_4b               : std_logic_vector(3 downto 0);
signal sig_one_16b               : std_logic_vector(15 downto 0);
signal sig_pc_carry_out         : std_logic;
signal sig_tags_match         : std_logic;
signal sig_insn                 : std_logic_vector(15 downto 0);
signal sig_output_tag           : std_logic_vector(c_tag_size downto 0);
signal if_id : if_id_reg;
signal id_ex : id_ex_reg;
signal ex_wb : ex_wb_reg; 
signal clk : std_logic;
signal s_btn : std_logic;

begin
    -- clk <= b_clk;
    debounce_inst : debounce
    port map (
        clk   => clk,
        noisy_sig  => btnC,
        clean_sig  => led(1) 
    );

    debounce_inst1 : debounce
    port map (
        clk   => clk,
        noisy_sig  => btnL,
        clean_sig  => s_btn 
    );

    led(0) <= s_btn;
    debounce_in2st : debounce
    port map (
        clk   => clk,
        noisy_sig  => btnU,
        clean_sig  => led(2)
    );
    de3bounce_inst : debounce
    port map (
        clk   => clk,
        noisy_sig  => btnD,
        clean_sig  => led(3)
    );
    clk <= s_btn;
    -- led(0) <= s_btn;

    sig_one_4b <= "0001";
    sig_one_16b <= "0000000000000001";

    pc : program_counter
    port map ( reset    => reset,
               clk      => clk,
               addr_in  => sig_next_pc,
               addr_out => sig_curr_pc ); 

    next_pc : adder_4b 
    port map ( src_a     => sig_curr_pc, 
               src_b     => sig_one_4b,
               sum       => sig_next_pc,   
               carry_out => sig_pc_carry_out );
    
    insn_mem : instruction_memory 
    port map ( reset    => reset,
               clk      => clk,
               addr_in  => sig_curr_pc,
               insn_out => if_id.instruction );

    reg_file : register_file 
    port map ( reset           => reset, 
               b_clk             => b_clk,
               clk             => clk,
               read_register => if_id.instruction(13 downto 12),
               write_enable    => ex_wb.wr,
               write_register  => ex_wb.instruction(13 downto 12),
               write_data      => ex_wb.cand_total,
               read_data     => id_ex.cand_total,
               led => led,
               an           => an,
               seg  => seg);
    id_ex.instruction <= if_id.instruction;
    
    increment : adder_16b
    port map ( src_a    => id_ex.cand_total,
               src_b    => sig_one_16b,
               sum      => ex_wb.cand_total,
               carry_out => open);
    
    tag_generator : tag
    port map ( incoming_bits  => id_ex.instruction(11 downto 4),
               output_tag => sig_output_tag);
    
    ex_wb.instruction <= id_ex.instruction;
    sig_tags_match <= '1' when sig_output_tag = id_ex.instruction(3 downto 0) else '0';
    ex_wb.wr <= sig_tags_match and not id_ex.instruction(14);

end structural;
