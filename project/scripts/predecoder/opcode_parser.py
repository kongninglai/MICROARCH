# This script extracts modrm and immediate information from a csv file input and concatenates
# that information into a byte for each row of the table. 
import csv

def process_opcodes(input_csv, output_txt, output_txt2, output_txt3, output_txt4):
    opcode_map_std = ["00"] * 256 # default value for empty/unmapped opcodes)
    opcode_map_oso = ["00"] * 256 # default value for empty/unmapped opcodes)
    opcode_map_ext = ["00"] * 256 # default value for empty/unmapped opcodes)
    opcode_map_ext_oso = ["00"] * 256 # default value for empty/unmapped opcodes)


    with open(input_csv, mode='r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        
        for row_num, row in enumerate(reader, start=2):
            if not row or not row.get('Opcode') or row['Opcode'].strip() == '':
                continue
                
            try:
                # Determine the exact hex opcode index.
                # If your CSV has the 'OP' column (which holds the exact byte like "81"), use it.
                # Otherwise, grab the first hex word from the 'Opcode' column (e.g., "04 ib" -> "04")
                if 'OP' in row and row['OP'].strip():
                    op_hex = row['OP'].strip()
                else:
                    op_hex = row['Opcode'].strip().split()[0]
                    
                opcode_idx = int(op_hex, 16)
                
                # extract values
                tbop_str = row.get('2BOP', '0').strip() if row.get('OSO') else '0'
                oso_str = row.get('OSO', '0').strip() if row.get('OSO') else '0'
                mrm_str = row.get('MRM', '0').strip() if row.get('MRM') else '0'
                imm_str = row.get('IMM', '0').strip() if row.get('IMM') else '0'
                far_br_str = row.get('FAR.BR', '0').strip() if row.get('FAR.BR') else '0'
                
                tbop = int(float(tbop_str)) if mrm_str.replace('.','',1).isdigit() else 0
                oso = int(float(oso_str)) if mrm_str.replace('.','',1).isdigit() else 0
                mrm = int(float(mrm_str)) if mrm_str.replace('.','',1).isdigit() else 0
                imm = int(float(imm_str)) if imm_str.replace('.','',1).isdigit() else 0
                far_br = int(float(far_br_str)) if far_br_str.replace('.','',1).isdigit() else 0
                
                #mask values
                tbop = tbop & 0x1     # 1 bit
                oso = oso & 0x1       # 1 bit
                mrm = mrm & 0x1       # 1 bit
                imm = imm & 0x7       # 3 bits
                far_br = far_br & 0x1 # 1 bit
                
                # 2. Compute MRM + IMM
                sum_mrm_imm_std = (mrm + imm + 1) & 0x7 # 3 bits (always add 1 to represent opcode)
                sum_mrm_imm_ifext = (mrm + imm + 2) & 0x7 #always add 2 to represent extended opcode
                
                # 3. Assemble the byte
                assembled_byte_std = (mrm << 7) | (imm << 4) | (sum_mrm_imm_std << 1) | far_br
                assembled_byte_ifext = (mrm << 7) | (imm << 4) | (sum_mrm_imm_ifext << 1) | far_br

                # Format as a 2-character uppercase Hex string
                hex_byte_std = f"{assembled_byte_std:02X}"
                hex_byte_ifext = f"{assembled_byte_ifext:02X}"
                
                # Map it to the exact index (if there are duplicate entries, the last one overwrites)
                if oso == 0x0:
                    if tbop == 0x0: #one bit opcode
                        opcode_map_std[opcode_idx] = hex_byte_std
                    else: #two bit opcode
                        opcode_map_ext[opcode_idx] = hex_byte_ifext

                else if oso == 0x1:
                    if tbop == 0x0: #one bit opcode
                        opcode_map_oso[opcode_idx] = hex_byte_std
                    else: #two bit opcode
                        opcode_map_ext_oso[opcode_idx] = hex_byte_ifext
                
            except Exception as e:
                # Ignore rows that fail parsing (e.g., headers or malformed text)
                continue

    # 4. Group into 32-bit (4-byte) chunks and write to output file
    with open(output_txt, 'w') as f:
        for i in range(64):  # 64 lines * 4 bytes = 256 bytes total
            op0 = i * 4 + 0
            op1 = i * 4 + 1
            op2 = i * 4 + 2
            op3 = i * 4 + 3
            
            b0 = opcode_map[op0]
            b1 = opcode_map[op1]
            b2 = opcode_map[op2]
            b3 = opcode_map[op3]
            
            # Combine bytes (Highest index on the left, lowest on the right)
            word_hex = f"{b3}{b2}{b1}{b0}"
            
            # Format comment exactly as requested
            comment = f"// Address {i} (Contains opcodes {op3:02X}, {op2:02X}, {op1:02X}, {op0:02X})"
            f.write(f"{word_hex}  {comment}\n")
            
    with open(output_txt2, 'w') as f:
        for i in range(64):  # 64 lines * 4 bytes = 256 bytes total
            op0 = i * 4 + 0
            op1 = i * 4 + 1
            op2 = i * 4 + 2
            op3 = i * 4 + 3
            
            b0 = opcode_map[op0]
            b1 = opcode_map[op1]
            b2 = opcode_map[op2]
            b3 = opcode_map[op3]
            
            # Combine bytes (Highest index on the left, lowest on the right)
            word_hex = f"{b3}{b2}{b1}{b0}"

            f.write(f"{word_hex}\n")
            
    print("Successfully mapped 256 opcodes into 32-bit ROM words.")
    print(f"Results saved to {output_txt}")
    print(f"Results saved to {output_txt2}")

# --- Run the script ---
input_filename = "instr_info.csv"
output_filename = "std.txt"
output_filename2 = "std_nc.txt"
output_filename3 = "oso.txt"
output_filename4 = "oso_nc.txt"

process_opcodes(input_filename, output_filename, output_filename2, output_filename3, output_filename4)