--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;  

--entity pipelined_core is
--    port ( 
--        reset    : in  std_logic;
--        clk      : in  std_logic;
--        sw 	  : in  std_logic_vector(15 downto 0);
--        led      : out std_logic_vector(15 downto 0)
--    );
--end pipelined_core;

--architecture structural of pipelined_core is
--    -- Pipeline register types
--    type if_id_reg is record
--        pc_plus_1  : std_logic_vector(3 downto 0);
--        instruction: std_logic_vector(15 downto 0);
--    end record;
    
--    type id_ex_reg is record
--        pc_plus_1    : std_logic_vector(3 downto 0);
--        reg_dst      : std_logic;
--        reg_write    : std_logic;
--        alu_src      : std_logic;
--        mem_write    : std_logic;
--        mem_to_reg   : std_logic;
--        sw_to_reg    : std_logic;
--        read_data_1  : std_logic_vector(15 downto 0);
--        read_data_2  : std_logic_vector(15 downto 0);
--        sign_ext_imm : std_logic_vector(15 downto 0);
--        rs           : std_logic_vector(3 downto 0);
--        rt           : std_logic_vector(3 downto 0);
--        rd           : std_logic_vector(3 downto 0);
--        instruction  : std_logic_vector(15 downto 0);  -- Added instruction field
--    end record;
    
--    type ex_mem_reg is record
--        reg_write    : std_logic;
--        mem_write    : std_logic;
--        mem_to_reg   : std_logic;
--        sw_to_reg    : std_logic;
--        branch_taken : std_logic;
--        alu_result   : std_logic_vector(15 downto 0);
--        write_data   : std_logic_vector(15 downto 0);
--        write_reg    : std_logic_vector(3 downto 0);
--    end record;
    
--    type mem_wb_reg is record
--        reg_write     : std_logic;
--        mem_to_reg    : std_logic;
--        sw_to_reg     : std_logic;
--        alu_result    : std_logic_vector(15 downto 0);
--        mem_read_data : std_logic_vector(15 downto 0);
--        write_reg     : std_logic_vector(3 downto 0);
--    end record;
    
--    -- Pipeline registers
--    signal if_id : if_id_reg;
--    signal id_ex : id_ex_reg;
--    signal ex_mem : ex_mem_reg;
--    signal mem_wb : mem_wb_reg;
    
--    -- Control signals
--    signal pc_write     : std_logic;
--    signal if_id_write  : std_logic;
--    signal stall        : std_logic;
--    signal forward_a    : std_logic_vector(1 downto 0);
--    signal forward_b    : std_logic_vector(1 downto 0);
--    signal branch_taken : std_logic;
    
--    -- Internal signals
--    signal pc_current, pc_next, pc_plus_1 : std_logic_vector(3 downto 0);
--    signal pc_branch_target : std_logic_vector(3 downto 0);
--    signal instruction : std_logic_vector(15 downto 0);
--    signal reg_dst, reg_write, alu_src, mem_write, mem_to_reg, sw_to_reg : std_logic;
--    signal read_data_1, read_data_2 : std_logic_vector(15 downto 0);
--    signal sign_ext_imm : std_logic_vector(15 downto 0);
--    signal write_reg : std_logic_vector(3 downto 0);
--    signal alu_src_a, alu_src_b, alu_result : std_logic_vector(15 downto 0);
--    signal alu_carry_out : std_logic;
--    signal mem_read_data : std_logic_vector(15 downto 0);
--    signal write_data : std_logic_vector(15 downto 0);
--    signal reg_write_data : std_logic_vector(15 downto 0);
--    signal pc_src : std_logic;
    
--    -- Detects load-use hazards BEFORE the dependent instruction enters EX stage
    
--    signal load_in_id : std_logic;
--    signal load_dest_reg : std_logic_vector(3 downto 0);
    
--    -- Component declarations (same as before)
--    component program_counter is
--        port ( reset    : in  std_logic;
--               clk      : in  std_logic;
--               write_enable : in  std_logic; 
--               addr_in  : in  std_logic_vector(3 downto 0);
--               addr_out : out std_logic_vector(3 downto 0) );
--    end component;
    
--    component instruction_memory is
--        port ( reset    : in  std_logic;
--               clk      : in  std_logic;
--               addr_in  : in  std_logic_vector(3 downto 0);
--               insn_out : out std_logic_vector(15 downto 0) );
--    end component;
    
--    component register_file is
--        port ( reset           : in  std_logic;
--               clk             : in  std_logic;
--               read_register_a : in  std_logic_vector(3 downto 0);
--               read_register_b : in  std_logic_vector(3 downto 0);
--               write_enable    : in  std_logic;
--               write_register  : in  std_logic_vector(3 downto 0);
--               write_data      : in  std_logic_vector(15 downto 0);
--               read_data_a     : out std_logic_vector(15 downto 0);
--               read_data_b     : out std_logic_vector(15 downto 0) );
--    end component;
    
