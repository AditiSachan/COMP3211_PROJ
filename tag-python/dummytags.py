from typing import List, Tuple
from itertools import product

# Constants
TAG_SIZE = 4
RECORD_SIZE = 31
BLOCK_SIZE = TAG_SIZE
NUM_BLOCKS = (RECORD_SIZE + TAG_SIZE - 1) // TAG_SIZE  # ceiling division

# Secret key used for tag generation
key = {
    'bf': 0,
    'bx': 1,
    'by': 2,
    'px': 1,
    'py': 2,
    's': 2,
    'bs': 3,
    'r': 1
}

# Utility functions
def int_to_bin(value: int, bits: int) -> str:
    return format(value, f'0{bits}b')

def flip(block: str) -> str:
    return ''.join('1' if b == '0' else '0' for b in block)

def swap(bx: str, by: str, px: int, py: int, s: int) -> Tuple[str, str]:
    def rotate_index(pos, s, length):
        return [(pos + i) % length for i in range(s)]
    idx_x = rotate_index(px, s, len(bx))
    idx_y = rotate_index(py, s, len(by))
    bx_list, by_list = list(bx), list(by)
    for i in range(s):
        bx_list[idx_x[i]], by_list[idx_y[i]] = by_list[idx_y[i]], bx_list[idx_x[i]]
    return ''.join(bx_list), ''.join(by_list)

def shift(block: str, r: int) -> str:
    r = r % len(block)
    return block[r:] + block[:r]

def xor_blocks(blocks: List[str]) -> str:
    result = int(blocks[0], 2)
    for b in blocks[1:]:
        result ^= int(b, 2)
    return int_to_bin(result, TAG_SIZE)

def tag_generation(record: str, key: dict) -> str:
    padded = record.ljust(BLOCK_SIZE * NUM_BLOCKS, '0')
    blocks = [padded[i * BLOCK_SIZE:(i + 1) * BLOCK_SIZE] for i in range(NUM_BLOCKS)]
    blocks[key['bf']] = flip(blocks[key['bf']])
    blocks[key['bx']], blocks[key['by']] = swap(
        blocks[key['bx']], blocks[key['by']],
        key['px'], key['py'], key['s']
    )
    blocks[key['bs']] = shift(blocks[key['bs']], key['r'])
    return xor_blocks(blocks)

def generate_all_tags(num_districts: int, num_candidates: int):
    tags = {}
    for district_id, candidate_id in product(range(num_districts), range(num_candidates)):
        for tally in range(256):  # 8-bit tally
            district_bin = int_to_bin(district_id, 2)
            candidate_bin = int_to_bin(candidate_id, 2)
            tally_bin = int_to_bin(tally, 8)
            record = district_bin + candidate_bin + tally_bin + '0' * (31 - 12)
            tag = tag_generation(record, key)
            tags[(district_id, candidate_id, tally)] = tag
    return tags

def encode_16bit_input(tag_str: str, tally: int, candidate: int, district: int) -> str:
    tag = int(tag_str, 2)
    encoded = (tag << 12) | (tally << 4) | (candidate << 2) | district
    return int_to_bin(encoded, 16)

# Generate and write output
tags_result = generate_all_tags(4, 4)

with open("all_tags_output.txt", "w") as f:
    for (district, candidate, tally), tag_str in tags_result.items():
        input_16bit = encode_16bit_input(tag_str, tally, candidate, district)
        f.write(f"input->{input_16bit}: district: {district}, candidate: {candidate}, tally: {tally}, tag: {tag_str}\n")

print("'all_tags_output.txt' generated with formatted 16-bit inputs and tags.")
