# Instruction Set 

## Register Architecture
- **R0-R15**: General purpose registers (16 x 16-bit)
- **PC**: Program Counter
- **STATUS**: Status flags (validation result, zero flag)
- **TBASE**: Tally table base address register
- **SKEY[0-7]**: Secret key storage (bs, r, s, py, px, by, bx, bf)

## Instruction Summary Table

| Mnemonic   | Opcode | Format  | Description |
|------------|--------|---------|-------------|
| `ADD`      | 0000   | R-type  | Add two registers |
| `SUB`      | 0001   | R-type  | Subtract two registers |
| `AND`      | 0010   | R-type  | Bitwise AND |
| `OR`       | 0011   | R-type  | Bitwise OR |
| `XOR`      | 0100   | R-type  | Bitwise XOR |
| `NOT`      | 0101   | R-type  | Bitwise NOT |
| `LOAD`     | 0110   | I-type  | Load from memory to register |
| `STORE`    | 0111   | I-type  | Store register to memory |
| `LDI`      | 1000   | I-type  | Load immediate value |
| `NEWC`     | 1001   | R-type  | Register candidate ID (initialize tally row) |
| `NEWD`     | 1010   | R-type  | Register district ID (initialize district column) |
| `ADDT`     | 1011   | R-type  | Add `value` votes to `candID` from `distID`, update total |
| `OUTT`     | 1100   | R-type  | Output total tally for `candID` to 7-segment display |
| `SETKEY`   | 1101   | I-type  | Set secret key field for tag generation |
| `TGEN`     | 1110   | R-type  | Generate tag using secret key parameters |
| `TVALID`   | 1111   | R-type  | Validate received tag against generated tag |
| `INSW`     | 0010   | I-type  | Read from switches to register |
| `OUTLED`   | 0011   | I-type  | Output register to LEDs |
| `OUT7SEG`  | 0100   | I-type  | Output register to 7-segment display |
| `CMP`      | 1100   | R-type  | Compare two registers, set STATUS flags |
| `JMP`      | 0110   | J-type  | Unconditional jump |
| `JEQ`      | 0111   | J-type  | Jump if equal (STATUS.Z = 1) |
| `JNE`      | 1000   | J-type  | Jump if not equal |
| `JVAL`     | 1001   | J-type  | Jump if tag validation passed |
| `NOP`      | 1010   | —       | No operation (for hazard handling) |
| `HALT`     | 1011   | —       | Stop processor execution (halts pipeline) |

---

## Instruction Formats

###  R-Type
Used for arithmetic, logic, validation, tallying, and display.
```
[4-bit opcode][4-bit rd][4-bit rs1][4-bit rs2/function]
```

**For ALU instruction (opcode 0000)**: rs2 field encodes function:
- 0000: ADD, 0001: SUB, 0010: AND, 0011: OR, 0100: XOR, 0101: NOT, 0110: SHL (shift left), 0111: SHR (shift right)

###  I-Type
Used for memory access and I/O operations.
```
[4-bit opcode][4-bit rd][8-bit immediate/address]
```

**For IO instruction (opcode 0110)**: immediate field encodes function:
- 00000000: INSW, 00000001: OUTLED, 00000010: OUT7SEG

**For SETKEY instruction (opcode 0101)**: immediate field encodes:
- [3-bit field][5-bit value] where field: 0=bs, 1=r, 2=s, 3=py, 4=px, 5=by, 6=bx, 7=bf

###  J-Type
Used for control flow.
```
[4-bit opcode][12-bit address/condition+address]
```

**For JCOND instruction (opcode 1110)**: address field encodes:
- [2-bit condition][10-bit address] where condition: 00=JEQ, 01=JNE, 10=JVAL

**For SYS instruction (opcode 1111)**: instruction encodes:
- [4-bit opcode][12-bit function] where function: 000000000000=NOP, 000000000001=HALT

---

##  Instruction Details

## Basic ALU Operations

### `ADD rd, rs1, rs2`
- **Opcode**: `0000`
- **Format**: R-type
- **Description**: Adds rs1 and rs2, stores result in rd. Sets zero flag if result is 0.

