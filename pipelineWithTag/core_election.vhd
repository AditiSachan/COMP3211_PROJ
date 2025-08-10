---------------------------------------------------------------------------
-- core_election.vhd - Enhanced Core with Election Tallying System
-- Based on your existing core.vhd with election extensions
---------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity core_election is
    generic ( N        : integer := 16;
              T        : integer := 8;
              CORE_NO  : integer := 1;
               BF       : integer := 1;      -- Must have default value
              R        : integer := 2 );
    port ( reset         : in  std_logic;
           clk           : in  std_logic; 
           bufget        : out std_logic;
           buf_value1    : in std_logic_vector(N-1 downto 0);
           buf_value2    : in std_logic_vector(N-1 downto 0);
           ackn_data     : out std_logic_vector(N-1 downto 0);
           -- Election system outputs for display/debugging
           total_candidate_0 : out std_logic_vector(7 downto 0);
           total_candidate_1 : out std_logic_vector(7 downto 0);
           total_candidate_2 : out std_logic_vector(7 downto 0);
           total_candidate_3 : out std_logic_vector(7 downto 0) );
end core_election;

architecture structural of core_election is

-- All your existing component declarations (keeping them identical)
component program_counter is
    port ( reset    : in  std_logic;
           stall    : in std_logic;
           clk      : in  std_logic;
           addr_in  : in  std_logic_vector(3 downto 0);
           addr_out : out std_logic_vector(3 downto 0) );
end component;

component instruction_memory_election is
    generic (CORE_NO: integer := 1);
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

component mux_2to1_Nb is
    generic (N: integer := 16);
    port ( mux_select : in  std_logic;
           data_a     : in  std_logic_vector(N-1 downto 0);
           data_b     : in  std_logic_vector(N-1 downto 0);
           data_out   : out std_logic_vector(N-1 downto 0) );
end component;

component control_unit_enhanced is
    port ( opcode     : in  std_logic_vector(3 downto 0);
           buf_get    : out std_logic;
           mem_put    : out std_logic;
           reg_write  : out std_logic;
           reg_write2 : out std_logic;
           buf_to_reg : out std_logic;
           tally_read : out std_logic;
           tally_write: out std_logic );
end component;

component register_file is
    generic (N: integer := 16);
    port ( reset           : in  std_logic;
           clk             : in  std_logic;
           read_register_a : in  std_logic_vector(3 downto 0);
           read_register_b : in  std_logic_vector(3 downto 0);
           write_enable    : in  std_logic;
           write_enable2   : in  std_logic;
           write_register  : in  std_logic_vector(3 downto 0);
           write_register2 : in  std_logic_vector(3 downto 0);
           write_data      : in  std_logic_vector(N-1 downto 0);
           write_data2     : in  std_logic_vector(N-1 downto 0);
           read_data_a     : out std_logic_vector(N-1 downto 0);
           read_data_b     : out std_logic_vector(N-1 downto 0) );
end component;

component adder_4b is
    port ( src_a     : in  std_logic_vector(3 downto 0);
           src_b     : in  std_logic_vector(3 downto 0);
           sum       : out std_logic_vector(3 downto 0);
           carry_out : out std_logic );
end component;

component alu_election is
    generic ( N        : integer := 16;
              T        : integer := 4;  
              b_size   : integer := 31;
              secret_key_width : integer := 32 );
    port ( opcode    : in  std_logic_vector(3 downto 0);
           src_a     : in  std_logic_vector(N-1 downto 0);
           src_b     : in  std_logic_vector(N-1 downto 0);
           output    : out std_logic_vector(N-1 downto 0);
           output2   : out std_logic_vector(N-1 downto 0);
           branch    : out std_logic;
           ackn      : out std_logic;
           district_id  : out std_logic_vector(1 downto 0);
           candidate_id : out std_logic_vector(1 downto 0);
           tally_increment : out std_logic_vector(7 downto 0);
           tag_valid    : out std_logic );
end component;


component mem is
    generic (N: integer := 16; CORE_NO: integer := 1);
    port ( clk          : in  std_logic;
           reset          : in  std_logic;
           memput       : in  std_logic;
           data1_in     : in std_logic_vector(N-1 downto 0);
           data2_in     : in std_logic_vector(N-1 downto 0) );
end component;