--    component control_unit is
--        port ( opcode     : in  std_logic_vector(3 downto 0);
--               reg_dst    : out std_logic;
--               reg_write  : out std_logic;
--               alu_src    : out std_logic;
--               mem_write  : out std_logic;
--               mem_to_reg : out std_logic;
--               sw_to_reg  : out std_logic );
--    end component;
    
--    component adder_4b is
--        port ( src_a     : in  std_logic_vector(3 downto 0);
--               src_b     : in  std_logic_vector(3 downto 0);
--               sum       : out std_logic_vector(3 downto 0);
--               carry_out : out std_logic );
--    end component;
    
--    component adder_16b is
--        port ( src_a     : in  std_logic_vector(15 downto 0);
--               src_b     : in  std_logic_vector(15 downto 0);
--               sum       : out std_logic_vector(15 downto 0);
--               carry_out : out std_logic );
--    end component;
    
--    component data_memory is
--        port ( reset        : in  std_logic;
--               clk          : in  std_logic;
--               write_enable : in  std_logic;
--               write_data   : in  std_logic_vector(15 downto 0);
--               addr_in      : in  std_logic_vector(3 downto 0);
--               data_out     : out std_logic_vector(15 downto 0) );
--    end component;
    
--    component sign_extend_4to16 is
--        port ( data_in  : in  std_logic_vector(3 downto 0);
--               data_out : out std_logic_vector(15 downto 0) );
--    end component;
    
--    component mux_2to1_4b is
--        port ( mux_select : in  std_logic;
--               data_a     : in  std_logic_vector(3 downto 0);
--               data_b     : in  std_logic_vector(3 downto 0);
--               data_out   : out std_logic_vector(3 downto 0) );
--    end component;
    
--    component mux_2to1_16b is
--        port ( mux_select : in  std_logic;
--               data_a     : in  std_logic_vector(15 downto 0);
--               data_b     : in  std_logic_vector(15 downto 0);
--               data_out   : out std_logic_vector(15 downto 0) );
--    end component;
    
--    component mux_3to1_16b is
--        port ( sel        : in  std_logic_vector(1 downto 0);
--               data_a     : in  std_logic_vector(15 downto 0);
--               data_b     : in  std_logic_vector(15 downto 0);
--               data_c     : in  std_logic_vector(15 downto 0);
--               data_out   : out std_logic_vector(15 downto 0) );
--    end component;


--begin


--    -- Stage 1: Instruction Fetch (IF)
--    -- =====================================================================
--    pc_mux: mux_2to1_4b port map(
--        mux_select => pc_src,
--        data_a => pc_plus_1,
--        data_b => pc_branch_target,
--        data_out => pc_next
--    );
    
--    pc_reg: program_counter port map(
--        reset => reset,
--        clk => clk,
--        write_enable =>  not stall, 
--        addr_in => pc_next,
--        addr_out => pc_current
--    );
    
--    pc_adder: adder_4b port map(
--        src_a => pc_current,
--        src_b => "0001",
--        sum => pc_plus_1,
--        carry_out => open
--    );
    
--    inst_mem: instruction_memory port map(
--        reset => reset,
--        clk => clk,
--        addr_in => pc_current,
--        insn_out => instruction
--    );
    
--    -- IF/ID Pipeline Register
----    process(clk, reset)
----    begin
----        if reset = '1' then
----            if_id.pc_plus_1 <= (others => '0');
----            if_id.instruction <= (others => '0');
----        elsif rising_edge(clk) and stall = '0' then
----            if_id.pc_plus_1 <= pc_plus_1;
----            if_id.instruction <= instruction;
----        end if;
----    end process;
--    -- IF/ID Pipeline Register (add pc_write control)
--process(clk, reset)
--begin
--    if reset = '1' then
--        if_id.pc_plus_1 <= (others => '0');
--        if_id.instruction <= (others => '0');
--    elsif rising_edge(clk) then
--        if stall = '0' then  -- Only update when not stalling
--            if_id.pc_plus_1 <= pc_plus_1;
--            if_id.instruction <= instruction;
--        end if;
--        -- When stalling, IF/ID register keeps same values
--    end if;
--end process;
    
--    -- =====================================================================
--    -- Stage 2: Instruction Decode (ID)
--    -- =====================================================================
--    control: control_unit port map(
--        opcode => if_id.instruction(15 downto 12),
--        reg_dst => reg_dst,
--        reg_write => reg_write,
--        alu_src => alu_src,
--        mem_write => mem_write,
--        mem_to_reg => mem_to_reg,
--        sw_to_reg => sw_to_reg
--    );
    
--    reg_file: register_file port map(
--        reset => reset,
--        clk => clk,
--        read_register_a => if_id.instruction(11 downto 8),
--        read_register_b => if_id.instruction(7 downto 4),
--        write_enable => mem_wb.reg_write,
--        write_register => mem_wb.write_reg,
--        write_data => reg_write_data,
--        read_data_a => read_data_1,
--        read_data_b => read_data_2
--    );
    
