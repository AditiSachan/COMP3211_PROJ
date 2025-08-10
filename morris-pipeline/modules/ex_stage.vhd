library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ex_stage is
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
end ex_stage;

architecture Behavioral of ex_stage is

    -- Component Declarations
    component alu is
        Port (
            opcode      : in  STD_LOGIC_VECTOR(3 downto 0);
            operand_a   : in  STD_LOGIC_VECTOR(15 downto 0);
            operand_b   : in  STD_LOGIC_VECTOR(15 downto 0);
            result      : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    component tag is
        generic(
            tag_size  : integer := 4;
            bit_size  : integer := 31;
            key_width : integer := 32
        );
        port(
            incoming_bits : in  std_logic_vector(30 downto 0); -- 31-bit input
            secret_key    : in  std_logic_vector(31 downto 0); -- 32-bit secret key
            output_tag    : out std_logic_vector(3 downto 0)   -- 4-bit tag
        );
    end component;

    component forwarding_mux is
        Port (
            select_signal : in  STD_LOGIC_VECTOR(1 downto 0);
            reg_data      : in  STD_LOGIC_VECTOR(15 downto 0);
            mem_data      : in  STD_LOGIC_VECTOR(15 downto 0);
            wb_data       : in  STD_LOGIC_VECTOR(15 downto 0);
            output_data   : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    -- Internal Signals
    signal forwarded_rs_data, forwarded_rt_data : STD_LOGIC_VECTOR(15 downto 0);
    signal alu_operand_b : STD_LOGIC_VECTOR(15 downto 0);
    signal alu_result_internal : STD_LOGIC_VECTOR(15 downto 0);
    
    -- Tag generation signals
    signal tag_gen_data : STD_LOGIC_VECTOR(30 downto 0);
    signal tag_gen_result : STD_LOGIC_VECTOR(3 downto 0);
    
    -- Secret key (hardcoded for now, could be from register)
    signal secret_key : STD_LOGIC_VECTOR(31 downto 0) := x"003101A0"; -- 32-bit secret key
    
    -- Validation signals
    signal generated_tag, received_tag : STD_LOGIC_VECTOR(3 downto 0);
    signal validation_result : STD_LOGIC;
    
    -- Control signals
    signal is_tag_gen_op, is_validate_op : STD_LOGIC;

begin

    -- Instantiate Forwarding Multiplexers
    FORWARD_MUX_A: forwarding_mux
        port map (
            select_signal => forward_a,
            reg_data => rs_data,
            mem_data => mem_forward,
            wb_data => wb_forward,
            output_data => forwarded_rs_data
        );

    FORWARD_MUX_B: forwarding_mux
        port map (
            select_signal => forward_b,
            reg_data => rt_data,
            mem_data => mem_forward,
            wb_data => wb_forward,
            output_data => forwarded_rt_data
        );

    -- ALU Operand B Selection (register or immediate)
    alu_operand_b <= forwarded_rt_data when alu_src = '0' else
                     "0000000" & immediate;

    -- Instantiate ALU
    ALU_INST: alu
        port map (
            opcode => opcode,
            operand_a => forwarded_rs_data,
            operand_b => alu_operand_b,
            result => alu_result_internal
        );

    -- Tag Generation Control
    is_tag_gen_op <= '1' when opcode = "0010" else '0'; -- GEN_TAG
    is_validate_op <= '1' when opcode = "0011" else '0'; -- VALIDATE

    -- Prepare data for tag generation (31-bit format)
    -- Format: {tally[7:0], candidate[1:0], district[1:0], 19'b0}
    process(forwarded_rs_data)
    begin
        -- Extract tally, candidate, district from rs_data (assumes they're in low 12 bits)
        tag_gen_data <= forwarded_rs_data(11 downto 0) & "0000000000000000000";
    end process;

    -- Instantiate Tag Generation Module (Combinational)
    TAG_GEN_INST: tag
        port map (
            incoming_bits => tag_gen_data,
            secret_key => secret_key,
            output_tag => tag_gen_result
        );

    -- Tag Validation Logic
    process(opcode, forwarded_rs_data, forwarded_rt_data, tag_gen_result)
    begin
        if is_validate_op = '1' then
            generated_tag <= forwarded_rs_data(3 downto 0); -- Generated tag from previous instruction
            received_tag <= forwarded_rt_data(3 downto 0);  -- Received tag
            if generated_tag = received_tag then
                validation_result <= '1';
            else
                validation_result <= '0';
            end if;
        else
            validation_result <= '0';
        end if;
    end process;

    -- Output Selection
    process(opcode, alu_result_internal, tag_gen_result, validation_result)
    begin
        case opcode is
            when "0010" => -- GEN_TAG
                alu_result <= "000000000000" & tag_gen_result;
                
            when "0011" => -- VALIDATE
                alu_result <= "000000000000000" & validation_result;
                
            when others =>
                alu_result <= alu_result_internal;
        end case;
    end process;

    -- Output Assignments
    tag_result <= tag_gen_result;
    validation <= validation_result;
    tag_gen_busy <= '0'; -- Never busy since it's combinational
    rt_data_out <= forwarded_rt_data; -- Pass through for memory stage

end Behavioral;


-- ALU Implementation
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
    Port (
        opcode      : in  STD_LOGIC_VECTOR(3 downto 0);
        operand_a   : in  STD_LOGIC_VECTOR(15 downto 0);
        operand_b   : in  STD_LOGIC_VECTOR(15 downto 0);
        result      : out STD_LOGIC_VECTOR(15 downto 0)
    );
end alu;

architecture Behavioral of alu is
begin

    process(opcode, operand_a, operand_b)
    begin
        case opcode is
            when "0000" => -- LOAD_INPUT
                result <= operand_a; -- Pass through input data
                
            when "0001" => -- EXTRACT  
                result <= operand_a; -- Pass through extracted field
                
            when "0100" => -- CALC_ADDR (candidate*5 + district)
                result <= std_logic_vector(resize(
                    unsigned(operand_a(1 downto 0)) * 5 + unsigned(operand_b(1 downto 0)), 16
                ));
                
            when "0101" => -- READ_TALLY
                result <= operand_b; -- Address from immediate
                
            when "0110" => -- WRITE_TALLY  
                result <= operand_b; -- Address from immediate
                
            when "0111" => -- ADD
                result <= std_logic_vector(unsigned(operand_a) + unsigned(operand_b));
                
            when "1001" => -- SUB
                result <= std_logic_vector(unsigned(operand_a) - unsigned(operand_b));
                
            when "1010" => -- AND
                result <= operand_a and operand_b;
                
            when "1011" => -- OR
                result <= operand_a or operand_b;
                
            when "1100" => -- SLL (Shift Left Logical)
                result <= std_logic_vector(
                    shift_left(unsigned(operand_a), to_integer(unsigned(operand_b(3 downto 0))))
                );
                
            when "1101" => -- SRL (Shift Right Logical)
                result <= std_logic_vector(
                    shift_right(unsigned(operand_a), to_integer(unsigned(operand_b(3 downto 0))))
                );
                
            when "1000" => -- BRANCH_VALID
                result <= operand_b; -- Branch target from immediate
                
            when "1110" => -- BEQ
                result <= operand_b; -- Branch target from immediate
                
            when others => -- NOP and undefined
                result <= (others => '0');
        end case;
    end process;

end Behavioral;


-- Forwarding Multiplexer Implementation
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity forwarding_mux is
    Port (
        select_signal : in  STD_LOGIC_VECTOR(1 downto 0);
        reg_data      : in  STD_LOGIC_VECTOR(15 downto 0);
        mem_data      : in  STD_LOGIC_VECTOR(15 downto 0);
        wb_data       : in  STD_LOGIC_VECTOR(15 downto 0);
        output_data   : out STD_LOGIC_VECTOR(15 downto 0)
    );
end forwarding_mux;

architecture Behavioral of forwarding_mux is
begin

    process(select_signal, reg_data, mem_data, wb_data)
    begin
        case select_signal is
            when "00" => 
                output_data <= reg_data;    -- No forwarding
            when "01" => 
                output_data <= wb_data;     -- Forward from WB stage
            when "10" => 
                output_data <= mem_data;    -- Forward from MEM stage
            when others => 
                output_data <= reg_data;    -- Default to register data
        end case;
    end process;

end Behavioral;