-- New election component
component tally_table is
    generic ( N_DISTRICTS : integer := 4;
              N_CANDIDATES: integer := 4;
              TALLY_WIDTH : integer := 8 );
    port ( clk          : in  std_logic;
           reset        : in  std_logic;
           write_enable : in  std_logic;
           district_id  : in  std_logic_vector(1 downto 0);
           candidate_id : in  std_logic_vector(1 downto 0);
           increment    : in  std_logic_vector(TALLY_WIDTH-1 downto 0);
           total_candidate_0 : out std_logic_vector(TALLY_WIDTH-1 downto 0);
           total_candidate_1 : out std_logic_vector(TALLY_WIDTH-1 downto 0);
           total_candidate_2 : out std_logic_vector(TALLY_WIDTH-1 downto 0);
           total_candidate_3 : out std_logic_vector(TALLY_WIDTH-1 downto 0) );
end component;

-- All your existing pipeline register components (unchanged)
component pipeline_reg1_if_id is
    port (
        clk          : in  std_logic;
        sync_reset   : in std_logic;
        next_pc_in   : in  std_logic_vector(3 downto 0);
        insn_in      : in  std_logic_vector(15 downto 0);
        next_pc_out  : out std_logic_vector(3 downto 0);
        insn_out     : out  std_logic_vector(15 downto 0) );
end component;

component pipeline_reg2_id_ex is
    generic (N: integer := 16);
    port ( stall            : in  std_logic;
           clk              : in  std_logic;
           opcode_in        : in std_logic_vector(3 downto 0);
           bufget_in        : in std_logic;
           memput_in        : in std_logic;
           regwrite_in      : in std_logic;
           regwrite2_in     : in std_logic;
           buftoreg_in      : in std_logic;
           next_pc_in       : in  std_logic_vector(3 downto 0);
           dataA_in         : in  std_logic_vector(N-1 downto 0);
           dataB_in         : in  std_logic_vector(N-1 downto 0);
           rs_in            : in  std_logic_vector(3 downto 0);
           rt_in            : in  std_logic_vector(3 downto 0);
           rd_in            : in  std_logic_vector(3 downto 0);
           insn_in          : in  std_logic_vector(15 downto 0);
           insn_out         : out  std_logic_vector(15 downto 0);
           opcode_out        : out std_logic_vector(3 downto 0);
           bufget_out        : out std_logic;
           memput_out        : out std_logic;
           regwrite_out      : out std_logic;
           regwrite2_out     : out std_logic;
           buftoreg_out      : out std_logic;
           next_pc_out       : out  std_logic_vector(3 downto 0);
           dataA_out         : out  std_logic_vector(N-1 downto 0);
           dataB_out         : out  std_logic_vector(N-1 downto 0);
           rs_out            : out  std_logic_vector(3 downto 0);
           rt_out            : out  std_logic_vector(3 downto 0);
           rd_out            : out  std_logic_vector(3 downto 0) );
end component;

component pipeline_reg3_ex_mem is
    generic (N: integer := 16);
    port ( stall            : in  std_logic;
           clk              : in  std_logic;
           memput_in        : in std_logic;
           bufget_in        : in std_logic;
           regwrite_in      : in std_logic;
           regwrite2_in     : in std_logic;
           buftoreg_in      : in std_logic;
           result_in        : in  std_logic_vector(N-1 downto 0);
           write_data2_in   : in  std_logic_vector(N-1 downto 0);
           write_reg_in     : in  std_logic_vector(3 downto 0);
           write_reg2_in    : in  std_logic_vector(3 downto 0);
           insn_in          : in  std_logic_vector(15 downto 0);
           insn_out         : out  std_logic_vector(15 downto 0);
           memput_out        : out std_logic;
           bufget_out        : out std_logic;
           regwrite_out      : out std_logic;
           regwrite2_out     : out std_logic;
           buftoreg_out      : out std_logic;
           result_out        : out  std_logic_vector(N-1 downto 0);
           write_data2_out   : out  std_logic_vector(N-1 downto 0);
           write_reg_out     : out  std_logic_vector(3 downto 0);
           write_reg2_out    : out  std_logic_vector(3 downto 0) );
end component;