--    sign_ext: sign_extend_4to16 port map(
--        data_in => if_id.instruction(3 downto 0),
--        data_out => sign_ext_imm
--    );
    
--    -- Hazard detection unit
----    hazard_detection: process(id_ex.reg_write, id_ex.rt, if_id.instruction(11 downto 8), if_id.instruction(7 downto 4))
------    begin
------        stall <= '0';
------        if (id_ex.reg_write = '1') and 
------           ((id_ex.rt = if_id.instruction(11 downto 8)) or 
------            (id_ex.rt = if_id.instruction(7 downto 4))) then
------            stall <= '1';
------        end if;
------    end process;
    
--    -- Hazard Detection (corrected timing)
--    hazard_detection: process(id_ex.mem_to_reg, id_ex.rt, if_id.instruction)
--    begin
--        stall <= '0';
        
--        -- Check for load-use hazard: LOAD in EX stage, dependent instruction in ID stage
--        if (id_ex.mem_to_reg = '1') then  -- EX stage has LOAD instruction
--            -- Check if ID stage instruction reads from register being loaded
--            if (id_ex.rt = if_id.instruction(11 downto 8)) or    -- Rs dependency
--               (id_ex.rt = if_id.instruction(7 downto 4)) then   -- Rt dependency
--                stall <= '1';
--            end if;
--        end if;
--    end process;

--    pc_src <= ex_mem.branch_taken;
--    pc_write <= not stall;
--    if_id_write <= not stall;
    
--   
--  -- ID/EX Pipeline Register with proper stall handling
--  process(clk, reset)
--begin
--    if reset = '1' then
--        id_ex.pc_plus_1 <= (others => '0');
--        id_ex.reg_dst <= '0';
--        id_ex.reg_write <= '0';
--        id_ex.alu_src <= '0';
--        id_ex.mem_write <= '0';
--        id_ex.mem_to_reg <= '0';
--        id_ex.sw_to_reg <= '0';
--        id_ex.read_data_1 <= (others => '0');
--        id_ex.read_data_2 <= (others => '0');
--        id_ex.sign_ext_imm <= (others => '0');
--        id_ex.rs <= (others => '0');
--        id_ex.rt <= (others => '0');
--        id_ex.rd <= (others => '0');
--        id_ex.instruction <= (others => '0');
--    elsif rising_edge(clk) then
--        if stall = '1' then
--            -- Insert NOP (bubble) when stalling
--            id_ex.reg_write <= '0';      -- Don't write to any register
--            id_ex.mem_write <= '0';      -- Don't write to memory
--            id_ex.mem_to_reg <= '0';     -- Clear LOAD signal
--            id_ex.sw_to_reg <= '0';      -- Don't update LEDs
--            id_ex.instruction <= X"0000"; -- NOP for debugging
--            -- Keep other fields (data remains for forwarding)
--        else
--            -- Normal operation - pass all signals through
--            id_ex.pc_plus_1 <= if_id.pc_plus_1;
--            id_ex.reg_dst <= reg_dst;
--            id_ex.reg_write <= reg_write;
--            id_ex.alu_src <= alu_src;
--            id_ex.mem_write <= mem_write;
--            id_ex.mem_to_reg <= mem_to_reg;
--            id_ex.sw_to_reg <= sw_to_reg;
--            id_ex.read_data_1 <= read_data_1;
--            id_ex.read_data_2 <= read_data_2;
--            id_ex.sign_ext_imm <= sign_ext_imm;
--            id_ex.rs <= if_id.instruction(11 downto 8);
--            id_ex.rt <= if_id.instruction(7 downto 4);
--            id_ex.rd <= if_id.instruction(3 downto 0);
--            id_ex.instruction <= if_id.instruction;
--        end if;
--    end if;
--end process;
    
--    -- =====================================================================
--    -- Stage 3: Execute (EX)
--    -- =====================================================================
--    -- Register write mux
--    reg_dst_mux: mux_2to1_4b port map(
--        mux_select => id_ex.reg_dst,
--        data_a => id_ex.rt,
--        data_b => id_ex.rd,
--        data_out => write_reg
--    );
    
--    -- Forwarding Unit
--    forwarding_unit: process(ex_mem.reg_write, ex_mem.write_reg, mem_wb.reg_write, mem_wb.write_reg, id_ex.rs, id_ex.rt)
--    begin
--        -- Forward A
--        if (ex_mem.reg_write = '1') and (ex_mem.write_reg = id_ex.rs) then
--            forward_a <= "10";
--        elsif (mem_wb.reg_write = '1') and (mem_wb.write_reg = id_ex.rs) then
--            forward_a <= "01";
--        else
--            forward_a <= "00";
--        end if;
        
--        -- Forward B
--        if (ex_mem.reg_write = '1') and (ex_mem.write_reg = id_ex.rt) then
--            forward_b <= "10";
--        elsif (mem_wb.reg_write = '1') and (mem_wb.write_reg = id_ex.rt) then
--            forward_b <= "01";
--        else
--            forward_b <= "00";
--        end if;
--    end process;
    
