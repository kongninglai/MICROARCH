# This script extracts modrm and immediate information from a csv file input and concatenates
# that information into a byte for each row of the table. 
import csv

def process_opcodes(input_csv, output_txt, output_txt2):
    # Initialize an array of 256 bytes with "00" (default value for empty/unmapped opcodes)
    opcode_map = ["00"] * 256
    
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
                
                # 1. Extract and clean the signals safely
                mrm_str = row.get('MRM', '0').strip() if row.get('MRM') else '0'
                imm_str = row.get('IMM', '0').strip() if row.get('IMM') else '0'
                far_br_str = row.get('FAR.BR', '0').strip() if row.get('FAR.BR') else '0'
                
                mrm = int(float(mrm_str)) if mrm_str.replace('.','',1).isdigit() else 0
                imm = int(float(imm_str)) if imm_str.replace('.','',1).isdigit() else 0
                far_br = int(float(far_br_str)) if far_br_str.replace('.','',1).isdigit() else 0
                
                # Ensure bits are within expected ranges
                mrm = mrm & 0x1       # 1 bit
                imm = imm & 0x7       # 3 bits
                far_br = far_br & 0x1 # 1 bit
                
                # 2. Compute MRM + IMM
                sum_mrm_imm = (mrm + imm) & 0x7 # 3 bits
                
                # 3. Assemble the byte
                assembled_byte = (mrm << 7) | (imm << 4) | (sum_mrm_imm << 1) | far_br
                
                # Format as a 2-character uppercase Hex string
                hex_byte = f"{assembled_byte:02X}"
                
                # Map it to the exact index (if there are duplicate entries, the last one overwrites)
                opcode_map[opcode_idx] = hex_byte
                
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
output_filename = "assembled_bytes.txt"
output_filename2 = "assembled_bytes_nc.txt"

process_opcodes(input_filename, output_filename, output_filename2)