component pipeline_reg4_mem_wb is
    generic (N: integer := 16);
    port ( stall            : in  std_logic;
           clk              : in  std_logic;
           regwrite_in      : in std_logic;
           regwrite2_in     : in std_logic;
           write_data_in     : in  std_logic_vector(N-1 downto 0);
           write_data2_in   : in  std_logic_vector(N-1 downto 0);
           write_reg_in     : in  std_logic_vector(3 downto 0);
           write_reg2_in    : in  std_logic_vector(3 downto 0);
           insn_in          : in  std_logic_vector(15 downto 0);
           insn_out         : out  std_logic_vector(15 downto 0);
           regwrite_out      : out std_logic;
           regwrite2_out     : out std_logic;
           write_data_out         : out  std_logic_vector(N-1 downto 0);
           write_data2_out   : out  std_logic_vector(N-1 downto 0);
           write_reg_out     : out  std_logic_vector(3 downto 0);
           write_reg2_out    : out  std_logic_vector(3 downto 0));
end component;

component mux_5to1_Nb is
    generic (N: integer := 16);
    port ( mux_select : in  std_logic_vector(2 downto 0);
           data_a     : in  std_logic_vector(N-1 downto 0);
           data_b     : in  std_logic_vector(N-1 downto 0);
           data_c     : in  std_logic_vector(N-1 downto 0);
           data_d     : in  std_logic_vector(N-1 downto 0);
           data_e     : in  std_logic_vector(N-1 downto 0);
           data_out   : out std_logic_vector(N-1 downto 0) );
end component;

component forwarding_unit is
    port ( ex_rs        : in std_logic_vector(3 downto 0);
           ex_rt        : in std_logic_vector(3 downto 0);
           mem_regwrite : in std_logic;
           mem_regwrite2 : in std_logic;
           mem_rd       : in std_logic_vector(3 downto 0);
           mem_rd2       : in std_logic_vector(3 downto 0);
           wb_regwrite : in std_logic;
           wb_regwrite2 : in std_logic;
           wb_rd       : in std_logic_vector(3 downto 0);
           wb_rd2       : in std_logic_vector(3 downto 0);
           alu_srcA    : out std_logic_vector(2 downto 0);
           alu_srcB    : out std_logic_vector(2 downto 0));
end component;

component hazard_detection_unit is
    port (  opcode           : in  std_logic_vector(3 downto 0);
            pc_stall         : out std_logic;
            reg1_sync_reset  : out std_logic);
end component;

component ackn_handler is
    generic (N: integer := 16);
    port (
        data_in     : in std_logic_vector(N-1 downto 0);
        ackn_in     : in std_logic;
        data_out    : out std_logic_vector(N-1 downto 0) );
end component;

-- All your existing signals (keeping them identical)
signal sig_one_4b                       : std_logic_vector(3 downto 0);
signal if_sig_next_pc                   : std_logic_vector(3 downto 0);
signal if_sig_curr_pc                   : std_logic_vector(3 downto 0);
signal if_sig_incremented_pc            : std_logic_vector(3 downto 0);
signal if_sig_incremented_pc_carry_out  : std_logic;
signal if_sig_insn                      : std_logic_vector(15 downto 0);

signal id_pc_stall                      : std_logic; 
signal id_sig_next_pc                   : std_logic_vector(3 downto 0);
signal id_sig_insn                      : std_logic_vector(15 downto 0); 
signal id_sig_bufget                    : std_logic;
signal id_sig_memput                    : std_logic;
signal id_sig_regwrite                  : std_logic;                 
signal id_sig_buftoreg                  : std_logic;
signal id_sig_dataA                     : std_logic_vector(N-1 downto 0); 
signal id_sig_dataB                     : std_logic_vector(N-1 downto 0); 
signal id_sig_regwrite2                 : std_logic;
signal id_reg1_sync_reset               : std_logic;

