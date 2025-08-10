library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity id_stage is
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
end id_stage;

architecture Behavioral of id_stage is

    -- Component Declarations
    component instruction_decoder is
        Port (
            instruction : in  STD_LOGIC_VECTOR(15 downto 0);
            opcode      : out STD_LOGIC_VECTOR(3 downto 0);
            rs_addr     : out STD_LOGIC_VECTOR(2 downto 0);
            rt_addr     : out STD_LOGIC_VECTOR(2 downto 0);
            rd_addr     : out STD_LOGIC_VECTOR(2 downto 0);
            immediate   : out STD_LOGIC_VECTOR(8 downto 0);
            inst_type   : out STD_LOGIC_VECTOR(1 downto 0) -- 00=R, 01=I, 10=M
        );
    end component;

    component register_file is
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            read_reg1   : in  STD_LOGIC_VECTOR(2 downto 0);
            read_reg2   : in  STD_LOGIC_VECTOR(2 downto 0);
            write_reg   : in  STD_LOGIC_VECTOR(2 downto 0);
            write_data  : in  STD_LOGIC_VECTOR(15 downto 0);
            write_en    : in  STD_LOGIC;
            read_data1  : out STD_LOGIC_VECTOR(15 downto 0);
            read_data2  : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    component control_unit is
        Port (
            opcode      : in  STD_LOGIC_VECTOR(3 downto 0);
            reg_write   : out STD_LOGIC;
            mem_read    : out STD_LOGIC;
            mem_write   : out STD_LOGIC;
            alu_src     : out STD_LOGIC;
            branch      : out STD_LOGIC
        );
    end component;

    component hazard_detection_unit is
        Port (
            id_rs           : in  STD_LOGIC_VECTOR(2 downto 0);
            id_rt           : in  STD_LOGIC_VECTOR(2 downto 0);
            ex_rd           : in  STD_LOGIC_VECTOR(2 downto 0);
            ex_mem_read     : in  STD_LOGIC;
            tag_gen_busy    : in  STD_LOGIC;
            stall_pipeline  : out STD_LOGIC
        );
    end component;

    -- Internal Signals
    signal decoded_opcode : STD_LOGIC_VECTOR(3 downto 0);
    signal decoded_rs, decoded_rt, decoded_rd : STD_LOGIC_VECTOR(2 downto 0);
    signal decoded_immediate : STD_LOGIC_VECTOR(8 downto 0);
    signal inst_type : STD_LOGIC_VECTOR(1 downto 0);
    
    signal rf_read_data1, rf_read_data2 : STD_LOGIC_VECTOR(15 downto 0);
    signal processed_rs_data, processed_rt_data : STD_LOGIC_VECTOR(15 downto 0);
    
    -- Control signals
    signal ctrl_reg_write, ctrl_mem_read, ctrl_mem_write : STD_LOGIC;
    signal ctrl_alu_src, ctrl_branch : STD_LOGIC;