### `SUB rd, rs1, rs2`
- **Opcode**: `0001`
- **Format**: R-type
- **Description**: Subtracts rs2 from rs1, stores result in rd. Sets zero flag if result is 0.

### `AND rd, rs1, rs2`
- **Opcode**: `0010`
- **Format**: R-type
- **Description**: Performs bitwise AND of rs1 and rs2, stores result in rd.

### `OR rd, rs1, rs2`
- **Opcode**: `0011`
- **Format**: R-type
- **Description**: Performs bitwise OR of rs1 and rs2, stores result in rd.

### `XOR rd, rs1, rs2`
- **Opcode**: `0100`
- **Format**: R-type
- **Description**: Performs bitwise XOR of rs1 and rs2, stores result in rd.

### `NOT rd, rs1`
- **Opcode**: `0101`
- **Format**: R-type
- **Description**: Performs bitwise NOT of rs1, stores result in rd.

### `CMP rs1, rs2`
- **Opcode**: `1100`
- **Format**: R-type
- **Description**: Compares rs1 and rs2, sets STATUS flags (zero flag if equal).

## Memory and Data Operations

### `LOAD rd, addr`
- **Opcode**: `0110`
- **Format**: I-type
- **Description**: Loads data from memory address into register rd. Executed in MEM stage.

### `STORE rs, addr`
- **Opcode**: `0111`
- **Format**: I-type
- **Description**: Stores register rs to memory address. Executed in MEM stage.

### `LDI rd, imm8`
- **Opcode**: `1000`
- **Format**: I-type
- **Description**: Loads 8-bit immediate value into register rd.

## Election-Specific Operations

### `NEWC rd, candID`
- **Opcode**: `1001`
- **Format**: R-type
- **Description**: Initializes a new candidate's tally row. Stores table offset in rd. Executed in WB stage.

### `NEWD rd, distID`
- **Opcode**: `1010`
- **Format**: R-type
- **Description**: Initializes district column for vote tracking. Stores offset in rd. Executed in WB.

### `ADDT distID, candID, value`
- **Opcode**: `1011`
- **Format**: R-type
- **Description**: Adds `value` votes from `distID` to `candID`. Updates district entry and total tally in WB.

### `OUTT candID`
- **Opcode**: `1100`
- **Format**: R-type
- **Description**: Reads and displays total vote tally for a candidate on 7-segment. Output happens in MEM.

## Tag Validation Operations (for Member 3)

### `SETKEY field, value`
- **Opcode**: `1101`
- **Format**: I-type
- **Description**: Sets secret key field to value. Field encoding: 0=bs, 1=r, 2=s, 3=py, 4=px, 5=by, 6=bx, 7=bf. Configures tag generation parameters per assignment Figure 4(c).

### `TGEN rd, rs`
- **Opcode**: `1110`
- **Format**: R-type
- **Description**: Generates tag for record in rs using stored secret key. Performs complete Block Partition → Flip → Swap → Shift → XOR sequence. Stores result in rd and sets validation flag.

### `TVALID rs1, rs2`
- **Opcode**: `1111`
- **Format**: R-type
- **Description**: Compares generated tag (rs1) with received tag (rs2). Sets validation flag in STATUS register if tags match.

## I/O Operations (for FPGA - Member 5)

### `INSW rd`
- **Opcode**: `0010`
- **Format**: I-type
- **Description**: Reads 16-bit value from switches into register rd.

### `OUTLED rs`
- **Opcode**: `0011`
- **Format**: I-type
- **Description**: Outputs register rs to LED array for debugging/status.

### `OUT7SEG rs`
- **Opcode**: `0100`
- **Format**: I-type
- **Description**: Outputs register rs to 7-segment display for vote totals.

## Control Flow Operations

### `JMP addr`
- **Opcode**: `0110`
- **Format**: J-type
- **Description**: Unconditional jump to address. Updates PC in EX stage.

### `JEQ addr`
- **Opcode**: `0111`
- **Format**: J-type
- **Description**: Jump to address if STATUS.Z flag is set (equal comparison result).

