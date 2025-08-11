# Election Processor Instruction Set Architecture (ISA)

## Overview

This document describes the Instruction Set Architecture for the real-time election tallying processor. The processor implements a 16-bit RISC architecture optimized for secure election record processing, validation, and vote tallying operations.

## Instruction Format

### Basic Format
All instructions are 16 bits wide with the following format:

```
15  12 11   8 7    4 3    0
+------+------+------+------+
|opcode|  rs  |  rt  |  rd  |
+------+------+------+------+
```

- **opcode [15:12]**: 4-bit operation code
- **rs [11:8]**: 4-bit source register A
- **rt [7:4]**: 4-bit source register B  
- **rd [3:0]**: 4-bit destination register or immediate/offset

## Register Set

The processor contains 16 general-purpose registers:
- **$0**: Always zero (read-only)
- **$1**: Always ones (read-only) 
- **$2-$15**: General purpose registers (16-bit each)

## Instruction Set

### Data Movement Instructions

#### BUFGET - Buffer Get
**Encoding**: `0001 rs rt rd`  
**Syntax**: `bufget $rs, $rt, $rd`  
**Operation**: Get data from input buffer into registers
- `$rs = buffer_data1` (election record)
- `$rt = buffer_data2` (control/tag data)
- Sets buffer read request signal

#### MEMPUT - Memory Put  
**Encoding**: `0010 rs rt rd`  
**Syntax**: `memput $rs, $rt`  
**Operation**: Store data to output memory
- Writes `$rs` and `$rt` to consecutive memory locations
- Used for sending processed data to network

### Election-Specific Instructions

#### RECGET - Record Get
**Encoding**: `0110 rs rt rd`  
**Syntax**: `recget $rs, $rt, $rd`  
**Operation**: Parse election record fields
- `$rs = tally_data` (8-bit vote count, zero-extended)
- `$rt = tag_data` (4-bit tag, zero-extended)  
- Extracts district_id and candidate_id for internal processing
- **Record Format**: `[district(2)][candidate(2)][tally(8)][tag(4)]`

#### TAGGEN - Tag Generate
**Encoding**: `0111 rs rt rd`  
**Syntax**: `taggen $rs, $rt`  
**Operation**: Generate cryptographic tag from election data
- Input: `$rt` contains election record data
- Output: `$rs = computed_tag` (4-bit tag, zero-extended)
- Uses 5-step algorithm: Partition→Flip→Swap→Shift→XOR
- Secret key embedded in processor (0x003101A0)

#### TAGCHK - Tag Check
**Encoding**: `1000 rs rt rd`  
**Syntax**: `tagchk $rs, $rt`  
**Operation**: Validate received tag against computed tag
- Input: `$rs = received_tag`, `$rt = computed_tag`
- Output: `$rs[0] = 1` if tags match, `0` if mismatch
- Sets internal `tag_valid` signal for tally operations

#### TALLYUPD - Tally Update
**Encoding**: `1001 rs rt rd`  
**Syntax**: `tallyupd $rs, $rt`  
**Operation**: Update vote tally table
- Input: `$rs` contains record with district/candidate IDs
- Input: `$rt` contains vote increment value
- Updates cumulative tally: `tally[district][candidate] += increment`
- Only executes if previous TAGCHK validated successfully

### Control Flow Instructions

#### BEQ - Branch if Equal
**Encoding**: `1010 rs rt offset`  
**Syntax**: `beq $rs, $rt, offset`  
**Operation**: Branch if `$rs == $rt`
- PC = PC + 1 + sign_extend(offset) if condition true
- PC = PC + 1 if condition false

#### BEQZ - Branch if Equal Zero
**Encoding**: `1011 rs rt offset`  
**Syntax**: `beqz $rs, offset`  
**Operation**: Branch if `$rs == 0`
- PC = PC + 1 + sign_extend(offset) if `$rs == 0`
- PC = PC + 1 if `$rs != 0`

#### B - Unconditional Branch
**Encoding**: `1100 xx xx offset`  
**Syntax**: `b offset`  
**Operation**: Unconditional branch
- PC = PC + 1 + sign_extend(offset)

### System Instructions

#### ACKN - Acknowledge
**Encoding**: `0101 rs rt rd`  
**Syntax**: `ackn $rs`  
**Operation**: Send acknowledgment for processed record
- Outputs `$rs` data as acknowledgment signal
- Used to confirm successful record processing

#### NOOP - No Operation
**Encoding**: `0000 xx xx xx`  
**Syntax**: `noop`  
**Operation**: No operation, advance PC only

## Sample Programs

### Election Center Program
```assembly
start:
    recget  $1, $2, $0      # Get record: $1=tally, $2=tag
    beqz    $1, start       # If no data, loop back
    taggen  $3, $1          # Generate tag from tally data  
    tagchk  $2, $3          # Compare received vs computed tag
    beqz    $0, drop        # If tags don't match, drop record
    tallyupd $1, $2         # Update tally table
    ackn    $1              # Send acknowledgment
    b       start           # Loop back
drop:
    noop                    # Could log error here
    b       start           # Continue processing
```

### District Program  
```assembly
start:
    bufget  $3, $2, $0      # Get data from local buffer
    beqz    $3, start       # If no data, wait
    taggen  $4, $3          # Generate authentication tag
    memput  $3, $4          # Send record + tag to network
    b       start           # Loop back
```

## Security Features

### Tag Generation Algorithm
The TAGGEN instruction implements a 5-step cryptographic process:

1. **Block Partition**: Split 31-bit record into 4-bit blocks (zero-padded)
2. **Flip**: Invert all bits in selected blocks (controlled by secret key)
3. **Swap**: Exchange bit segments between two blocks 
4. **Shift**: Rotate-left shift bits in selected block
5. **XOR**: XOR all blocks to produce 4-bit tag

### Secret Key Format (32-bit)
```
31  29 28  26 25  23 22 21 20 19 18 17 16 15 14 13  11 10   8 7    0
+-----+-----+-----+----+----+----+----+----+----+-----+-----+------+
| bf  | by  | bx  | py | px | s  | r  | bs |  unused    | unused |
+-----+-----+-----+----+----+----+----+----+----+-----+-----+------+
```

- **bf**: Block flip mask (3 bits) 
- **by, bx**: Swap block indices (3 bits each)
- **py, px**: Swap positions (2 bits each)
- **s**: Swap segment size (2 bits)
- **r**: Shift amount (2 bits)
- **bs**: Shift block select (3 bits)

## Pipeline Considerations

The processor implements a 5-stage pipeline:
1. **IF**: Instruction Fetch
2. **ID**: Instruction Decode  
3. **EX**: Execute/ALU operations
4. **MEM**: Memory/Tally table access
5. **WB**: Write Back

### Hazards
- **Data hazards**: Handled by forwarding unit
- **Control hazards**: Branch prediction with stall on branch instructions
- **Structural hazards**: Dual-write capability for BUFGET operations

## Error Handling

- **Invalid tags**: Records dropped, processing continues
- **Invalid register access**: $0 and $1 are read-only
- **Buffer underflow**: BUFGET returns zero data
- **Tally overflow**: 8-bit counters with saturation logic

## Performance Characteristics

- **Clock frequency**: Target 100 MHz
- **Throughput**: 1 instruction per cycle (ideal pipeline)
- **Tag generation latency**: 1 cycle (combinational)
- **Tally update latency**: 1 cycle
- **Record processing**: ~6-8 cycles per election record