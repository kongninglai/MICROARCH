import csv

def process_opcodes(input_csv):
    # Initialize 4 distinct maps for the 256 opcodes
    opcode_map_std     = ["00"] * 256
    opcode_map_oso     = ["00"] * 256
    opcode_map_ext     = ["00"] * 256
    opcode_map_ext_oso = ["00"] * 256

    with open(input_csv, mode='r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        
        for row_num, row in enumerate(reader, start=2):
            if not row or not row.get('Opcode') or row['Opcode'].strip() == '':
                continue
                
            try:
                # Determine the exact hex opcode index.
                if 'OP' in row and row['OP'].strip():
                    op_hex = row['OP'].strip()
                else:
                    op_hex = row['Opcode'].strip().split()[0]
                    
                opcode_idx = int(op_hex, 16)
                
                # Extract values (Fixed copy-paste errors here)
                tbop_str   = row.get('2BOP', '0').strip() if row.get('2BOP') else '0'
                oso_str    = row.get('OSO', '0').strip() if row.get('OSO') else '0'
                mrm_str    = row.get('MRM', '0').strip() if row.get('MRM') else '0'
                imm_str    = row.get('IMM', '0').strip() if row.get('IMM') else '0'
                far_br_str = row.get('FAR.BR', '0').strip() if row.get('FAR.BR') else '0'
                
                # Clean strings to integers
                tbop   = int(float(tbop_str))   if tbop_str.replace('.','',1).isdigit() else 0
                oso    = int(float(oso_str))    if oso_str.replace('.','',1).isdigit() else 0
                mrm    = int(float(mrm_str))    if mrm_str.replace('.','',1).isdigit() else 0
                imm    = int(float(imm_str))    if imm_str.replace('.','',1).isdigit() else 0
                far_br = int(float(far_br_str)) if far_br_str.replace('.','',1).isdigit() else 0
                
                # Mask values
                tbop   = tbop & 0x1       # 1 bit
                oso    = oso & 0x1        # 1 bit
                mrm    = mrm & 0x1        # 1 bit
                imm    = imm & 0x7        # 3 bits
                far_br = far_br & 0x1     # 1 bit
                
                # Compute MRM + IMM
                sum_mrm_imm_std = (mrm + imm + 1) & 0x7     # always add 1 to represent opcode
                sum_mrm_imm_ifext = (mrm + imm + 2) & 0x7   # always add 2 to represent extended opcode
                
                # Assemble the byte
                assembled_byte_std = (mrm << 7) | (imm << 4) | (sum_mrm_imm_std << 1) | far_br
                assembled_byte_ifext = (mrm << 7) | (imm << 4) | (sum_mrm_imm_ifext << 1) | far_br

                # Format as a 2-character uppercase Hex string
                hex_byte_std = f"{assembled_byte_std:02X}"
                hex_byte_ifext = f"{assembled_byte_ifext:02X}"
                
                # Map it to the exact index (Fixed "else if" syntax here)
                if oso == 0x0:
                    if tbop == 0x0: 
                        opcode_map_std[opcode_idx] = hex_byte_std
                    else: 
                        opcode_map_ext[opcode_idx] = hex_byte_ifext
                elif oso == 0x1:
                    if tbop == 0x0: 
                        opcode_map_oso[opcode_idx] = hex_byte_std
                    else: 
                        opcode_map_ext_oso[opcode_idx] = hex_byte_ifext
                
            except Exception as e:
                # Ignore rows that fail parsing
                continue

    # Helper function to write exactly 32 lines (128 opcodes) to a specific ROM file
    def write_rom_file(filename, data_map, start_idx):
        with open(filename, 'w') as f:
            for i in range(32):  # 32 lines
                # Calculate the exact opcode index based on which half (LO or HI) we are in
                base_op = start_idx + (i * 4)
                
                b0 = data_map[base_op + 0]
                b1 = data_map[base_op + 1]
                b2 = data_map[base_op + 2]
                b3 = data_map[base_op + 3]
                
                # Combine bytes (Highest index on the left, lowest on the right)
                word_hex = f"{b3}{b2}{b1}{b0}"
                
                # Add comments so you can still read them easily (Verilog ignores them)
                comment = f"// Address {i:02d} (Opcodes {base_op+3:02X}, {base_op+2:02X}, {base_op+1:02X}, {base_op+0:02X})"
                f.write(f"{word_hex}  {comment}\n")

    # Write the 8 files needed by Verilog
    # LO files cover opcodes 0x00 to 0x7F (Start index 0)
    # HI files cover opcodes 0x80 to 0xFF (Start index 128)
    write_rom_file("rom_std_lo.data", opcode_map_std, 0)
    write_rom_file("rom_std_hi.data", opcode_map_std, 128)
    
    write_rom_file("rom_oso_lo.data", opcode_map_oso, 0)
    write_rom_file("rom_oso_hi.data", opcode_map_oso, 128)
    
    write_rom_file("rom_ext_lo.data", opcode_map_ext, 0)
    write_rom_file("rom_ext_hi.data", opcode_map_ext, 128)
    
    write_rom_file("rom_ext_oso_lo.data", opcode_map_ext_oso, 0)
    write_rom_file("rom_ext_oso_hi.data", opcode_map_ext_oso, 128)

    print("Successfully assembled 8 ROM `.data` files (32 words each)!")

# --- Run the script ---
input_filename = "instr_info.csv"
process_opcodes(input_filename)