library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity election_center is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        input_data  : in  STD_LOGIC_VECTOR(15 downto 0);
        output_data : out STD_LOGIC_VECTOR(15 downto 0)
    );
end election_center;

architecture Behavioral of election_center is

    -- Component Declarations
    component if_stage is
        Port (
            clk             : in  STD_LOGIC;
            reset           : in  STD_LOGIC;
            pc_enable       : in  STD_LOGIC;
            branch_target   : in  STD_LOGIC_VECTOR(15 downto 0);
            branch_taken    : in  STD_LOGIC;
            instruction     : out STD_LOGIC_VECTOR(15 downto 0);
            pc_plus_one     : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    component id_stage is
        Port (
            clk             : in  STD_LOGIC;
            reset           : in  STD_LOGIC;
            instruction     : in  STD_LOGIC_VECTOR(15 downto 0);
            input_data      : in  STD_LOGIC_VECTOR(15 downto 0);
            writeback_reg   : in  STD_LOGIC_VECTOR(2 downto 0);
            writeback_data  : in  STD_LOGIC_VECTOR(15 downto 0);
            writeback_en    : in  STD_LOGIC;
            
            -- Control signals
            opcode          : out STD_LOGIC_VECTOR(3 downto 0);
            rs_addr         : out STD_LOGIC_VECTOR(2 downto 0);
            rt_addr         : out STD_LOGIC_VECTOR(2 downto 0);
            rd_addr         : out STD_LOGIC_VECTOR(2 downto 0);
            immediate       : out STD_LOGIC_VECTOR(8 downto 0);
            rs_data         : out STD_LOGIC_VECTOR(15 downto 0);
            rt_data         : out STD_LOGIC_VECTOR(15 downto 0);
            
            -- Control signals for pipeline
            reg_write       : out STD_LOGIC;
            mem_read        : out STD_LOGIC;
            mem_write       : out STD_LOGIC;
            alu_src         : out STD_LOGIC;
            branch          : out STD_LOGIC;
            
            -- Hazard detection
            stall_pipeline  : out STD_LOGIC
        );
    end component;

    component ex_stage is
        Port (
            clk             : in  STD_LOGIC;
            reset           : in  STD_LOGIC;
            opcode          : in  STD_LOGIC_VECTOR(3 downto 0);
            rs_data         : in  STD_LOGIC_VECTOR(15 downto 0);
            rt_data         : in  STD_LOGIC_VECTOR(15 downto 0);
            immediate       : in  STD_LOGIC_VECTOR(8 downto 0);
            alu_src         : in  STD_LOGIC;
            
            -- Forwarding inputs
            forward_a       : in  STD_LOGIC_VECTOR(1 downto 0);
            forward_b       : in  STD_LOGIC_VECTOR(1 downto 0);
            mem_forward     : in  STD_LOGIC_VECTOR(15 downto 0);
            wb_forward      : in  STD_LOGIC_VECTOR(15 downto 0);
            
            -- Outputs
            alu_result      : out STD_LOGIC_VECTOR(15 downto 0);
            tag_result      : out STD_LOGIC_VECTOR(3 downto 0);
            validation      : out STD_LOGIC;
            tag_gen_busy    : out STD_LOGIC;
            rt_data_out     : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    component mem_stage is
        Port (
            clk             : in  STD_LOGIC;
            reset           : in  STD_LOGIC;
            mem_read        : in  STD_LOGIC;
            mem_write       : in  STD_LOGIC;
            address         : in  STD_LOGIC_VECTOR(15 downto 0);
            write_data      : in  STD_LOGIC_VECTOR(15 downto 0);
            validation      : in  STD_LOGIC;
            
            -- Outputs
            read_data       : out STD_LOGIC_VECTOR(15 downto 0);
            candidate_total : out STD_LOGIC_VECTOR(10 downto 0)
        );
    end component;

    component wb_stage is
        Port (
            mem_to_reg      : in  STD_LOGIC;
            alu_result      : in  STD_LOGIC_VECTOR(15 downto 0);
            mem_data        : in  STD_LOGIC_VECTOR(15 downto 0);
            writeback_data  : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    component forwarding_unit is
        Port (
            -- Current instruction register addresses
            id_ex_rs        : in  STD_LOGIC_VECTOR(2 downto 0);
            id_ex_rt        : in  STD_LOGIC_VECTOR(2 downto 0);
            
            -- Previous instruction information
            ex_mem_rd       : in  STD_LOGIC_VECTOR(2 downto 0);
            ex_mem_reg_write: in  STD_LOGIC;
            mem_wb_rd       : in  STD_LOGIC_VECTOR(2 downto 0);
            mem_wb_reg_write: in  STD_LOGIC;
            
            -- Forwarding control signals
            forward_a       : out STD_LOGIC_VECTOR(1 downto 0);
            forward_b       : out STD_LOGIC_VECTOR(1 downto 0)
        );
    end component;

    -- Pipeline Register Components
    component if_id_reg is
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            stall       : in  STD_LOGIC;
            flush       : in  STD_LOGIC;
            if_instruction : in  STD_LOGIC_VECTOR(15 downto 0);
            if_pc_plus_one : in  STD_LOGIC_VECTOR(15 downto 0);
            id_instruction : out STD_LOGIC_VECTOR(15 downto 0);
            id_pc_plus_one : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    component id_ex_reg is
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            stall       : in  STD_LOGIC;
            
            -- ID stage inputs
            id_opcode       : in  STD_LOGIC_VECTOR(3 downto 0);
            id_rs_addr      : in  STD_LOGIC_VECTOR(2 downto 0);
            id_rt_addr      : in  STD_LOGIC_VECTOR(2 downto 0);
            id_rd_addr      : in  STD_LOGIC_VECTOR(2 downto 0);
            id_rs_data      : in  STD_LOGIC_VECTOR(15 downto 0);
            id_rt_data      : in  STD_LOGIC_VECTOR(15 downto 0);
            id_immediate    : in  STD_LOGIC_VECTOR(8 downto 0);
            id_reg_write    : in  STD_LOGIC;
            id_mem_read     : in  STD_LOGIC;
            id_mem_write    : in  STD_LOGIC;
            id_alu_src      : in  STD_LOGIC;
            
            -- EX stage outputs
            ex_opcode       : out STD_LOGIC_VECTOR(3 downto 0);
            ex_rs_addr      : out STD_LOGIC_VECTOR(2 downto 0);
            ex_rt_addr      : out STD_LOGIC_VECTOR(2 downto 0);
            ex_rd_addr      : out STD_LOGIC_VECTOR(2 downto 0);
            ex_rs_data      : out STD_LOGIC_VECTOR(15 downto 0);
            ex_rt_data      : out STD_LOGIC_VECTOR(15 downto 0);
            ex_immediate    : out STD_LOGIC_VECTOR(8 downto 0);
            ex_reg_write    : out STD_LOGIC;
            ex_mem_read     : out STD_LOGIC;
            ex_mem_write    : out STD_LOGIC;
            ex_alu_src      : out STD_LOGIC
        );
    end component;

    component ex_mem_reg is
        Port (
            clk             : in  STD_LOGIC;
            reset           : in  STD_LOGIC;
            
            -- EX stage inputs
            ex_alu_result   : in  STD_LOGIC_VECTOR(15 downto 0);
            ex_rt_data      : in  STD_LOGIC_VECTOR(15 downto 0);
            ex_rd_addr      : in  STD_LOGIC_VECTOR(2 downto 0);
            ex_validation   : in  STD_LOGIC;
            ex_reg_write    : in  STD_LOGIC;
            ex_mem_read     : in  STD_LOGIC;
            ex_mem_write    : in  STD_LOGIC;
            
            -- MEM stage outputs
            mem_alu_result  : out STD_LOGIC_VECTOR(15 downto 0);
            mem_rt_data     : out STD_LOGIC_VECTOR(15 downto 0);
            mem_rd_addr     : out STD_LOGIC_VECTOR(2 downto 0);
            mem_validation  : out STD_LOGIC;
            mem_reg_write   : out STD_LOGIC;
            mem_mem_read    : out STD_LOGIC;
            mem_mem_write   : out STD_LOGIC
        );
    end component;

    component mem_wb_reg is
        Port (
            clk             : in  STD_LOGIC;
            reset           : in  STD_LOGIC;
            
            -- MEM stage inputs
            mem_alu_result  : in  STD_LOGIC_VECTOR(15 downto 0);
            mem_read_data   : in  STD_LOGIC_VECTOR(15 downto 0);
            mem_rd_addr     : in  STD_LOGIC_VECTOR(2 downto 0);
            mem_reg_write   : in  STD_LOGIC;
            
            -- WB stage outputs
            wb_alu_result   : out STD_LOGIC_VECTOR(15 downto 0);
            wb_read_data    : out STD_LOGIC_VECTOR(15 downto 0);
            wb_rd_addr      : out STD_LOGIC_VECTOR(2 downto 0);
            wb_reg_write    : out STD_LOGIC
        );
    end component;

    -- Internal Signals
    
    -- IF Stage
    signal if_instruction, if_pc_plus_one : STD_LOGIC_VECTOR(15 downto 0);
    signal pc_enable, branch_taken : STD_LOGIC;
    signal branch_target : STD_LOGIC_VECTOR(15 downto 0);
    
    -- IF/ID Pipeline Register
    signal id_instruction, id_pc_plus_one : STD_LOGIC_VECTOR(15 downto 0);
    
    -- ID Stage
    signal id_opcode : STD_LOGIC_VECTOR(3 downto 0);
    signal id_rs_addr, id_rt_addr, id_rd_addr : STD_LOGIC_VECTOR(2 downto 0);
    signal id_immediate : STD_LOGIC_VECTOR(8 downto 0);
    signal id_rs_data, id_rt_data : STD_LOGIC_VECTOR(15 downto 0);
    signal id_reg_write, id_mem_read, id_mem_write, id_alu_src : STD_LOGIC;
    signal stall_pipeline : STD_LOGIC;
    
    -- ID/EX Pipeline Register
    signal ex_opcode : STD_LOGIC_VECTOR(3 downto 0);
    signal ex_rs_addr, ex_rt_addr, ex_rd_addr : STD_LOGIC_VECTOR(2 downto 0);
    signal ex_rs_data, ex_rt_data : STD_LOGIC_VECTOR(15 downto 0);
    signal ex_immediate : STD_LOGIC_VECTOR(8 downto 0);
    signal ex_reg_write, ex_mem_read, ex_mem_write, ex_alu_src : STD_LOGIC;
    
    -- EX Stage
    signal ex_alu_result : STD_LOGIC_VECTOR(15 downto 0);
    signal ex_tag_result : STD_LOGIC_VECTOR(3 downto 0);
    signal ex_validation, tag_gen_busy : STD_LOGIC;
    signal ex_rt_data_out : STD_LOGIC_VECTOR(15 downto 0);
    
    -- Forwarding
    signal forward_a, forward_b : STD_LOGIC_VECTOR(1 downto 0);
    
    -- EX/MEM Pipeline Register
    signal mem_alu_result, mem_rt_data : STD_LOGIC_VECTOR(15 downto 0);
    signal mem_rd_addr : STD_LOGIC_VECTOR(2 downto 0);
    signal mem_validation, mem_reg_write, mem_mem_read, mem_mem_write : STD_LOGIC;
    
    -- MEM Stage
    signal mem_read_data : STD_LOGIC_VECTOR(15 downto 0);
    signal candidate_total : STD_LOGIC_VECTOR(10 downto 0);  -- 11-bit candidate total
    
    -- MEM/WB Pipeline Register
    signal wb_alu_result, wb_read_data : STD_LOGIC_VECTOR(15 downto 0);
    signal wb_rd_addr : STD_LOGIC_VECTOR(2 downto 0);
    signal wb_reg_write : STD_LOGIC;
    
    -- WB Stage
    signal writeback_data : STD_LOGIC_VECTOR(15 downto 0);
    
    -- Output Formation
    signal output_validation : STD_LOGIC;
    signal output_candidate : STD_LOGIC_VECTOR(1 downto 0);
    signal output_district : STD_LOGIC_VECTOR(1 downto 0);

begin

    -- Pipeline Control
    pc_enable <= not stall_pipeline;
    
    -- Output Formation (echo back candidate/district from input, add validation and total)
    output_candidate <= input_data(3 downto 2);
    output_district <= input_data(1 downto 0);
    
    -- Form final output: [15] validation [14:4] candidate_total(11-bit) [3:2] candidate [1:0] district
    output_data <= output_validation & candidate_total & output_candidate & output_district;

    -- Instantiate Pipeline Stages
    
    IF_STAGE_INST: if_stage
        port map (
            clk => clk,
            reset => reset,
            pc_enable => pc_enable,
            branch_target => branch_target,
            branch_taken => branch_taken,
            instruction => if_instruction,
            pc_plus_one => if_pc_plus_one
        );

    IF_ID_REG_INST: if_id_reg
        port map (
            clk => clk,
            reset => reset,
            stall => stall_pipeline,
            flush => branch_taken,
            if_instruction => if_instruction,
            if_pc_plus_one => if_pc_plus_one,
            id_instruction => id_instruction,
            id_pc_plus_one => id_pc_plus_one
        );

    ID_STAGE_INST: id_stage
        port map (
            clk => clk,
            reset => reset,
            instruction => id_instruction,
            input_data => input_data,
            writeback_reg => wb_rd_addr,
            writeback_data => writeback_data,
            writeback_en => wb_reg_write,
            opcode => id_opcode,
            rs_addr => id_rs_addr,
            rt_addr => id_rt_addr,
            rd_addr => id_rd_addr,
            immediate => id_immediate,
            rs_data => id_rs_data,
            rt_data => id_rt_data,
            reg_write => id_reg_write,
            mem_read => id_mem_read,
            mem_write => id_mem_write,
            alu_src => id_alu_src,
            branch => open,
            stall_pipeline => stall_pipeline
        );

    ID_EX_REG_INST: id_ex_reg
        port map (
            clk => clk,
            reset => reset,
            stall => tag_gen_busy,
            id_opcode => id_opcode,
            id_rs_addr => id_rs_addr,
            id_rt_addr => id_rt_addr,
            id_rd_addr => id_rd_addr,
            id_rs_data => id_rs_data,
            id_rt_data => id_rt_data,
            id_immediate => id_immediate,
            id_reg_write => id_reg_write,
            id_mem_read => id_mem_read,
            id_mem_write => id_mem_write,
            id_alu_src => id_alu_src,
            ex_opcode => ex_opcode,
            ex_rs_addr => ex_rs_addr,
            ex_rt_addr => ex_rt_addr,
            ex_rd_addr => ex_rd_addr,
            ex_rs_data => ex_rs_data,
            ex_rt_data => ex_rt_data,
            ex_immediate => ex_immediate,
            ex_reg_write => ex_reg_write,
            ex_mem_read => ex_mem_read,
            ex_mem_write => ex_mem_write,
            ex_alu_src => ex_alu_src
        );

    EX_STAGE_INST: ex_stage
        port map (
            clk => clk,
            reset => reset,
            opcode => ex_opcode,
            rs_data => ex_rs_data,
            rt_data => ex_rt_data,
            immediate => ex_immediate,
            alu_src => ex_alu_src,
            forward_a => forward_a,
            forward_b => forward_b,
            mem_forward => mem_alu_result,
            wb_forward => writeback_data,
            alu_result => ex_alu_result,
            tag_result => ex_tag_result,
            validation => ex_validation,
            tag_gen_busy => tag_gen_busy,
            rt_data_out => ex_rt_data_out
        );

    FORWARDING_UNIT_INST: forwarding_unit
        port map (
            id_ex_rs => ex_rs_addr,
            id_ex_rt => ex_rt_addr,
            ex_mem_rd => mem_rd_addr,
            ex_mem_reg_write => mem_reg_write,
            mem_wb_rd => wb_rd_addr,
            mem_wb_reg_write => wb_reg_write,
            forward_a => forward_a,
            forward_b => forward_b
        );

    EX_MEM_REG_INST: ex_mem_reg
        port map (
            clk => clk,
            reset => reset,
            ex_alu_result => ex_alu_result,
            ex_rt_data => ex_rt_data_out,
            ex_rd_addr => ex_rd_addr,
            ex_validation => ex_validation,
            ex_reg_write => ex_reg_write,
            ex_mem_read => ex_mem_read,
            ex_mem_write => ex_mem_write,
            mem_alu_result => mem_alu_result,
            mem_rt_data => mem_rt_data,
            mem_rd_addr => mem_rd_addr,
            mem_validation => mem_validation,
            mem_reg_write => mem_reg_write,
            mem_mem_read => mem_mem_read,
            mem_mem_write => mem_mem_write
        );

    MEM_STAGE_INST: mem_stage
        port map (
            clk => clk,
            reset => reset,
            mem_read => mem_mem_read,
            mem_write => mem_mem_write,
            address => mem_alu_result,
            write_data => mem_rt_data,
            validation => mem_validation,
            read_data => mem_read_data,
            candidate_total => candidate_total
        );

    MEM_WB_REG_INST: mem_wb_reg
        port map (
            clk => clk,
            reset => reset,
            mem_alu_result => mem_alu_result,
            mem_read_data => mem_read_data,
            mem_rd_addr => mem_rd_addr,
            mem_reg_write => mem_reg_write,
            wb_alu_result => wb_alu_result,
            wb_read_data => wb_read_data,
            wb_rd_addr => wb_rd_addr,
            wb_reg_write => wb_reg_write
        );

    WB_STAGE_INST: wb_stage
        port map (
            mem_to_reg => '1', -- Simplified for now
            alu_result => wb_alu_result,
            mem_data => wb_read_data,
            writeback_data => writeback_data
        );

    -- Output validation comes from the validation result in MEM stage
    output_validation <= mem_validation;

end Behavioral;