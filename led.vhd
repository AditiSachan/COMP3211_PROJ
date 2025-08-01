library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pipelined_processor is
    Port (
        clk     : in  std_logic;
        led    : out std_logic_vector(7 downto 0)
    );
end pipelined_processor;

architecture Behavioral of pipelined_processor is

    type reg_array is array(0 to 7) of std_logic_vector(15 downto 0);
    signal reg_file : reg_array := (others => (others => '0'));

    signal pc       : std_logic_vector(3 downto 0) := (others => '0');
    signal pc_next  : std_logic_vector(3 downto 0);

    type pipeline_IF_ID is record
        insn : std_logic_vector(15 downto 0);
        pc   : std_logic_vector(3 downto 0);
    end record;

    type pipeline_ID_EX is record
        opcode  : std_logic_vector(3 downto 0);
        rs_val  : std_logic_vector(15 downto 0);
        rt_val  : std_logic_vector(15 downto 0);
        rd      : integer range 0 to 7;
        rt      : integer range 0 to 7;
        imm     : std_logic_vector(7 downto 0);
        pc      : std_logic_vector(3 downto 0);
    end record;

    type pipeline_EX_WB is record
        result  : std_logic_vector(15 downto 0);
        rd      : integer range 0 to 7;
        write   : std_logic;
    end record;

    signal IF_ID : pipeline_IF_ID;
    signal ID_EX : pipeline_ID_EX;
    signal EX_WB : pipeline_EX_WB;

    signal stall  : std_logic := '0';
    signal reset : std_logic := '0';

    --instruction memory
    type instr_mem_type is array(0 to 15) of std_logic_vector(15 downto 0);
    constant instr_mem : instr_mem_type := (
        x"8100", -- add r1, r0, r0
        x"8221", -- add r2, r1, r1
        x"4212", -- beq r2, r1, 2
        x"8031", -- add r3, r0, r1
        x"8412", -- add r4, r1, r2
        others => x"0000"
    );

    function sign_extend(x: std_logic_vector(7 downto 0)) return std_logic_vector is
    begin
        return std_logic_vector(resize(signed(x), 16));
    end;

begin
    --Fetch
    process(clk, reset)
    begin
        if reset = '1' then
            pc <= (others => '0');
        elsif rising_edge(clk) then
            if stall = '0' then
                pc <= pc_next;
                IF_ID.insn <= instr_mem(to_integer(unsigned(pc)));
                IF_ID.pc   <= pc;
            end if;
        end if;
    end process;

    --Decode
    process(IF_ID)
        variable insn  : std_logic_vector(15 downto 0);
        variable op    : std_logic_vector(3 downto 0);
        variable rs, rt, rd : integer range 0 to 7;
    begin
        insn := IF_ID.insn;
        op   := insn(15 downto 12);
        rs   := to_integer(unsigned(insn(11 downto 9)));
        rt   := to_integer(unsigned(insn(8 downto 6)));
        rd   := to_integer(unsigned(insn(5 downto 3)));

        ID_EX.opcode <= op;
        ID_EX.rs_val <= reg_file(rs);
        ID_EX.rt_val <= reg_file(rt);
        ID_EX.rd     <= rd;
        ID_EX.rt     <= rt;
        ID_EX.imm    <= insn(7 downto 0);
        ID_EX.pc     <= IF_ID.pc;

        -- Detect BEQ hazard
        if EX_WB.write = '1' and 
           (EX_WB.rd = rs or EX_WB.rd = rt) and 
           ID_EX.opcode = "0100" then -- OP_BEQ
            stall <= '1';
        else
            stall <= '0';
        end if;
    end process;

    --Execute
    process(ID_EX)
        variable pc_s     : signed(4 downto 0);
        variable offset_s : signed(4 downto 0);
        variable result_s : signed(4 downto 0);
    begin
        case ID_EX.opcode is
            when "1000" =>  --add
                EX_WB.result <= std_logic_vector(
                                    unsigned(ID_EX.rs_val) + unsigned(ID_EX.rt_val));
                EX_WB.rd     <= ID_EX.rd;
                EX_WB.write  <= '1';
                pc_next      <= std_logic_vector(unsigned(ID_EX.pc) + 1);
    
            when "0100" =>  --beq
                pc_s := signed('0' & ID_EX.pc);
                offset_s := resize(signed(ID_EX.imm(3 downto 0)), 5);
                if ID_EX.rs_val = ID_EX.rt_val then
                    result_s := pc_s + 1 + offset_s;
                else
                    result_s := pc_s + 1;
                end if;
                pc_next <= std_logic_vector(result_s(3 downto 0));
    
            when others =>
                pc_next <= std_logic_vector(unsigned(ID_EX.pc) + 1);
        end case;
    end process;

    --Writeback
    process(clk)
    begin
        if rising_edge(clk) then
            if EX_WB.write = '1' then
                reg_file(EX_WB.rd) <= EX_WB.result;
            end if;
        end if;
    end process;

end Behavioral;