signal ex_sig_opcode                    : std_logic_vector(3 downto 0);
signal ex_sig_bufget                    : std_logic;
signal ex_sig_memput                    : std_logic;
signal ex_sig_regwrite                  : std_logic;
signal ex_sig_regwrite2                 : std_logic;
signal ex_sig_buftoreg                  : std_logic;
signal ex_sig_next_pc                   : std_logic_vector(3 downto 0);
signal ex_sig_dataA                     : std_logic_vector(N-1 downto 0);
signal ex_sig_dataB                     : std_logic_vector(N-1 downto 0);
signal ex_sig_rs                        : std_logic_vector(3 downto 0);
signal ex_sig_rt                        : std_logic_vector(3 downto 0);
signal ex_sig_rd                        : std_logic_vector(3 downto 0);
signal ex_sig_branch_pc_carry_out       : std_logic;
signal ex_sig_write_reg                 : std_logic_vector(3 downto 0);
signal ex_sig_alusrc_B                  : std_logic_vector(N-1 downto 0);
signal ex_sig_mux_alu_srcA              : std_logic_vector(2 downto 0);
signal ex_sig_alusrc_A                  : std_logic_vector(N-1 downto 0);
signal ex_sig_mux_alu_srcB              : std_logic_vector(2 downto 0);
signal ex_sig_result                    : std_logic_vector(N-1 downto 0);
signal ex_sig_write_data2               : std_logic_vector(N-1 downto 0);
signal ex_sig_alu_carry_out             : std_logic;
signal ex_sig_branch                    : std_logic;
signal ex_sig_branch_pc                 : std_logic_vector(3 downto 0);
signal ex_sig_ackn                      : std_logic;

signal mem_sig_memput                  : std_logic;
signal mem_sig_regwrite                 : std_logic;
signal mem_sig_regwrite2                : std_logic;
signal mem_sig_buftoreg                 : std_logic;
signal mem_sig_result                   : std_logic_vector(N-1 downto 0);
signal mem_sig_write_data               : std_logic_vector(N-1 downto 0);
signal mem_sig_write_data2              : std_logic_vector(N-1 downto 0);
signal mem_sig_write_reg                : std_logic_vector(3 downto 0);
signal mem_sig_write_reg2               : std_logic_vector(3 downto 0);
signal mem_sig_dataB                    : std_logic_vector(N-1 downto 0);
signal mem_wb_stall                     : std_logic;
signal mem_sig_write_data2_sel          : std_logic_vector(N-1 downto 0);

signal wb_sig_regwrite                  : std_logic;
signal wb_sig_regwrite2                 : std_logic;
signal wb_sig_buftoreg                  : std_logic;
signal wb_sig_dataA                     : std_logic_vector(N-1 downto 0);
signal wb_sig_dataB                     : std_logic_vector(N-1 downto 0);
signal wb_sig_write_reg                 : std_logic_vector(3 downto 0);
signal wb_sig_write_reg2                : std_logic_vector(3 downto 0);
signal wb_sig_write_data                : std_logic_vector(N-1 downto 0);
signal wb_sig_write_data2               : std_logic_vector(N-1 downto 0);

signal ex_insn               : std_logic_vector(15 downto 0);
signal mem_insn              : std_logic_vector(15 downto 0);
signal wb_insn               : std_logic_vector(15 downto 0);

-- New election signals
signal id_sig_tally_read                : std_logic;
signal id_sig_tally_write               : std_logic;
signal ex_sig_district_id               : std_logic_vector(1 downto 0);
signal ex_sig_candidate_id              : std_logic_vector(1 downto 0);
signal ex_sig_tally_increment           : std_logic_vector(7 downto 0);
signal ex_sig_tag_valid                 : std_logic;