--    -- ALU input A forwarding mux
--    alu_src_a_mux: mux_3to1_16b port map(
--        sel => forward_a,
--        data_a => id_ex.read_data_1,
--        data_b => reg_write_data,
--        data_c => ex_mem.alu_result,
--        data_out => alu_src_a
--    );
    
--    -- ALU input B mux
--    alu_src_b_mux1: mux_3to1_16b port map(
--        sel => forward_b,
--        data_a => id_ex.read_data_2,
--        data_b => reg_write_data,
--        data_c => ex_mem.alu_result,
--        data_out => write_data
--    );
    
--    alu_src_b_mux2: mux_2to1_16b port map(
--        mux_select => id_ex.alu_src,
--        data_a => write_data,
--        data_b => id_ex.sign_ext_imm,
--        data_out => alu_src_b
--    );
    
--    -- ALU
--    alu: adder_16b port map(
--        src_a => alu_src_a,
--        src_b => alu_src_b,
--        sum => alu_result,
--        carry_out => alu_carry_out
--    );
    
--    -- Branch target calculation
--    branch_adder: adder_4b port map(
--        src_a => id_ex.pc_plus_1,
--        src_b => id_ex.sign_ext_imm(3 downto 0),
--        sum => pc_branch_target,
--        carry_out => open
--    );
    
--    -- Corrected Branch Condition Check
--    branch_condition: process(id_ex, alu_src_a, write_data)
--    begin
--        -- Check for BEQ opcode (0100) and equality
--        if (id_ex.instruction(15 downto 12) = "0100") and 
--           (alu_src_a = write_data) then  -- Direct comparison since both are std_logic_vector
--            branch_taken <= '1';
--        else
--            branch_taken <= '0';
--        end if;
--    end process;
    
--    -- EX/MEM Pipeline Register
--    process(clk, reset)
--    begin
--        if reset = '1' then
--            ex_mem <= (
--                reg_write => '0',
--                mem_write => '0',
--                mem_to_reg => '0',
--                sw_to_reg => '0',
--                branch_taken => '0',
--                alu_result => (others => '0'),
--                write_data => (others => '0'),
--                write_reg => (others => '0')
--            );
--        elsif rising_edge(clk) then
--            ex_mem.reg_write <= id_ex.reg_write;
--            ex_mem.mem_write <= id_ex.mem_write;
--            ex_mem.mem_to_reg <= id_ex.mem_to_reg;
--            ex_mem.sw_to_reg <= id_ex.sw_to_reg;
--            ex_mem.branch_taken <= branch_taken;
--            ex_mem.alu_result <= alu_result;
--            ex_mem.write_data <= write_data;
--            ex_mem.write_reg <= write_reg;
--        end if;
--    end process;
    
--    -- =====================================================================
--    -- Stage 4: Memory Access (MEM)
--    -- =====================================================================
--    data_mem: data_memory port map(
--        reset => reset,
--        clk => clk,
--        write_enable => ex_mem.mem_write,
--        write_data => ex_mem.write_data,
--        addr_in => ex_mem.alu_result(3 downto 0),
--        data_out => mem_read_data
--    );
    
--    -- MEM/WB Pipeline Register
--    process(clk, reset)
--    begin
--        if reset = '1' then
--            mem_wb <= (
--                reg_write => '0',
--                mem_to_reg => '0',
--                sw_to_reg => '0',
--                alu_result => (others => '0'),
--                mem_read_data => (others => '0'),
--                write_reg => (others => '0')
--            );
--        elsif rising_edge(clk) then
--            mem_wb.reg_write <= ex_mem.reg_write;
--            mem_wb.mem_to_reg <= ex_mem.mem_to_reg;
--            mem_wb.sw_to_reg <= ex_mem.sw_to_reg;
--            mem_wb.alu_result <= ex_mem.alu_result;
--            mem_wb.mem_read_data <= mem_read_data;
--            mem_wb.write_reg <= ex_mem.write_reg;
--        end if;
--    end process;
    
--    -- =====================================================================
--    -- Stage 5: Write Back (WB)
--    -- =====================================================================
--    mem_to_reg_mux: mux_2to1_16b port map(
--        mux_select => mem_wb.mem_to_reg,
--        data_a => mem_wb.alu_result,
--        data_b => mem_wb.mem_read_data,
--        data_out => reg_write_data
--    );
    
--    -- LED register for LOADLED instruction
--    process(clk, reset)
--    begin
--        if reset = '1' then
--            led <= (others => '0');
--        elsif rising_edge(clk) then
--            if ex_mem.sw_to_reg = '1' then
--                led <= mem_read_data;
--            end if;
--        end if;
--    end process;
    
--end structural;

-- ===================================================================
-- MAIN PIPELINE CORE - 6 Stages with Tag Validation Integration
-- existing components + minimal additions for tag support
-- ===================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;  

