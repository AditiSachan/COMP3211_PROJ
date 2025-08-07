from typing import List, Tuple
from itertools import product

TAG_SIZE = 4  # updated tag size
RECORD_SIZE = 31
BLOCK_SIZE = TAG_SIZE
NUM_BLOCKS = (RECORD_SIZE + TAG_SIZE - 1) // TAG_SIZE  # ceiling division

# Secret key for tag operations
key = {
    'bf': 0,  # block to flip
    'bx': 1,  # block x for swap
    'by': 2,  # block y for swap
    'px': 1,  # start bit pos in bx
    'py': 2,  # start bit pos in by
    's': 2,   # segment length
    'bs': 3,  # block to shift
    'r': 1    # rotate amount
}

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

    # Flip
    blocks[key['bf']] = flip(blocks[key['bf']])

    # Swap
    blocks[key['bx']], blocks[key['by']] = swap(
        blocks[key['bx']], blocks[key['by']],
        key['px'], key['py'], key['s']
    )

    # Shift
    blocks[key['bs']] = shift(blocks[key['bs']], key['r'])

    # XOR all blocks
    return xor_blocks(blocks)

def generate_all_tags(num_districts: int, num_candidates: int):
    tags = {}
    for district_id, candidate_id in product(range(num_districts), range(num_candidates)):
        for tally in range(16):  # 4-bit tally (0–15)
            district_bin = int_to_bin(district_id, 2)
            candidate_bin = int_to_bin(candidate_id, 2)
            tally_bin = int_to_bin(tally, 4)

            # 31-bit record = 2 (district) + 2 (candidate) + 4 (tally) + 23 zeros
            record = district_bin + candidate_bin + tally_bin + '0' * (31 - 8)
            tag = tag_generation(record, key)
            tags[(district_id, candidate_id, tally)] = tag
    return tags

# Generate all tags
tags_result = generate_all_tags(4, 4)

# Save output in the same directory as the script
with open("all_tags_output.txt", "w") as f:
    for k, v in tags_result.items():
        f.write(f"District: {k[0]}, Candidate: {k[1]}, Tally: {k[2]} -> Tag: {v}\n")

print("'all_tags_output.txt' is generated in the current directory.")