begin

    -- Instantiate Instruction Decoder
    INST_DECODER: instruction_decoder
        port map (
            instruction => instruction,
            opcode => decoded_opcode,
            rs_addr => decoded_rs,
            rt_addr => decoded_rt,
            rd_addr => decoded_rd,
            immediate => decoded_immediate,
            inst_type => inst_type
        );

    -- Instantiate Register File
    REG_FILE: register_file
        port map (
            clk => clk,
            reset => reset,
            read_reg1 => decoded_rs,
            read_reg2 => decoded_rt,
            write_reg => writeback_reg,
            write_data => writeback_data,
            write_en => writeback_en,
            read_data1 => rf_read_data1,
            read_data2 => rf_read_data2
        );

    -- Instantiate Control Unit
    CTRL_UNIT: control_unit
        port map (
            opcode => decoded_opcode,
            reg_write => ctrl_reg_write,
            mem_read => ctrl_mem_read,
            mem_write => ctrl_mem_write,
            alu_src => ctrl_alu_src,
            branch => ctrl_branch
        );

    -- Instantiate Hazard Detection Unit
    HAZARD_DETECT: hazard_detection_unit
        port map (
            id_rs => decoded_rs,
            id_rt => decoded_rt,
            ex_rd => "000", -- Connected from pipeline register in top level
            ex_mem_read => '0', -- Connected from pipeline register in top level
            tag_gen_busy => '0', -- Connected from EX stage in top level
            stall_pipeline => stall_pipeline
        );

    -- Special Data Processing for LOAD_INPUT and EXTRACT instructions
    process(decoded_opcode, decoded_immediate, input_data, rf_read_data1, rf_read_data2)
    begin
        -- Default: pass through register file data
        processed_rs_data <= rf_read_data1;
        processed_rt_data <= rf_read_data2;
        
        case decoded_opcode is
            when "0000" => -- LOAD_INPUT
                -- For LOAD_INPUT, rs_data should be the input_data
                processed_rs_data <= input_data;
                
            when "0001" => -- EXTRACT
                -- For EXTRACT, rs_data should be extracted field from input_data
                case decoded_immediate(1 downto 0) is
                    when "00" => -- Extract tag
                        processed_rs_data <= "000000000000" & input_data(15 downto 12);
                    when "01" => -- Extract tally
                        processed_rs_data <= "00000000" & input_data(11 downto 4);
                    when "10" => -- Extract candidate
                        processed_rs_data <= "00000000000000" & input_data(3 downto 2);
                    when "11" => -- Extract district
                        processed_rs_data <= "00000000000000" & input_data(1 downto 0);
                    when others =>
                        processed_rs_data <= (others => '0');
                end case;
                
            when others =>
                -- For all other instructions, use normal register data
                processed_rs_data <= rf_read_data1;
                processed_rt_data <= rf_read_data2;
        end case;
    end process;

    -- Output Assignments
    opcode <= decoded_opcode;
    rs_addr <= decoded_rs;
    rt_addr <= decoded_rt;
    rd_addr <= decoded_rd;
    immediate <= decoded_immediate;
    rs_data <= processed_rs_data;
    rt_data <= processed_rt_data;
    
    reg_write <= ctrl_reg_write;
    mem_read <= ctrl_mem_read;
    mem_write <= ctrl_mem_write;
    alu_src <= ctrl_alu_src;
    branch <= ctrl_branch;

end Behavioral;


-- Instruction Decoder Implementation
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity instruction_decoder is
    Port (
        instruction : in  STD_LOGIC_VECTOR(15 downto 0);
        opcode      : out STD_LOGIC_VECTOR(3 downto 0);
        rs_addr     : out STD_LOGIC_VECTOR(2 downto 0);
        rt_addr     : out STD_LOGIC_VECTOR(2 downto 0);
        rd_addr     : out STD_LOGIC_VECTOR(2 downto 0);
        immediate   : out STD_LOGIC_VECTOR(8 downto 0);
        inst_type   : out STD_LOGIC_VECTOR(1 downto 0)
    );
end instruction_decoder;

architecture Behavioral of instruction_decoder is
begin

    -- Extract opcode (always bits 15:12)
    opcode <= instruction(15 downto 12);
    
    -- Decode instruction format based on opcode
    process(instruction)
    begin
        case instruction(15 downto 12) is
            -- I-Type Instructions
            when "0000" | "0001" | "1000" | "1110" =>
                inst_type <= "01"; -- I-Type
                rs_addr <= instruction(11 downto 9);
                rt_addr <= "000"; -- Not used in I-Type
                rd_addr <= "000"; -- Not used in I-Type  
                immediate <= instruction(8 downto 0);
                
            -- M-Type Instructions  
            when "0101" | "0110" =>
                inst_type <= "10"; -- M-Type
                rs_addr <= instruction(11 downto 9);
                rt_addr <= "000"; -- Not used in M-Type
                rd_addr <= "000"; -- Not used in M-Type
                immediate <= instruction(8 downto 0);
                
            -- R-Type Instructions (default)
            when others =>
                inst_type <= "00"; -- R-Type
                rs_addr <= instruction(11 downto 9);
                rt_addr <= instruction(8 downto 6);
                rd_addr <= instruction(5 downto 3);
                immediate <= "000000000"; -- Not used in R-Type
        end case;
    end process;

end Behavioral;


-- Register File Implementation
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity register_file is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        read_reg1   : in  STD_LOGIC_VECTOR(2 downto 0);
        read_reg2   : in  STD_LOGIC_VECTOR(2 downto 0);
        write_reg   : in  STD_LOGIC_VECTOR(2 downto 0);
        write_data  : in  STD_LOGIC_VECTOR(15 downto 0);
        write_en    : in  STD_LOGIC;
        read_data1  : out STD_LOGIC_VECTOR(15 downto 0);
        read_data2  : out STD_LOGIC_VECTOR(15 downto 0)
    );
end register_file;

architecture Behavioral of register_file is
    
    -- Register array: R0 to R7
    type reg_array is array (0 to 7) of STD_LOGIC_VECTOR(15 downto 0);
    signal registers : reg_array := (others => (others => '0'));
    
