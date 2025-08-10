# Election Processor ISA and Data Path Documentation

## 1. Instruction Set Architecture (ISA)

### 1.1 Overview
16-bit RISC processor designed specifically for real-time election vote tallying with cryptographic tag validation.

### 1.2 Instruction Formats

#### R-Type (Register Operations)
```
[15:12] Opcode | [11:9] Rs | [8:6] Rt | [5:3] Rd | [2:0] Func
```

#### I-Type (Immediate Operations)  
```
[15:12] Opcode | [11:9] Rs | [8:0] Immediate (9-bit signed)
```

#### M-Type (Memory Operations)
```
[15:12] Opcode | [11:9] Rs | [8:0] Address/Offset (9-bit)
```

### 1.3 Register File
- **8 Registers**: R0, R1, R2, R3, R4, R5, R6, R7
- **R0**: Always contains 0 (hardwired)
- **R1-R7**: General purpose registers (16-bit each)

### 1.4 Complete Instruction Set

| Opcode | Mnemonic | Format | Description | Encoding Example |
|--------|----------|--------|-------------|------------------|
| 0000 | LOAD_INPUT | I-Type | Load 16-bit input data to register Rs | `0000 001 000000000` |
| 0001 | EXTRACT | I-Type | Extract field from input (field in Imm[1:0]) | `0001 010 000000001` |
| 0010 | GEN_TAG | R-Type | Generate 4-bit tag from 31-bit padded data | `0010 001 000 110 000` |
| 0011 | VALIDATE | R-Type | Compare generated tag with received tag | `0011 110 101 111 000` |
| 0100 | CALC_ADDR | R-Type | Calculate tally table address (cand*5+dist) | `0100 011 100 001 000` |
| 0101 | READ_TALLY | M-Type | Read value from tally table | `0101 010 000000000` |
| 0110 | WRITE_TALLY | M-Type | Write value to tally table | `0110 010 000000000` |
| 0111 | ADD | R-Type | Rs + Rt → Rd | `0111 010 010 010 000` |
| 1000 | BRANCH_VALID | I-Type | Branch if validation flag set | `1000 111 000001111` |
| 1001 | SUB | R-Type | Rs - Rt → Rd | `1001 010 011 001 000` |
| 1010 | AND | R-Type | Rs & Rt → Rd | `1010 010 011 001 000` |
| 1011 | OR | R-Type | Rs \| Rt → Rd | `1011 010 011 001 000` |
| 1100 | SLL | R-Type | Shift Rs left by Rt bits → Rd | `1100 010 011 001 000` |
| 1101 | SRL | R-Type | Shift Rs right by Rt bits → Rd | `1101 010 011 001 000` |
| 1110 | BEQ | I-Type | Branch if Rs == 0 | `1110 000 000000000` |
| 1111 | NOP | - | No operation | `1111 000 000000000` |

### 1.5 Election-Specific Instructions

#### LOAD_INPUT (0000)
- **Purpose**: Load 16-bit election record from external input
- **Operation**: Rs ← INPUT_DATA[15:0]
- **Format**: I-Type

#### EXTRACT (0001)  
- **Purpose**: Extract specific fields from input record
- **Operation**: 
  - field=00: Rs ← tag[15:12] (zero-extended)
  - field=01: Rs ← tally[11:4] (zero-extended)
  - field=10: Rs ← candidate[3:2] (zero-extended)  
  - field=11: Rs ← district[1:0] (zero-extended)
- **Format**: I-Type