entity pipelined_core is
    port ( 
        reset    : in  std_logic;
        clk      : in  std_logic;
        sw       : in  std_logic_vector(15 downto 0);
        led      : out std_logic_vector(15 downto 0)
    );
end pipelined_core;

architecture structural of pipelined_core is
    -- Pipeline register types
    type if_id_reg is record
        pc_plus_1  : std_logic_vector(3 downto 0);
        instruction: std_logic_vector(15 downto 0);
    end record;
    
    type id_ex_reg is record
        pc_plus_1    : std_logic_vector(3 downto 0);
        reg_dst      : std_logic;
        reg_write    : std_logic;
        alu_src      : std_logic;
        mem_write    : std_logic;
        mem_to_reg   : std_logic;
        sw_to_reg    : std_logic;
        tag_enable   : std_logic;                     -- NEW: Tag operation enable
        read_data_1  : std_logic_vector(15 downto 0);
        read_data_2  : std_logic_vector(15 downto 0);
        sign_ext_imm : std_logic_vector(15 downto 0);
        rs           : std_logic_vector(3 downto 0);
        rt           : std_logic_vector(3 downto 0);
        rd           : std_logic_vector(3 downto 0);
        instruction  : std_logic_vector(15 downto 0);
    end record;
    
    type ex_tag_reg is record
        reg_write     : std_logic;
        mem_write     : std_logic;
        mem_to_reg    : std_logic;
        sw_to_reg     : std_logic;
        tag_enable    : std_logic;                    -- NEW: Tag enable
        branch_taken  : std_logic;
        alu_result    : std_logic_vector(15 downto 0);
        write_data    : std_logic_vector(15 downto 0);
        write_reg     : std_logic_vector(3 downto 0);
        instruction   : std_logic_vector(15 downto 0); -- For tag operations
    end record;
    
    type tag_mem_reg is record
        reg_write     : std_logic;
        mem_write     : std_logic;
        mem_to_reg    : std_logic;
        sw_to_reg     : std_logic;
        branch_taken  : std_logic;
        final_result  : std_logic_vector(15 downto 0); -- ALU or Tag result
        write_data    : std_logic_vector(15 downto 0);
        write_reg     : std_logic_vector(3 downto 0);
    end record;
    
    type mem_wb_reg is record
        reg_write     : std_logic;
        mem_to_reg    : std_logic;
        sw_to_reg     : std_logic;
        final_result  : std_logic_vector(15 downto 0);
        mem_read_data : std_logic_vector(15 downto 0);
        write_reg     : std_logic_vector(3 downto 0);
    end record;
    
    -- Pipeline registers
    signal if_id   : if_id_reg;
    signal id_ex   : id_ex_reg;
    signal ex_tag  : ex_tag_reg;
    signal tag_mem : tag_mem_reg;
    signal mem_wb  : mem_wb_reg;
    
    -- Control signals
    signal stall        : std_logic;
    signal forward_a    : std_logic_vector(1 downto 0);
    signal forward_b    : std_logic_vector(1 downto 0);
    signal branch_taken : std_logic;
    
    -- Internal signals
    signal pc_current, pc_next, pc_plus_1 : std_logic_vector(3 downto 0);
    signal pc_branch_target : std_logic_vector(3 downto 0);
    signal instruction : std_logic_vector(15 downto 0);
    signal reg_dst, reg_write, alu_src, mem_write, mem_to_reg, sw_to_reg : std_logic;
    signal tag_enable : std_logic;
    signal read_data_1, read_data_2 : std_logic_vector(15 downto 0);
    signal sign_ext_imm : std_logic_vector(15 downto 0);
    signal write_reg : std_logic_vector(3 downto 0);
    signal alu_src_a, alu_src_b, alu_result : std_logic_vector(15 downto 0);
    signal alu_carry_out : std_logic;
    signal mem_read_data : std_logic_vector(15 downto 0);
    signal write_data : std_logic_vector(15 downto 0);
    signal reg_write_data : std_logic_vector(15 downto 0);
    signal pc_src : std_logic;
    
    -- Tag validation signals
    signal tag_result : std_logic_vector(15 downto 0);
    signal tag_input : std_logic_vector(31 downto 0);  -- Extended for tag processing
    signal tag_output : std_logic_vector(6 downto 0);  -- Tag size from your teammate's code
    
    -- ===================================================================
    -- EXISTING COMPONENT DECLARATIONS (unchanged)
    -- ===================================================================
    component program_counter is
        port ( reset    : in  std_logic;
               clk      : in  std_logic;
               write_enable : in  std_logic; 
               addr_in  : in  std_logic_vector(3 downto 0);
               addr_out : out std_logic_vector(3 downto 0) );
    end component;
    
    component instruction_memory is
        port ( reset    : in  std_logic;
               clk      : in  std_logic;
               addr_in  : in  std_logic_vector(3 downto 0);
               insn_out : out std_logic_vector(15 downto 0) );
    end component;
    
    component register_file is
        port ( reset           : in  std_logic;
               clk             : in  std_logic;
               read_register_a : in  std_logic_vector(3 downto 0);
               read_register_b : in  std_logic_vector(3 downto 0);
               write_enable    : in  std_logic;
               write_register  : in  std_logic_vector(3 downto 0);
               write_data      : in  std_logic_vector(15 downto 0);
               read_data_a     : out std_logic_vector(15 downto 0);
               read_data_b     : out std_logic_vector(15 downto 0) );
    end component;
    
    component control_unit is
        port ( opcode     : in  std_logic_vector(3 downto 0);
               reg_dst    : out std_logic;
               reg_write  : out std_logic;
               alu_src    : out std_logic;
               mem_write  : out std_logic;
               mem_to_reg : out std_logic;
               sw_to_reg  : out std_logic );
    end component;
    
    component data_memory is
        port ( reset        : in  std_logic;
               clk          : in  std_logic;
               write_enable : in  std_logic;
               write_data   : in  std_logic_vector(15 downto 0);
               addr_in      : in  std_logic_vector(3 downto 0);
               data_out     : out std_logic_vector(15 downto 0) );
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
    
    component sign_extend_4to16 is
        port ( data_in  : in  std_logic_vector(3 downto 0);
               data_out : out std_logic_vector(15 downto 0) );
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
    
    component mux_3to1_16b is
        port ( sel        : in  std_logic_vector(1 downto 0);
               data_a     : in  std_logic_vector(15 downto 0);
               data_b     : in  std_logic_vector(15 downto 0);
               data_c     : in  std_logic_vector(15 downto 0);
               data_out   : out std_logic_vector(15 downto 0) );
    end component;
    
    -- ===================================================================
    -- MINIMAL NEW COMPONENTS FOR TAG SUPPORT
    -- ===================================================================
    
    -- Enhanced control unit for tag operations
    component enhanced_control_unit is
        port ( opcode     : in  std_logic_vector(3 downto 0);
               reg_dst    : out std_logic;
               reg_write  : out std_logic;
               alu_src    : out std_logic;
               mem_write  : out std_logic;
               mem_to_reg : out std_logic;
               sw_to_reg  : out std_logic;
               tag_enable : out std_logic );
    end component;
    
    -- Your teammate's tag validation component
    component tag is
        generic(
            tag_size : integer := 6;
            bit_size : integer := 31   
        );
        port (
            incoming_bits : in std_logic_vector(31 downto 0);
            output_tag : out std_logic_vector(6 downto 0)
        );
    end component;

