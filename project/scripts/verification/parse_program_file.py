import re


def parse_program_file(filename):
    test_prog = []

    current_addr = None
    current_bytes = []

    with open(filename, "r") as f:
        for line in f:
            # Remove comments
            line = line.split("//")[0].strip()
            if not line:
                continue

            # Check if line starts a new address block
            addr_match = re.match(r"0x([0-9a-fA-F]+):", line)
            if addr_match:
                # Save previous block if exists
                if current_addr is not None:
                    test_prog.append((current_addr, current_bytes))

                # Start new block
                current_addr = int(addr_match.group(1), 16)
                current_bytes = []

                # Remove "0x...:" part
                line = line.split(":", 1)[1].strip()

            # Extract hex bytes (matches "ba", "0a", etc.)
            bytes_found = re.findall(r"\b[0-9a-fA-F]{2}\b", line)
            current_bytes.extend(int(b, 16) for b in bytes_found)

        # Append last block
        if current_addr is not None:
            test_prog.append((current_addr, current_bytes))

    return test_prog


# # Example usage
# prog = parse_program_file("program.txt")

# for addr, bytes_ in prog:
#     print(f"(0x{addr:x}, {[hex(b) for b in bytes_]})")
