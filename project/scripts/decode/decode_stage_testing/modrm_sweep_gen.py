# gen_modrm_tests.py

def generate_modrm_sweep():
    opcode = 0x01  # ADD r/m32, r32

    with open("modrm_tests.hex", "w") as f:
        # Loop through all 256 ModR/M combinations
        for mod in range(4):
            for reg in range(8):
                for rm in range(8):
                    modrm = (mod << 6) | (reg << 3) | rm
                    
                    # 1. Calculate Expected Length based on x86 rules
                    expected_length = 2  # 1 byte Opcode + 1 byte ModR/M
                    has_sib = False

                    # Check for SIB byte presence
                    if mod != 3 and rm == 4:
                        has_sib = True
                        expected_length += 1
                        
                    # Check for Displacements
                    if mod == 1:
                        expected_length += 1  # 8-bit disp
                    elif mod == 2:
                        expected_length += 4  # 32-bit disp
                    elif mod == 0 and rm == 5:
                        expected_length += 4  # disp32 only (direct memory address)
                        
                    # NOTE: If SIB is present, SIB Base == 5 & Mod == 0 also adds a 32-bit disp. 
                    # For this sweep, we will hardcode the SIB byte to 0x00 (Base 0, Index 0) to keep it simple.
                    
                    # 2. Construct the bytes for the cache line
                    cache_bytes = [opcode, modrm]
                    
                    if has_sib:
                        cache_bytes.append(0x00) # Dummy SIB byte
                        
                    # Pad the rest of the instruction length with dummy displacement data (e.g., 0xAA)
                    while len(cache_bytes) < expected_length:
                        cache_bytes.append(0xAA)
                        
                    # Pad the cache line up to 16 bytes (128 bits) with 0x00
                    while len(cache_bytes) < 16:
                        cache_bytes.append(0x00)
                        
                    # 3. Format string: Expected_Len Expected_Opcode Expected_ModRM B0 B1 B2 ... B15
                    # Everything is written in HEX format for Verilog to easily read
                    byte_str = " ".join([f"{b:02X}" for b in cache_bytes])
                    line = f"{expected_length:X} {opcode:02X} {modrm:02X} {byte_str}\n"
                    
                    f.write(line)

    print("Successfully generated modrm_tests.hex with 256 test cases!")

if __name__ == "__main__":
    generate_modrm_sweep()