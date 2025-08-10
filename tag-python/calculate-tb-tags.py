# five_tests_fixed.py
from typing import List, Tuple

TAG_SIZE = 4
RECORD_SIZE = 31
NUM_BLOCKS = (RECORD_SIZE + TAG_SIZE - 1) // TAG_SIZE  # 8
KEY_32 = 0x32110000  # MSB→LSB layout: [bf|by|bx|py|px|s|r|bs]

def int_to_bin(x: int, bits: int) -> str:
    return format(x & ((1 << bits) - 1), f"0{bits}b")

def decode_key(k: int):
    bf = (k >> 29) & 0x7
    by = (k >> 26) & 0x7
    bx = (k >> 23) & 0x7
    py = (k >> 21) & 0x3
    px = (k >> 19) & 0x3
    s  = (k >> 17) & 0x3
    r  = (k >> 15) & 0x3
    bs = (k >> 12) & 0x7
    s = (s % TAG_SIZE) or TAG_SIZE  # 0 ⇒ full block
    return {"bf":bf%NUM_BLOCKS, "by":by%NUM_BLOCKS, "bx":bx%NUM_BLOCKS,
            "py":py%TAG_SIZE,   "px":px%TAG_SIZE,   "s":s,
            "r": r%TAG_SIZE,    "bs":bs%NUM_BLOCKS}

def build_blocks(rec_bits: str) -> List[str]:
    # Left-pad to 32; A0 is rightmost 4 bits
    padded = rec_bits.rjust(NUM_BLOCKS * TAG_SIZE, '0')
    L = len(padded)
    return [padded[L-(i+1)*TAG_SIZE : L-i*TAG_SIZE] for i in range(NUM_BLOCKS)]

def flip(block: str) -> str:
    return ''.join('1' if b == '0' else '0' for b in block)

def swap(bx: str, by: str, px: int, py: int, s: int) -> Tuple[str, str]:
    n = len(bx)
    def lsb_to_idx(p): return n - 1 - (p % n)  # LSB-based → string idx
    ix = [lsb_to_idx(px + i) for i in range(s)]
    iy = [lsb_to_idx(py + i) for i in range(s)]
    bx_list, by_list = list(bx), list(by)
    for i in range(s):
        bx_list[ix[i]], by_list[iy[i]] = by_list[iy[i]], bx_list[ix[i]]
    return ''.join(bx_list), ''.join(by_list)

def rotl(block: str, r: int) -> str:
    n = len(block); r %= n
    return block[r:] + block[:r]

def xor_blocks(blocks: List[str]) -> str:
    acc = 0
    for b in blocks: acc ^= int(b, 2)
    return int_to_bin(acc, TAG_SIZE)

def tag_generation(rec_bits: str, key32: int) -> str:
    k = decode_key(key32)
    blocks = build_blocks(rec_bits)          # blocks[0] = A0 (rightmost)
    blocks[k["bf"]] = flip(blocks[k["bf"]])  # Flip
    if k["bx"] != k["by"]:                   # <<< key fix: skip swap if same block
        blocks[k["bx"]], blocks[k["by"]] = swap(
            blocks[k["bx"]], blocks[k["by"]], k["px"], k["py"], k["s"]
        )
    blocks[k["bs"]] = rotl(blocks[k["bs"]], k["r"])  # Shift (rotate-left)
    return xor_blocks(blocks)

def encode_16(tag_bits: str, tally: int, cand: int, dist: int) -> str:
    val = (int(tag_bits, 2) << 12) | ((tally & 0xFF) << 4) | ((cand & 0x3) << 2) | (dist & 0x3)
    return int_to_bin(val, 16)

if __name__ == "__main__":
    tests = [0x0000000, 0x1234567, 0x0000001, 0x5A5A5A5, 0x7FFFFFF]
    for x in tests:
        rec_bits = int_to_bin(x, RECORD_SIZE)
        low12 = x & 0xFFF
        dist  =  low12        & 0x3
        cand  = (low12 >> 2)  & 0x3
        tally = (low12 >> 4)  & 0xFF
        tag   = tag_generation(rec_bits, KEY_32)
        print(f"input->{encode_16(tag, tally, cand, dist)}: "
              f"district: {dist}, candidate: {cand}, tally: {tally}, tag: {tag}")
