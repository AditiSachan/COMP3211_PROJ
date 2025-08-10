# README — Using `tag.vhd` (Election Tag Generator)

This module computes the authentication **tag** for a 31-bit tally record using a **secret key**. It implements the spec’s pipeline:

**Partition → Flip → Swap → Shift (rotate-left) → XOR.**

---

## Module interface

```vhdl
entity tag is
  generic(
    tag_size  : integer := 4;    -- tag width T (nibble blocks)
    bit_size  : integer := 31;   -- record width
    key_width : integer := 32    -- secret key width
  );
  port(
    incoming_bits : in  std_logic_vector(bit_size-1 downto 0);
    secret_key    : in  std_logic_vector(key_width-1 downto 0);
    output_tag    : out std_logic_vector(tag_size-1 downto 0)
  );
end tag;
```

### Record format (`incoming_bits`)
31 bits, MSB→LSB:
```
[ 19-bit MSB padding | Tally (8) | Candidate (2) | District (2) ]
                          bits 11..4     3..2           1..0
```
- The **upper 19 bits** are part of the tag computation (can be zero or any pattern).
- Internally the record is split into 4-bit blocks **A7 … A0**, where **A0 is the rightmost (LSB) block**.

### Secret key format (`secret_key`)
Top 20 bits are used, MSB→LSB:
```
[ bf(3) | by(3) | bx(3) | py(2) | px(2) | s(2) | r(2) | bs(3) ]  (then 12 LSBs unused)
```
- **bf**: which block to **Flip** (0..7)
- **bx, by**: blocks used by **Swap**
- **px, py**: LSB-based start bit positions inside a block (0..3)
- **s**: segment length for Swap (0 ⇒ full block = 4 bits)
- **bs**: which block to **Shift**
- **r**: rotate-left amount (0..3)

> Example key (used in our TB): `0x32110000`.  
> This decodes to: `bf=1, by=4, bx=4, py=0, px=2, s=0→4, r=2, bs=0`.

---

## How it works (one line each)

- **Partition**: left-pad to a multiple of 4; map into A7..A0 with **A0 = bits[3:0]**.  
- **Flip**: invert all bits in block **bf**.  
- **Swap**: swap `s` bits between blocks **bx** and **by**, starting at LSB positions **px**/**py** (wrapping within the block). If **bx==by**, this is a **no-op**.  
- **Shift**: rotate-left block **bs** by **r** bits.  
- **XOR**: XOR all 8 blocks to produce `output_tag` (4 bits when `tag_size=4`).