#!/usr/bin/env python3
import argparse
import re
from pathlib import Path

INPUT_FILE="/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/program.txt"
OUTPUT_FILE="/home/ecelrc/students/aak3265/MICROARCH/project/scripts/verification/program_eip_idx_map.txt"

# Match lines like:
# 0x214:  f3 a7  // repz cmps DWORD PTR ds:[esi],DWORD PTR es:[edi]
#
# Default behavior: only count "instruction lines" that contain "//"
INSTR_LINE_RE = re.compile(
    r'^\s*(0x[0-9a-fA-F]+)\s*:\s*([0-9a-fA-F]{2}(?:\s+[0-9a-fA-F]{2})*)\s*(//.*)?\s*$'
)


def parse_mapping(lines, include_data_lines=False):
    """
    Returns a list of (eip_int, idx, original_line).
    idx is the testcase line number among selected lines only.
    """
    mapping = []
    idx = 0

    for raw in lines:
        line = raw.strip()
        if not line:
            continue

        m = INSTR_LINE_RE.match(line)
        if not m:
            continue

        eip_str, byte_str, comment = m.groups()

        # By default, only keep instruction lines that have a trailing comment.
        # This skips raw data dump lines like:
        #   0x2000: 52 5d 2f 59 ...
        if not include_data_lines and comment is None:
            continue

        eip = int(eip_str, 16)
        mapping.append((eip, idx, raw.rstrip("\n")))
        idx += 1

    return mapping


def write_text_mapping(mapping, out_path: Path):
    """
    Output format:
    0x00000000 0
    0x00000005 1
    ...
    """
    with out_path.open("w", encoding="utf-8") as f:
        for eip, idx, _ in mapping:
            f.write(f"0x{eip:08x} {idx}\n")


def write_csv_mapping(mapping, out_path: Path):
    with out_path.open("w", encoding="utf-8") as f:
        f.write("eip_hex,idx\n")
        for eip, idx, _ in mapping:
            f.write(f"0x{eip:08x},{idx}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Generate eip->idx mapping from an instruction test file."
    )
    
    parser.add_argument(
        "--csv",
        action="store_true",
        help="Write CSV instead of plain text",
    )
    parser.add_argument(
        "--include-data-lines",
        action="store_true",
        help="Also include address lines without // comments",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print parsed mappings to stdout",
    )

    args = parser.parse_args()

    in_path = Path(INPUT_FILE)
    out_path = Path(OUTPUT_FILE)

    if not in_path.exists():
        raise FileNotFoundError(f"Input file not found: {in_path}")

    with in_path.open("r", encoding="utf-8") as f:
        mapping = parse_mapping(f.readlines(), include_data_lines=args.include_data_lines)

    if args.csv:
        write_csv_mapping(mapping, out_path)
    else:
        write_text_mapping(mapping, out_path)

    if args.verbose:
        for eip, idx, line in mapping:
            print(f"idx={idx:4d}  eip=0x{eip:08x}  line={line}")



if __name__ == "__main__":
    main()