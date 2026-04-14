# This script reads the `instr_info.csv` file, processes the opcode information, 
# and generates 8 ROM `.data` files that can be directly used in the Verilog testbench. 
# Each ROM file contains 32 lines, with each line representing a 4-byte word (8 hex characters) 
# corresponding to 4 opcodes. The script handles both standard and extended opcodes, as well as 
# OSO variants, by mapping them to their respective ROM files based on the provided CSV data.
# At the bottom of this file, you can specify the input CSV filename if needed: 
#       input_filename = "instr_info.csv" #CHANGE IF NEEDED
# The info per byte is in the following format: 
#       bit 7: MRM, bits 6-4: IMM, bits 3-1: SUM Opcode Cnt (1) + IMM_in_bytes + MODRM Cnt (0 or 1), bit 0: FAR.BR (0 or 1)

# To run: <python3 rom_gen.py>

import csv
import os

def rom_gen(input_csv):
    folder_name = "/home/ecelrc/students/kl38888/MICROARCH/project/scripts/decode/rom_data"
    if not os.path.exists(folder_name):
        os.makedirs(folder_name)

    # Phase 1: Initialize maps with "XX" to represent 'X' in Verilog [cite: 375, 376]
    opcode_map_std = ["XX"] * 256
    opcode_map_ext = ["XX"] * 256

    instructions = []
    with open(input_csv, mode='r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if not row or not row.get('Opcode'): continue
            instructions.append(row)

    def parse_row(row, ops):
        # bit 7: MRM, bits 6-4: IMM, bits 3-1: SUM, bit 0: FAR.BR
        mrm = int(float(row.get('MRM', 0) or 0)) & 0x1
        imm = int(float(row.get('IMM', 0) or 0)) & 0x7
        far = int(float(row.get('FAR.BR', 0) or 0)) & 0x1
        sum_val = (mrm + imm + 1) & 0x7
        assembled = (mrm << 7) | (imm << 4) | (sum_val << 1) | far
        return f"{assembled:02X}"

    # Phase 2: Populate Standard/Extended (OSO=0)
    for row in instructions:
        try:
            op_hex = row['OP'].strip() if row.get('OP') else row['Opcode'].strip().split()[0]
            idx = int(op_hex, 16)
            tbop = int(float(row.get('2BOP', 0) or 0))
            oso = int(float(row.get('OSO', 0) or 0))
            if oso == 0:
                if tbop == 0: opcode_map_std[idx] = parse_row(row, op_hex)
                else: opcode_map_ext[idx] = parse_row(row, op_hex)
        except: continue

    # Phase 3: Create OSO maps as COPIES (preserving the "XX" logic)
    opcode_map_oso = list(opcode_map_std)
    opcode_map_ext_oso = list(opcode_map_ext)

    # Phase 4: Overwrite OSO (OSO=1)
    for row in instructions:
        try:
            op_hex = row['OP'].strip() if row.get('OP') else row['Opcode'].strip().split()[0]
            idx = int(op_hex, 16)
            tbop = int(float(row.get('2BOP', 0) or 0))
            oso = int(float(row.get('OSO', 0) or 0))
            if oso == 1:
                if tbop == 0: opcode_map_oso[idx] = parse_row(row, op_hex)
                else: opcode_map_ext_oso[idx] = parse_row(row, op_hex)
        except: continue

    # Phase 5: Writing Helper
    def write_rom_file(filename, data_map, start_idx):
        file_path = os.path.join(folder_name, filename)
        with open(file_path, 'w') as f:
            for i in range(32):
                base_op = start_idx + (i * 4)
                # Word construction b3b2b1b0
                word = "".join([data_map[base_op + j] for j in range(3, -1, -1)])
                ops = [f"{base_op + j:02X}" for j in range(3, -1, -1)]                    
                comment = f"// Address {i:02d}: Opcodes {ops[0]}, {ops[1]}, {ops[2]}, {ops[3]}"
                f.write(f"{word}  {comment}\n")

    write_rom_file("rom_std_lo.data", opcode_map_std, 0)
    write_rom_file("rom_std_hi.data", opcode_map_std, 128)
    write_rom_file("rom_oso_lo.data", opcode_map_oso, 0)
    write_rom_file("rom_oso_hi.data", opcode_map_oso, 128)
    write_rom_file("rom_ext_lo.data", opcode_map_ext, 0)
    write_rom_file("rom_ext_hi.data", opcode_map_ext, 128)
    write_rom_file("rom_ext_oso_lo.data", opcode_map_ext_oso, 0)
    write_rom_file("rom_ext_oso_hi.data", opcode_map_ext_oso, 128)
    print(f"Successfully generated X-padded ROMs in {folder_name}/")

rom_gen("/home/ecelrc/students/kl38888/MICROARCH/project/scripts/decode/instr_info.csv")