### `JNE addr`
- **Opcode**: `1000`
- **Format**: J-type
- **Description**: Jump to address if STATUS.Z flag is clear (not equal).

### `JVAL addr`
- **Opcode**: `1001`
- **Format**: J-type
- **Description**: Jump to address if tag validation flag is set (valid tag).

## System Operations

### `NOP`
- **Opcode**: `1010`
- **Format**: —
- **Description**: No operation. Used to resolve hazards or insert delays.

### `HALT`
- **Opcode**: `1011`
- **Format**: —
- **Description**: Halts processor. Ends simulation or FPGA run.

---

## Programming Example for Tag Validation

```assembly
# Configure secret key for tag validation (from assignment Figure 4c)
SETKEY 0, 1      # Set bs (block select) = 1
SETKEY 1, 10     # Set r (rotate amount) = 10  
SETKEY 2, 10     # Set s (segment size) = 10
SETKEY 3, 1      # Set py (position y) = 1
SETKEY 4, 0      # Set px (position x) = 0
SETKEY 5, 1      # Set by (block y) = 1
SETKEY 6, 1      # Set bx (block x) = 1
SETKEY 7, 1      # Set bf (flip block) = 1

main_loop:
# Load record from switches
IO R1, 0         # Read from switches (INSW)

# Extract district ID (bits 15-14)
LDI R0, 0xC0     # Load mask 0xC000 (upper 8 bits of immediate)
ALU R2, R1, R0, 2    # AND: R2 = R1 & mask
LDI R0, 14       # Shift amount
ALU R2, R2, R0, 7    # SHR: Shift right to get district ID

# Extract candidate ID (bits 13-12)
LDI R0, 0x30     # Load mask 0x3000  
ALU R3, R1, R0, 2    # AND: R3 = R1 & mask
LDI R0, 12       # Shift amount
ALU R3, R3, R0, 7    # SHR: Shift right to get candidate ID

# Extract vote count (bits 11-4)
LDI R0, 0xFF     # Load mask 0x0FF0
ALU R4, R1, R0, 2    # AND: R4 = R1 & mask  
LDI R0, 4        # Shift amount
ALU R4, R4, R0, 7    # SHR: Shift right to get vote count

# Extract received tag (bits 3-0)
LDI R0, 0x0F     # Load mask 0x000F
ALU R5, R1, R0, 2    # AND: R5 = R1 & mask (tag in lower bits)

# Generate tag using configured secret key
TGEN R6, R4      # Generate tag for vote record

# Validate tag
TVALID R6, R5    # Compare generated vs received tag
JCOND 1, invalid_tag  # JNE: Jump if validation fails

# Process valid vote
ADDT R2, R3, R4  # Add votes to tally
OUTT R3          # Display updated total
JMP main_loop    # Continue

invalid_tag:
LDI R0, 0xFF     # Load error pattern
IO R0, 1         # OUTLED: Light all LEDs as error
JMP main_loop    # Continue processing
```

## Implementation Notes for Team Members

### For Member 2 (Datapath Design):
- ALU needs to support: ADD, SUB, AND, OR, XOR, NOT operations
- Register file: 16 general purpose registers, 16-bit wide
- Memory interface for LOAD/STORE operations
- Special registers: PC, STATUS, TBASE, SKEY[0-7] for secret key storage
- Consider dedicated tag generation unit that can be pipelined

### For Member 3 (Tag Validation Logic):
- Implement SETKEY instruction to configure secret key fields (bs, r, s, py, px, by, bx, bf)
- TGEN instruction performs complete tag generation: Block Partition → Flip → Swap → Shift → XOR
- Tag generation could be its own pipeline stage for better performance
- TVALID compares generated vs received tags and sets STATUS validation flag
- Make tag size and block size configurable via secret key parameters

### For Member 4 (Testing):
- Test cases should use basic ALU ops to build complex operations
- Create records with known tags using tag generation sequence
- Test different record sizes by adjusting bit extraction masks

### For Member 5 (FPGA):
- INSW maps to 16 switches on FPGA board
- OUT7SEG drives 7-segment display
- OUTLED drives LED array
- Button inputs can be read via additional I/O instructions if needed