begin

    -- =====================================================================
    -- Stage 1: Instruction Fetch (IF)
    -- =====================================================================
    pc_mux: mux_2to1_4b port map(
        mux_select => pc_src,
        data_a => pc_plus_1,
        data_b => pc_branch_target,
        data_out => pc_next
    );
    
    pc_reg: program_counter port map(
        reset => reset,
        clk => clk,
        write_enable => not stall,
        addr_in => pc_next,
        addr_out => pc_current
    );
    
    pc_adder: adder_4b port map(
        src_a => pc_current,
        src_b => "0001",
        sum => pc_plus_1,
        carry_out => open
    );
    
    inst_mem: instruction_memory port map(
        reset => reset,
        clk => clk,
        addr_in => pc_current,
        insn_out => instruction
    );
    
    -- IF/ID Pipeline Register
    process(clk, reset)
    begin
        if reset = '1' then
            if_id.pc_plus_1 <= (others => '0');
            if_id.instruction <= (others => '0');
        elsif rising_edge(clk) then
            if stall = '0' then
                if_id.pc_plus_1 <= pc_plus_1;
                if_id.instruction <= instruction;
            end if;
        end if;
    end process;
    
    -- =====================================================================
    -- Stage 2: Instruction Decode (ID)
    -- =====================================================================
    
    -- Enhanced control unit that replaces your existing one
    control: enhanced_control_unit port map(
        opcode => if_id.instruction(15 downto 12),
        reg_dst => reg_dst,
        reg_write => reg_write,
        alu_src => alu_src,
        mem_write => mem_write,
        mem_to_reg => mem_to_reg,
        sw_to_reg => sw_to_reg,
        tag_enable => tag_enable
    );
    
    reg_file: register_file port map(
        reset => reset,
        clk => clk,
        read_register_a => if_id.instruction(11 downto 8),
        read_register_b => if_id.instruction(7 downto 4),
        write_enable => mem_wb.reg_write,
        write_register => mem_wb.write_reg,
        write_data => reg_write_data,
        read_data_a => read_data_1,
        read_data_b => read_data_2
    );
    
    sign_ext: sign_extend_4to16 port map(
        data_in => if_id.instruction(3 downto 0),
        data_out => sign_ext_imm
    );
    
    -- Hazard Detection
    hazard_detection: process(id_ex.mem_to_reg, id_ex.rt, if_id.instruction)
    begin
        stall <= '0';
        if (id_ex.mem_to_reg = '1') then
            if (id_ex.rt = if_id.instruction(11 downto 8)) or    
               (id_ex.rt = if_id.instruction(7 downto 4)) then   
                stall <= '1';
            end if;
        end if;
    end process;

    pc_src <= tag_mem.branch_taken;
    
    -- ID/EX Pipeline Register
    process(clk, reset)
    begin
        if reset = '1' then
            id_ex.pc_plus_1 <= (others => '0');
            id_ex.reg_dst <= '0';
            id_ex.reg_write <= '0';
            id_ex.alu_src <= '0';
            id_ex.mem_write <= '0';
            id_ex.mem_to_reg <= '0';
            id_ex.sw_to_reg <= '0';
            id_ex.tag_enable <= '0';
            id_ex.read_data_1 <= (others => '0');
            id_ex.read_data_2 <= (others => '0');
            id_ex.sign_ext_imm <= (others => '0');
            id_ex.rs <= (others => '0');
            id_ex.rt <= (others => '0');
            id_ex.rd <= (others => '0');
            id_ex.instruction <= (others => '0');
        elsif rising_edge(clk) then
            if stall = '1' then
                -- Insert bubble
                id_ex.reg_write <= '0';
                id_ex.mem_write <= '0';
                id_ex.mem_to_reg <= '0';
                id_ex.sw_to_reg <= '0';
                id_ex.tag_enable <= '0';
                id_ex.instruction <= X"0000";
            else
                id_ex.pc_plus_1 <= if_id.pc_plus_1;
                id_ex.reg_dst <= reg_dst;
                id_ex.reg_write <= reg_write;
                id_ex.alu_src <= alu_src;
                id_ex.mem_write <= mem_write;
                id_ex.mem_to_reg <= mem_to_reg;
                id_ex.sw_to_reg <= sw_to_reg;
                id_ex.tag_enable <= tag_enable;
                id_ex.read_data_1 <= read_data_1;
                id_ex.read_data_2 <= read_data_2;
                id_ex.sign_ext_imm <= sign_ext_imm;
                id_ex.rs <= if_id.instruction(11 downto 8);
                id_ex.rt <= if_id.instruction(7 downto 4);
                id_ex.rd <= if_id.instruction(3 downto 0);
                id_ex.instruction <= if_id.instruction;
            end if;
        end if;
    end process;
    
    -- =====================================================================
    -- Stage 3: Execute (EX)
    -- =====================================================================
    reg_dst_mux: mux_2to1_4b port map(
        mux_select => id_ex.reg_dst,
        data_a => id_ex.rt,
        data_b => id_ex.rd,
        data_out => write_reg
    );
    
    -- Forwarding Unit (Updated for 6-stage pipeline)
    forwarding_unit: process(tag_mem.reg_write, tag_mem.write_reg, mem_wb.reg_write, mem_wb.write_reg, id_ex.rs, id_ex.rt)
    begin
        -- Forward A
        if (tag_mem.reg_write = '1') and (tag_mem.write_reg = id_ex.rs) then
            forward_a <= "10";  -- From TAG/MEM stage
        elsif (mem_wb.reg_write = '1') and (mem_wb.write_reg = id_ex.rs) then
            forward_a <= "01";  -- From MEM/WB stage
        else
            forward_a <= "00";  -- No forwarding
        end if;
        
        -- Forward B
        if (tag_mem.reg_write = '1') and (tag_mem.write_reg = id_ex.rt) then
            forward_b <= "10";
        elsif (mem_wb.reg_write = '1') and (mem_wb.write_reg = id_ex.rt) then
            forward_b <= "01";
        else
            forward_b <= "00";
        end if;
    end process;
    
    -- ALU input A forwarding mux
    alu_src_a_mux: mux_3to1_16b port map(
        sel => forward_a,
        data_a => id_ex.read_data_1,
        data_b => reg_write_data,
        data_c => tag_mem.final_result,
        data_out => alu_src_a
    );
    
    -- ALU input B mux
    alu_src_b_mux1: mux_3to1_16b port map(
        sel => forward_b,
        data_a => id_ex.read_data_2,
        data_b => reg_write_data,
        data_c => tag_mem.final_result,
        data_out => write_data
    );
    
    alu_src_b_mux2: mux_2to1_16b port map(
        mux_select => id_ex.alu_src,
        data_a => write_data,
        data_b => id_ex.sign_ext_imm,
        data_out => alu_src_b
    );
    
    -- ALU (using your existing adder)
    alu: adder_16b port map(
        src_a => alu_src_a,
        src_b => alu_src_b,
        sum => alu_result,
        carry_out => alu_carry_out
    );
    
    -- Branch target calculation
    branch_adder: adder_4b port map(
        src_a => id_ex.pc_plus_1,
        src_b => id_ex.sign_ext_imm(3 downto 0),
        sum => pc_branch_target,
        carry_out => open
    );
    
    -- Branch condition check
    branch_condition: process(id_ex, alu_src_a, write_data)
    begin
        if (id_ex.instruction(15 downto 12) = "0100") and (alu_src_a = write_data) then
            branch_taken <= '1';
        else
            branch_taken <= '0';
        end if;
    end process;
    
    -- EX/TAG Pipeline Register
    process(clk, reset)
    begin
        if reset = '1' then
            ex_tag <= (
                reg_write => '0',
                mem_write => '0',
                mem_to_reg => '0',
                sw_to_reg => '0',
                tag_enable => '0',
                branch_taken => '0',
                alu_result => (others => '0'),
                write_data => (others => '0'),
                write_reg => (others => '0'),
                instruction => (others => '0')
            );
        elsif rising_edge(clk) then
            ex_tag.reg_write <= id_ex.reg_write;
            ex_tag.mem_write <= id_ex.mem_write;
            ex_tag.mem_to_reg <= id_ex.mem_to_reg;
            ex_tag.sw_to_reg <= id_ex.sw_to_reg;
            ex_tag.tag_enable <= id_ex.tag_enable;
            ex_tag.branch_taken <= branch_taken;
            ex_tag.alu_result <= alu_result;
            ex_tag.write_data <= write_data;
            ex_tag.write_reg <= write_reg;
            ex_tag.instruction <= id_ex.instruction;
        end if;
    end process;
    
    -- =====================================================================
    -- Stage 4: Tag Validation (TAG) - NEW STAGE
    -- =====================================================================
    
    -- Prepare input for tag validation (extend ALU result to 32 bits)
    tag_input <= X"0000" & ex_tag.alu_result;
    
    -- Jasper's tag validation unit
    tag_validator: tag
        generic map(
            tag_size => 6,
            bit_size => 31
        )
        port map(
            incoming_bits => tag_input,
            output_tag => tag_output
        );
    
    -- Extend tag output back to 16 bits for register storage
    tag_result <= "000000000" & tag_output;
    
    -- TAG/MEM Pipeline Register
    process(clk, reset)
    begin
        if reset = '1' then
            tag_mem <= (
                reg_write => '0',
                mem_write => '0',
                mem_to_reg => '0',
                sw_to_reg => '0',
                branch_taken => '0',
                final_result => (others => '0'),
                write_data => (others => '0'),
                write_reg => (others => '0')
            );
        elsif rising_edge(clk) then
            tag_mem.reg_write <= ex_tag.reg_write;
            tag_mem.mem_write <= ex_tag.mem_write;
            tag_mem.mem_to_reg <= ex_tag.mem_to_reg;
            tag_mem.sw_to_reg <= ex_tag.sw_to_reg;
            tag_mem.branch_taken <= ex_tag.branch_taken;
            tag_mem.write_data <= ex_tag.write_data;
            tag_mem.write_reg <= ex_tag.write_reg;
            
            -- Select between ALU result and tag result
            if ex_tag.tag_enable = '1' then
                tag_mem.final_result <= tag_result;
            else
                tag_mem.final_result <= ex_tag.alu_result;
            end if;
        end if;
    end process;
    
    -- =====================================================================
    -- Stage 5: Memory Access (MEM)
    -- =====================================================================
    data_mem: data_memory port map(
        reset => reset,
        clk => clk,
        write_enable => tag_mem.mem_write,
        write_data => tag_mem.write_data,
        addr_in => tag_mem.final_result(3 downto 0),
        data_out => mem_read_data
    );
    
    -- MEM/WB Pipeline Register
    process(clk, reset)
    begin
        if reset = '1' then
            mem_wb <= (
                reg_write => '0',
                mem_to_reg => '0',
                sw_to_reg => '0',
                final_result => (others => '0'),
                mem_read_data => (others => '0'),
                write_reg => (others => '0')
            );
        elsif rising_edge(clk) then
            mem_wb.reg_write <= tag_mem.reg_write;
            mem_wb.mem_to_reg <= tag_mem.mem_to_reg;
            mem_wb.sw_to_reg <= tag_mem.sw_to_reg;
            mem_wb.final_result <= tag_mem.final_result;
            mem_wb.mem_read_data <= mem_read_data;
            mem_wb.write_reg <= tag_mem.write_reg;
        end if;
    end process;
    
    -- =====================================================================
    -- Stage 6: Write Back (WB)
    -- =====================================================================
    mem_to_reg_mux: mux_2to1_16b port map(
        mux_select => mem_wb.mem_to_reg,
        data_a => mem_wb.final_result,  -- ALU or Tag result
        data_b => mem_wb.mem_read_data, -- Memory data
        data_out => reg_write_data
    );
    
    -- LED output register
    process(clk, reset)
    begin
        if reset = '1' then
            led <= (others => '0');
        elsif rising_edge(clk) then
            if mem_wb.sw_to_reg = '1' then
                led <= reg_write_data;
            end if;
        end if;
    end process;
    
end structural;