begin

    sig_one_4b <= "0001";

    -- IF Stage (unchanged)
    pc : program_counter
    port map ( reset    => reset,
               stall    => id_pc_stall,
               clk      => clk,
               addr_in  => if_sig_next_pc,
               addr_out => if_sig_curr_pc ); 

    increment_pc : adder_4b 
    port map ( src_a     => if_sig_curr_pc, 
               src_b     => sig_one_4b,
               sum       => if_sig_incremented_pc,
               carry_out => if_sig_incremented_pc_carry_out );

    next_pc : mux_2to1_4b 
    port map ( mux_select => ex_sig_branch,
               data_a     => if_sig_incremented_pc,
               data_b     => ex_sig_branch_pc,
               data_out   => if_sig_next_pc );
    
    insn_mem : instruction_memory_election 
    generic map (CORE_NO => CORE_NO) 
    port map ( reset    => reset,
               clk      => clk,
               addr_in  => if_sig_curr_pc,
               insn_out => if_sig_insn );

    reg1_if_id : pipeline_reg1_if_id
    port map ( 
               sync_reset  => id_reg1_sync_reset,
               clk         => clk,
               next_pc_in  => if_sig_incremented_pc,
               insn_in     => if_sig_insn,
               next_pc_out => id_sig_next_pc,
               insn_out    => id_sig_insn);

    -- ID Stage (enhanced control unit)
    ctrl_unit : control_unit_enhanced 
    port map ( opcode     => id_sig_insn(15 downto 12),
                buf_get  => id_sig_bufget,
                mem_put  => id_sig_memput,
               reg_write  => id_sig_regwrite,
               reg_write2  => id_sig_regwrite2,
               buf_to_reg => id_sig_buftoreg,
               tally_read => id_sig_tally_read,
               tally_write => id_sig_tally_write);

    hazard_detection : hazard_detection_unit
    port map (
        opcode => id_sig_insn(15 downto 12),
        pc_stall => id_pc_stall,
        reg1_sync_reset => id_reg1_sync_reset);

    reg_file : register_file 
    generic map (N => N) 
    port map ( reset           => reset, 
               clk             => clk,
               read_register_a => id_sig_insn(11 downto 8),
               read_register_b => id_sig_insn(7 downto 4),
               read_data_a     => id_sig_dataA,
               read_data_b     => id_sig_dataB,
               write_enable    => wb_sig_regwrite,
               write_enable2   => wb_sig_regwrite2,
               write_register  => wb_sig_write_reg,
               write_register2 => wb_sig_write_reg2,
               write_data      => wb_sig_write_data,
               write_data2     => wb_sig_write_data2);

    reg2_id_ex : pipeline_reg2_id_ex
    generic map (N => N)
    port map (  stall         => '0',
                clk           => clk,
                opcode_in     => id_sig_insn(15 downto 12),
                regwrite_in   => id_sig_regwrite,
                regwrite2_in  => id_sig_regwrite2,
                buftoreg_in   => id_sig_buftoreg,
                bufget_in     => id_sig_bufget,
                memput_in     => id_sig_memput,
                next_pc_in    => id_sig_next_pc,
                dataA_in      => id_sig_dataA,
                dataB_in      => id_sig_dataB,
                rs_in         => id_sig_insn(11 downto 8),
                rt_in         => id_sig_insn(7 downto 4),
                rd_in         => id_sig_insn(3 downto 0),
                insn_in       => id_sig_insn,
                insn_out      => ex_insn,
                opcode_out    => ex_sig_opcode,
                bufget_out   => ex_sig_bufget,
                memput_out   => ex_sig_memput,
                regwrite_out  => ex_sig_regwrite,
                regwrite2_out => ex_sig_regwrite2,
                buftoreg_out  => ex_sig_buftoreg,
                next_pc_out   => ex_sig_next_pc,
                dataA_out     => ex_sig_dataA,
                dataB_out     => ex_sig_dataB,
                rs_out        => ex_sig_rs,
                rt_out        => ex_sig_rt,
                rd_out        => ex_sig_rd );

    -- EX Stage (enhanced ALU)
    branch_pc : adder_4b
    port map ( src_a     => (others => '0'), 
               src_b     => ex_sig_rd,
               sum       => ex_sig_branch_pc,
               carry_out => ex_sig_branch_pc_carry_out);
    
    mux_alu_srcA : mux_5to1_Nb 
    generic map (N => N)
    port map (  mux_select => ex_sig_mux_alu_srcA,
                data_a     => ex_sig_dataA,
                data_b     => mem_sig_write_data,
                data_c     => mem_sig_write_data2_sel,
                data_d     => wb_sig_write_data,
                data_e     => wb_sig_write_data2,
                data_out   => ex_sig_alusrc_A );

    mux_alu_srcB : mux_5to1_Nb 
    generic map (N => N)
    port map (  mux_select => ex_sig_mux_alu_srcB,
                data_a     => ex_sig_dataB,
                data_b     => mem_sig_write_data,
                data_c     => mem_sig_write_data2_sel,
                data_d     => wb_sig_write_data,
                data_e     => wb_sig_write_data2,
                data_out   => ex_sig_alusrc_B );
    
    fu : forwarding_unit
    port map (
        alu_srcA    => ex_sig_mux_alu_srcA,
        alu_srcB    => ex_sig_mux_alu_srcB,
        ex_rs        => ex_sig_rs,
        ex_rt        => ex_sig_rt,
        mem_regwrite => mem_sig_regwrite,
        mem_regwrite2 => mem_sig_regwrite2,
        mem_rd       => mem_sig_write_reg,
        mem_rd2       => mem_sig_write_reg2,
        wb_regwrite => wb_sig_regwrite,
        wb_regwrite2 => wb_sig_regwrite2,
        wb_rd       => wb_sig_write_reg, 
        wb_rd2      => wb_sig_write_reg2 );

    handler: ackn_handler
    generic map (N => N)
    port map (
        data_in    => ex_sig_alusrc_A,
        ackn_in    => ex_sig_ackn,
        data_out   => ackn_data );

    alu_enhanced : alu_election
    generic map ( N => N, T => 4, b_size => 31, secret_key_width => 32 )
    port map ( opcode        => ex_sig_opcode,
               src_a         => ex_sig_alusrc_A,
               src_b         => ex_sig_alusrc_B,
               output        => ex_sig_result,
               output2       => ex_sig_write_data2,
               branch        => ex_sig_branch, 
               ackn          => ex_sig_ackn,
               district_id   => ex_sig_district_id,
               candidate_id  => ex_sig_candidate_id,
               tally_increment => ex_sig_tally_increment,
               tag_valid     => ex_sig_tag_valid );

    reg3_ex_mem : pipeline_reg3_ex_mem
    generic map (N => N)
    port map (
        stall            => '0',
        clk              => clk,
        memput_in      => ex_sig_memput,
        bufget_in      => ex_sig_bufget,
        regwrite_in      => ex_sig_regwrite,
        regwrite2_in     => ex_sig_regwrite2,
        buftoreg_in      => ex_sig_buftoreg,
        result_in        => ex_sig_result,
        write_data2_in   => ex_sig_write_data2,
        write_reg_in     => ex_sig_rt,
        write_reg2_in    => ex_sig_rs,
        insn_in       => ex_insn,
        insn_out      => mem_insn,
        bufget_out     => bufget,
        memput_out     => mem_sig_memput,
        regwrite_out     => mem_sig_regwrite,
        regwrite2_out    => mem_sig_regwrite2,
        buftoreg_out     => mem_sig_buftoreg,
        result_out       => mem_sig_result,
        write_data2_out   => mem_sig_write_data2,
        write_reg_out    => mem_sig_write_reg,
        write_reg2_out   => mem_sig_write_reg2 );

    -- MEM Stage (unchanged data memory + new tally table)
    output_mem : mem
    generic map (N => N, CORE_NO => CORE_NO)
    port map (
        clk => clk,
        reset => reset,
        memput => mem_sig_memput,
        data1_in => mem_sig_result,
        data2_in => mem_sig_write_data2 );

    -- New tally table for election tallying
    tally_mem : tally_table
    generic map (N_DISTRICTS => 4, N_CANDIDATES => 4, TALLY_WIDTH => 8)
    port map (
        clk => clk,
        reset => reset,
        write_enable => ex_sig_tag_valid,  -- Only update if tag is valid
        district_id => ex_sig_district_id,
        candidate_id => ex_sig_candidate_id,
        increment => ex_sig_tally_increment,
        total_candidate_0 => total_candidate_0,
        total_candidate_1 => total_candidate_1,
        total_candidate_2 => total_candidate_2,
        total_candidate_3 => total_candidate_3 );

    mux_mem_to_reg : mux_2to1_Nb 
    generic map (N => N)
    port map ( mux_select => mem_sig_buftoreg,
                data_a     => mem_sig_result,
                data_b     => buf_value1,
                data_out   => mem_sig_write_data );

    write_data_sel : mux_2to1_Nb 
    generic map (N => N)
    port map ( mux_select => mem_sig_buftoreg,
               data_a     => mem_sig_write_data2,
               data_b     => buf_value2,
               data_out   => mem_sig_write_data2_sel );

    -- WB Stage (unchanged)
    reg4_mem_wb : pipeline_reg4_mem_wb
    generic map (N => N)
    port map (
        stall           => '0',
        clk             => clk,
        regwrite_in     => mem_sig_regwrite,
        regwrite2_in    => mem_sig_regwrite2,
        write_data_in   => mem_sig_write_data,
        write_data2_in  => mem_sig_write_data2_sel,
        write_reg_in    => mem_sig_write_reg,
        write_reg2_in   => mem_sig_write_reg2,
        insn_in       => mem_insn,
        insn_out      => wb_insn,
        regwrite_out    => wb_sig_regwrite,
        regwrite2_out   => wb_sig_regwrite2,
        write_data_out  => wb_sig_write_data,
        write_data2_out => wb_sig_write_data2,
        write_reg_out   => wb_sig_write_reg,
        write_reg2_out  => wb_sig_write_reg2 );

end structural;