#### GEN_TAG (0010)
- **Purpose**: Generate cryptographic tag using secret key
- **Operation**: Generate 4-bit tag from {tally, candidate, district, 19'b0}
- **Format**: R-Type

#### VALIDATE (0011)
- **Purpose**: Compare generated and received tags
- **Operation**: Rd ← (Rs[3:0] == Rt[3:0]) ? 1 : 0
- **Format**: R-Type

#### CALC_ADDR (0100)
- **Purpose**: Calculate tally table address
- **Operation**: Rd ← Rs * 5 + Rt (candidate_id * 5 + district_id)
- **Format**: R-Type

## 2. Data Path Architecture

### 2.1 Pipeline Overview
5-stage pipeline: **IF → ID → EX → MEM → WB**

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│   IF    │    │   ID    │    │   EX    │    │  MEM    │    │   WB    │
│ Fetch   │ -> │ Decode  │ -> │Execute  │ -> │ Memory  │ -> │Writeback│
│         │    │         │    │         │    │         │    │         │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
     |              |              |              |              |
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ IF/ID   │    │ ID/EX   │    │ EX/MEM  │    │ MEM/WB  │
│  Reg    │    │  Reg    │    │  Reg    │    │  Reg    │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
```

### 2.2 Stage-by-Stage Data Flow

#### 2.2.1 IF Stage (Instruction Fetch)
**Components:**
- Program Counter (PC)
- Instruction Memory (256 instructions)

**Data Flow:**
```
PC → Instruction Memory → Instruction[15:0]
PC + 1 → PC_plus_one
```

**Operations:**
- Fetch instruction from memory at PC address
- Increment PC for next instruction
- Handle branch targets when branch_taken = 1

#### 2.2.2 ID Stage (Instruction Decode)
**Components:**
- Instruction Decoder
- Register File (8 × 16-bit registers)
- Control Unit
- Hazard Detection Unit

**Data Flow:**
```
Instruction[15:0] → Decoder → {opcode, rs_addr, rt_addr, rd_addr, immediate}
{rs_addr, rt_addr} → Register File → {rs_data, rt_data}
input_data[15:0] → Special processing for LOAD_INPUT/EXTRACT
```

**Special Election Processing:**
- **LOAD_INPUT**: Rs_data = input_data (not register file)
- **EXTRACT**: Rs_data = extracted field from input_data based on immediate value

#### 2.2.3 EX Stage (Execute)
**Components:**
- ALU (16-bit arithmetic/logic operations)
- Tag Generation Module (cryptographic tag computation)
- Forwarding Multiplexers
- Address Calculator

**Data Flow:**
```
{rs_data, rt_data} → Forwarding Muxes → {operand_a, operand_b}
{operand_a, operand_b} → ALU → alu_result[15:0]

For GEN_TAG:
{tally, candidate, district} → Tag Module → generated_tag[3:0]

For VALIDATE:
{generated_tag, received_tag} → Comparator → validation_result
```

**Tag Generation Process:**
1. Combine tally[7:0] + candidate[1:0] + district[1:0] + 19'b0 = 31-bit input
2. Apply secret key (x"32110000") to tag generation algorithm
3. Output 4-bit cryptographic tag

#### 2.2.4 MEM Stage (Memory Access)
**Components:**
- Tally Table Memory (20 × 16-bit words)
- Memory Controller (validation-based write control)
- Address Decoder

**Data Flow:**
```
alu_result → address[4:0] (for 20-location tally table)
rt_data → write_data[15:0]
validation → write_enable (security control)

Memory Layout:
Address 0-4:   Candidate 0 [District 0, District 1, District 2, District 3, Total]
Address 5-9:   Candidate 1 [District 0, District 1, District 2, District 3, Total]
Address 10-14: Candidate 2 [District 0, District 1, District 2, District 3, Total]
Address 15-19: Candidate 3 [District 0, District 1, District 2, District 3, Total]
```

**Security Feature:**
- Memory writes only occur when validation = 1
- Invalid records are dropped (no tally update)

#### 2.2.5 WB Stage (Write Back)
**Components:**
- Write Back Multiplexer

**Data Flow:**
```
mem_to_reg = 0: writeback_data = alu_result (compute instructions)
mem_to_reg = 1: writeback_data = mem_data (load instructions)
writeback_data → Register File[rd_addr]
```

### 2.3 Control Signals

#### 2.3.1 ALU Control
```
LOAD_INPUT:  Pass through input data
EXTRACT:     Pass through extracted field  
CALC_ADDR:   candidate * 5 + district
GEN_TAG:     Generate cryptographic tag
VALIDATE:    Compare 4-bit tags
ADD/SUB:     Arithmetic operations
READ_TALLY:  Pass address
WRITE_TALLY: Pass address
```

#### 2.3.2 Memory Control
```
reg_write:   Enable register file write
mem_read:    Enable memory read
mem_write:   Enable memory write (gated by validation)
alu_src:     Select immediate vs register for ALU operand B
```

### 2.4 Hazard Handling

#### 2.4.1 Data Hazards
**Forwarding Unit:** Detects when EX stage needs data from MEM/WB stages
```
Forward from MEM: Recent ALU results, tag generation results
Forward from WB:  Memory read data, older computation results
```

**Load-Use Hazards:** Stall pipeline when instruction needs result from previous load

#### 2.4.2 Control Hazards
**Branch Prediction:** Simple predict-not-taken
**Pipeline Flush:** Insert NOPs when branch taken

#### 2.4.3 Structural Hazards
**Single-port Memory:** Tally table has one read/write port
**Tag Generation:** Combinational (no structural hazard)

### 2.5 Election Record Processing Flow

#### 2.5.1 Input Format
```
16-bit input_data: {tag_rx[15:12], tally[11:4], candidate[3:2], district[1:0]}
```

#### 2.5.2 Processing Steps
1. **LOAD_INPUT R1**: Load 16-bit record
2. **EXTRACT R2, 01**: Extract tally → R2
3. **EXTRACT R3, 10**: Extract candidate → R3
4. **EXTRACT R4, 11**: Extract district → R4
5. **EXTRACT R5, 00**: Extract received tag → R5
6. **GEN_TAG R1, R6**: Generate tag from record data → R6
7. **VALIDATE R6, R5, R7**: Compare tags → R7 (validation flag)
8. **CALC_ADDR R3, R4, R1**: Calculate tally address → R1
9. **READ_TALLY R2, R1**: Read current tally → R2
10. **ADD R2, R2, R2**: Add incremental tally
11. **WRITE_TALLY R2, R1**: Write updated tally (if valid)
12. **Loop back** to process next record

#### 2.5.3 Output Format
```
16-bit output_data: {validation[15], candidate_total[14:4], candidate[3:2], district[1:0]}
```

