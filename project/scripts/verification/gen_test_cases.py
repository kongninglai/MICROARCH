import re

INPUT_FILE = "/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/program.txt"
OUTPUT_FILE = "/home/ecelrc/students/aak3265/MICROARCH/project/scripts/verification/gen_testcases.mem"


def parse_test_file(filename):
    instructions = []
    current_bytes = []

    with open(filename, "r") as f:
        for line in f:
            line = line.strip()

            if not line or line.startswith("//"):
                continue

            if re.match(r"^0x[0-9a-fA-F]+:", line):
                if current_bytes:
                    instructions.append(current_bytes)
                    current_bytes = []

                parts = line.split("//")[0]
                parts = parts.split(":", 1)[1]
            else:
                parts = line.split("//")[0]

            bytes_found = re.findall(r"\b[0-9a-fA-F]{2}\b", parts)
            current_bytes.extend(bytes_found)

        if current_bytes:
            instructions.append(current_bytes)

    return instructions


def format_instructions(instructions):
    lines = []

    for inst in instructions:
        bytes_list = [int(b, 16) for b in inst]

        if len(bytes_list) > 16:
            raise ValueError("Instruction longer than 16 bytes")

        # Create empty 16B line
        line_bytes = [0] * 16

        # Place bytes so inst[0] goes to line[15], etc.
        for i, b in enumerate(bytes_list):
            line_bytes[15 - i] = b

        line = "".join(f"{b:02X}" for b in line_bytes)
        lines.append(line)

    return lines


def main():
    instructions = parse_test_file(INPUT_FILE)
    lines = format_instructions(instructions)

    with open(OUTPUT_FILE, "w") as f:
        for line in lines:
            f.write(line + "\n")


if __name__ == "__main__":
    main()
