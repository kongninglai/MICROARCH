# gen_pillar1_tests.py

def generate_pillar1_tests():
    with open("pillar1_tests.hex", "w") as f:
        
        def emit_test(prefixes, opcode, modrm=None, sib=None, disp=[], imm=[]):
            # 1. Calculate Expected Lengths and Flags
            exp_len = len(prefixes) + len(opcode) + (1 if modrm is not None else 0) + \
                      (1 if sib is not None else 0) + len(disp) + len(imm)
            
            exp_opsize = 1 if 0x66 in prefixes else 0
            exp_rep = 1 if (0xF3 in prefixes or 0xF2 in prefixes) else 0
            exp_ext = 1 if 0x0F in prefixes else 0 # NEW: 0x0F is treated as a prefix!
            
            exp_opcode = opcode[0]
            exp_modrm_v = 1 if modrm is not None else 0
            exp_modrm = modrm if modrm is not None else 0
            exp_sib = sib if sib is not None else 0

            # 2. Build the physical byte stream
            cache_bytes = prefixes + opcode
            if modrm is not None: cache_bytes.append(modrm)
            if sib is not None: cache_bytes.append(sib)
            cache_bytes.extend(disp)
            cache_bytes.extend(imm)

            while len(cache_bytes) < 16:
                cache_bytes.append(0x00)

            # 3. Format string (Now 24 columns: 8 flags + 16 bytes)
            fields = [exp_len, exp_opsize, exp_rep, exp_ext, exp_opcode, exp_modrm_v, exp_modrm, exp_sib] + cache_bytes[:16]
            line = " ".join([f"{val:02X}" for val in fields]) + "\n"
            f.write(line)

        # =================================================================
        # PART 1: PREFIX COMBINATIONS (Customized for your processor)
        # =================================================================
        # No prefix (ADD eax, ecx)
        emit_test(prefixes=[], opcode=[0x01], modrm=0xC8)
        # 1 Prefix: Operand Size
        emit_test(prefixes=[0x66], opcode=[0x01], modrm=0xC8)
        # 1 Prefix: REP
        emit_test(prefixes=[0xF3], opcode=[0xA4]) 
        # 1 Prefix: Segment Override (DS)
        emit_test(prefixes=[0x3E], opcode=[0x01], modrm=0xC8)
        
        # EXTENDED OPCODES (0x0F as prefix)
        # 0x0F + Opcode 0x85 (JNE rel16/32)
        emit_test(prefixes=[0x0F], opcode=[0x85], imm=[0x11, 0x22, 0x33, 0x44])
        # 0x66 + 0x0F + Opcode 0x85 (JNE rel16)
        emit_test(prefixes=[0x66, 0x0F], opcode=[0x85], imm=[0x11, 0x22])

        # THE MAXIMUM COMBO FOR YOUR CPU: REP + SEG + OPSIZE + EXTENDED
        emit_test(prefixes=[0xF3, 0x3E, 0x66, 0x0F], opcode=[0x85], imm=[0x11, 0x22])

        # =================================================================
        # PART 2: MOD R/M SWEEP (All 256 combinations)
        # =================================================================
        for mod in range(4):
            for reg in range(8):
                for rm in range(8):
                    has_sib = (mod != 3 and rm == 4)
                    sib_byte = 0x20 if has_sib else None 
                    disp_bytes = []
                    
                    if mod == 1: disp_bytes = [0xAA] 
                    elif mod == 2: disp_bytes = [0xAA, 0xBB, 0xCC, 0xDD] 
                    elif mod == 0 and rm == 5: disp_bytes = [0xAA, 0xBB, 0xCC, 0xDD] 

                    emit_test(prefixes=[], opcode=[0x01], modrm=(mod<<6)|(reg<<3)|rm, 
                              sib=sib_byte, disp=disp_bytes)

        # =================================================================
        # PART 3: SIB SWEEP (When R/M = 100)
        # =================================================================
        mod = 0
        rm = 4
        for scale in range(4):
            for index in range(8):
                for base in range(8):
                    disp_bytes = []
                    #if base == 5: disp_bytes = [0x11, 0x22, 0x33, 0x44]
                    
                    emit_test(prefixes=[], opcode=[0x01], modrm=(mod<<6)|(1<<3)|rm, 
                              sib=(scale<<6)|(index<<3)|base, disp=disp_bytes)

        # =================================================================
        # PART 4: IMMEDIATES & DISPLACEMENTS
        # =================================================================
        emit_test(prefixes=[], opcode=[0x05], imm=[0x11, 0x22, 0x33, 0x44])
        emit_test(prefixes=[0x66], opcode=[0x05], imm=[0x11, 0x22])
        emit_test(prefixes=[], opcode=[0x04], imm=[0x11])
        emit_test(prefixes=[], opcode=[0x81], modrm=0xC0, imm=[0x11, 0x22, 0x33, 0x44])
        emit_test(prefixes=[0x66], opcode=[0x81], modrm=0xC0, imm=[0x11, 0x22])
        emit_test(prefixes=[], opcode=[0x83], modrm=0xC0, imm=[0x11])

    print("Successfully generated pillar1_tests.hex!")

if __name__ == "__main__":
    generate_pillar1_tests()