begin

    -- Write Process
    process(clk, reset)
    begin
        if reset = '1' then
            registers <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if write_en = '1' and write_reg /= "000" then
                -- R0 is hardwired to 0, cannot be written
                registers(to_integer(unsigned(write_reg))) <= write_data;
            end if;
        end if;
    end process;

    -- Read Process (Asynchronous)
    process(read_reg1, read_reg2, registers)
    begin
        -- R0 always reads as 0
        if read_reg1 = "000" then
            read_data1 <= (others => '0');
        else
            read_data1 <= registers(to_integer(unsigned(read_reg1)));
        end if;
        
        if read_reg2 = "000" then
            read_data2 <= (others => '0');
        else
            read_data2 <= registers(to_integer(unsigned(read_reg2)));
        end if;
    end process;

end Behavioral;


-- Control Unit Implementation
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity control_unit is
    Port (
        opcode      : in  STD_LOGIC_VECTOR(3 downto 0);
        reg_write   : out STD_LOGIC;
        mem_read    : out STD_LOGIC;
        mem_write   : out STD_LOGIC;
        alu_src     : out STD_LOGIC;
        branch      : out STD_LOGIC
    );
end control_unit;

architecture Behavioral of control_unit is
begin

    process(opcode)
    begin
        -- Default values
        reg_write <= '0';
        mem_read <= '0';
        mem_write <= '0';
        alu_src <= '0';
        branch <= '0';
        
        case opcode is
            when "0000" => -- LOAD_INPUT
                reg_write <= '1';
                alu_src <= '1'; -- Use immediate/input data
                
            when "0001" => -- EXTRACT
                reg_write <= '1';
                alu_src <= '1'; -- Use immediate for field selection
                
            when "0010" => -- GEN_TAG
                reg_write <= '1';
                alu_src <= '0'; -- Use register data
                
            when "0011" => -- VALIDATE
                reg_write <= '1';
                alu_src <= '0'; -- Use register data
                
            when "0100" => -- CALC_ADDR
                reg_write <= '1';
                alu_src <= '0'; -- Use register data
                
            when "0101" => -- READ_TALLY
                reg_write <= '1';
                mem_read <= '1';
                alu_src <= '1'; -- Use immediate for address
                
            when "0110" => -- WRITE_TALLY
                mem_write <= '1';
                alu_src <= '1'; -- Use immediate for address
                
            when "0111" => -- ADD
                reg_write <= '1';
                alu_src <= '0'; -- Use register data
                
            when "1000" => -- BRANCH_VALID
                branch <= '1';
                alu_src <= '1'; -- Use immediate for branch target
                
            when "1001" => -- SUB
                reg_write <= '1';
                alu_src <= '0'; -- Use register data
                
            when "1010" => -- AND
                reg_write <= '1';
                alu_src <= '0'; -- Use register data
                
            when "1011" => -- OR
                reg_write <= '1';
                alu_src <= '0'; -- Use register data
                
            when "1100" => -- SLL
                reg_write <= '1';
                alu_src <= '0'; -- Use register data
                
            when "1101" => -- SRL
                reg_write <= '1';
                alu_src <= '0'; -- Use register data
                
            when "1110" => -- BEQ
                branch <= '1';
                alu_src <= '1'; -- Use immediate for branch target
                
            when "1111" => -- NOP
                -- All signals remain default (0)
                
            when others =>
                -- Invalid opcode, all signals remain default (0)
        end case;
    end process;

end Behavioral;


-- Hazard Detection Unit Implementation
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hazard_detection_unit is
    Port (
        id_rs           : in  STD_LOGIC_VECTOR(2 downto 0);
        id_rt           : in  STD_LOGIC_VECTOR(2 downto 0);
        ex_rd           : in  STD_LOGIC_VECTOR(2 downto 0);
        ex_mem_read     : in  STD_LOGIC;
        tag_gen_busy    : in  STD_LOGIC;
        stall_pipeline  : out STD_LOGIC
    );
end hazard_detection_unit;

architecture Behavioral of hazard_detection_unit is
begin

    process(id_rs, id_rt, ex_rd, ex_mem_read, tag_gen_busy)
    begin
        stall_pipeline <= '0'; -- Default: no stall
        
        -- Stall if tag generation is busy
        if tag_gen_busy = '1' then
            stall_pipeline <= '1';
        end if;
        
        -- Stall for load-use hazard
        if ex_mem_read = '1' then
            if (ex_rd = id_rs and id_rs /= "000") or 
               (ex_rd = id_rt and id_rt /= "000") then
                stall_pipeline <= '1';
            end if;
        end if;
    end process;

end Behavioral;