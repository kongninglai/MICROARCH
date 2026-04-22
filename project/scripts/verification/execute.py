import struct


class Executor:
    def __init__(self, state, mmu):
        self.state = state
        self.mmu = mmu
        self.oso = False
        self.sro = -1
        self.rep = False
        self.ext = False
        self.oeip = 0
        self.should_print_fetch = 0

    def fetch8(self):
        v = self.mmu.read_byte(1, self.state.eip, should_print=self.should_print_fetch)

        self.state.eip = (self.state.eip + 1) & 0xFFFFFFFF
        return v

    def fetch16(self):
        v = self.mmu.read_word(1, self.state.eip, should_print=self.should_print_fetch)
        self.state.eip = (self.state.eip + 2) & 0xFFFFFFFF
        return v

    def fetch32(self):
        v = self.mmu.read_dword(1, self.state.eip, should_print=self.should_print_fetch)
        self.state.eip = (self.state.eip + 4) & 0xFFFFFFFF
        return v

    def get_reg8(self, idx):
        if idx < 4:
            return self.state.gpr[idx] & 0xFF
        return (self.state.gpr[idx - 4] >> 8) & 0xFF

    def set_reg8(self, idx, val):
        val &= 0xFF
        if idx < 4:
            self.state.gpr[idx] = (self.state.gpr[idx] & 0xFFFFFF00) | val
        else:
            self.state.gpr[idx - 4] = (self.state.gpr[idx - 4] & 0xFFFF00FF) | (
                val << 8
            )

    def get_reg(self, idx, size):
        if size == 1:
            return self.get_reg8(idx)
        elif size == 2:
            return self.state.gpr[idx] & 0xFFFF
        return self.state.gpr[idx]

    def set_reg(self, idx, val, size):
        if size == 1:
            self.set_reg8(idx, val)
        elif size == 2:
            self.state.gpr[idx] = (self.state.gpr[idx] & 0xFFFF0000) | (val & 0xFFFF)
        else:
            self.state.gpr[idx] = val & 0xFFFFFFFF

    def get_rm(self, mod, rm):
        if mod == 3:
            return None, rm
        seg = 3  # DS = default
        addr = 0

        # Handle SIB
        if rm == 4:
            sib = self.fetch8()
            scale = (sib >> 6) & 3
            idx = (sib >> 3) & 7
            base = sib & 7
            if base == 5:
                raise Exception("GP_FAULT")
            if idx == 4:
                raise Exception("GP_FAULT")
            addr = self.state.gpr[base] + (self.state.gpr[idx] << scale)
            if base in (4, 5):
                seg = 2  # SS for base ESP or EBP

        # Handle just the R/M base value, or the lone disp32 case
        else:
            if mod == 0 and rm == 5:
                addr = self.fetch32()
            else:
                addr = self.state.gpr[rm]
                if rm in (4, 5):
                    seg = 2  # SS for base ESP or EBP

        # Add disp8
        if mod == 1:
            disp = self.fetch8()
            if disp & 0x80:  # Sign-extend
                disp -= 256
            addr += disp

        # Add disp32
        elif mod == 2:
            addr += self.fetch32()

        # Mask to 32-bit
        addr &= 0xFFFFFFFF

        # Segment override
        if self.sro != -1:
            seg = self.sro
        return seg, addr

    def read_rm(self, seg, addr, size):
        # Register value
        if seg is None:
            return self.get_reg(addr, size)

        # Otherwise, it's a memory value
        if size == 1:
            return self.mmu.read_byte(seg, addr) & 0xFF
        elif size == 2:
            return self.mmu.read_word(seg, addr) & 0xFFFF
        return self.mmu.read_dword(seg, addr) & 0xFFFFFFFF

    def write_rm(self, seg, addr, val, size):
        if seg is None:
            self.set_reg(addr, val, size)
        else:
            if size == 1:
                self.mmu.write_byte(seg, addr, val)
            elif size == 2:
                self.mmu.write_word(seg, addr, val)
            else:
                self.mmu.write_dword(seg, addr, val)

    def update_flags(self, res, size):
        res &= (1 << (size * 8)) - 1
        self.state.eflags["ZF"] = 1 if res == 0 else 0
        self.state.eflags["SF"] = (res >> (size * 8 - 1)) & 1
        self.state.eflags["PF"] = 1 if bin(res & 0xFF).count("1") % 2 == 0 else 0

    # 000 = ADD, 001 = OR, 010 = ADC, 011 = SBB, 100 = AND
    def calc_alu(self, op, v1, v2, size, calc_flags=True):
        res = 0
        mask = (1 << (size * 8)) - 1
        sign_bit = 1 << (size * 8 - 1)
        if op == 0:
            res = v1 + v2
            if calc_flags:
                self.state.eflags["CF"] = 1 if res > mask else 0
                self.state.eflags["OF"] = (
                    1 if ((v1 ^ res) & (v2 ^ res) & sign_bit) else 0
                )
                self.state.eflags["AF"] = ((v1 ^ v2 ^ res) >> 4) & 1
        elif op == 1:
            res = v1 | v2
            if calc_flags:
                self.state.eflags["CF"] = 0
                self.state.eflags["OF"] = 0
        elif op == 2:
            res = v1 + v2 + self.state.eflags["CF"]
            v2_with_carry = v2 + self.state.eflags["CF"]
            if calc_flags:
                self.state.eflags["CF"] = 1 if res > mask else 0
                self.state.eflags["OF"] = (
                    1 if ((v1 ^ res) & (v2_with_carry ^ res) & sign_bit) else 0
                )
                self.state.eflags["AF"] = ((v1 ^ v2_with_carry ^ res) >> 4) & 1
        elif op == 3:
            res = v1 - v2 - self.state.eflags["CF"]
            v2_twos = (~(v2 + self.state.eflags["CF"]) + 1) & mask
            if calc_flags:
                self.state.eflags["CF"] = (
                    1 if v1 < (v2 + self.state.eflags["CF"]) else 0
                )
                self.state.eflags["OF"] = (
                    1 if ((v1 ^ res) & (v2_twos ^ res) & sign_bit) else 0
                )
                self.state.eflags["AF"] = (
                    1 if (v1 & 0xF) < ((v2 + self.state.eflags["CF"]) & 0xF) else 0
                )
        elif op == 4:
            res = v1 & v2
            if calc_flags:
                self.state.eflags["CF"] = 0
                self.state.eflags["OF"] = 0
        elif op == 5:  # Subtract WITHOUT BORROW
            res = v1 - v2
            v2_twos = (~(v2) + 1) & mask
            if calc_flags:
                self.state.eflags["CF"] = 1 if v1 < (v2) else 0
                self.state.eflags["OF"] = (
                    1 if ((v1 ^ res) & (v2_twos ^ res) & sign_bit) else 0
                )
                self.state.eflags["AF"] = 1 if (v1 & 0xF) < ((v2) & 0xF) else 0
        res &= mask
        if calc_flags:
            self.update_flags(res, size)
        return res

    def push(self, val, size):
        self.state.gpr[4] = (self.state.gpr[4] - size) & 0xFFFFFFFF
        if size == 2:
            self.mmu.write_byte(2, self.state.gpr[4], val & 0xFF, check_lim=0)
            self.mmu.write_byte(
                2, self.state.gpr[4] + 1, (val >> 8) & 0xFF, check_lim=0
            )
        elif size ==4:
            self.mmu.write_dword(2, self.state.gpr[4], val, check_lim=0)
        else:
            self.mmu.write_qword(2, self.state.gpr[4], val, check_lim=0)

    def pop(self, size):
        if size == 2:
            b0 = self.mmu.read_byte(2, self.state.gpr[4], check_lim=0)
            b1 = self.mmu.read_byte(2, self.state.gpr[4] + 1, check_lim=0)
            val = b0 | (b1 << 8)
        else:
            val = self.mmu.read_dword(2, self.state.gpr[4], check_lim=0)
        self.state.gpr[4] = (self.state.gpr[4] + size) & 0xFFFFFFFF
        return val

    def do_int(self, vector):
        eflags_val = (
            self.state.eflags["CF"]
            | (self.state.eflags["PF"] << 2)
            | (self.state.eflags["AF"] << 4)
            | (self.state.eflags["ZF"] << 6)
            | (self.state.eflags["SF"] << 7)
            | (self.state.eflags["DF"] << 10)
            | (self.state.eflags["OF"] << 11)
        )
        self.push(eflags_val & 0xFFFFFFFF, 4)
        idt_addr = self.state.idtr_base + (vector * 8)
        temp = self.state.seg[1] & 0xFFFF
        self.state.seg[1] = 0
        low = self.mmu.read_dword(1, idt_addr, check_lim=0)
        high = self.mmu.read_dword(1, idt_addr + 4, check_lim=0)
        self.state.seg[1] = temp

        old_eip = self.state.eip & 0xFFFFFFFF
        old_cs = self.state.seg[1] & 0xFFFF

        self.push(((old_cs << 32) | old_eip), 8)

        new_eip = (low & 0xFFFF) | (high & 0xFFFF0000)
        new_cs = (low >> 16) & 0xFFFF

        self.state.eip = new_eip
        self.state.seg[1] = new_cs

    def check_cond(self, cond):
        cf = self.state.eflags["CF"]
        zf = self.state.eflags["ZF"]
        if cond == 7:
            return cf == 0 and zf == 0
        elif cond == 5:
            return zf == 0
        return False

    def packsswb(self, op1, op2):
        res = [0] * 8
        for i in range(4):
            val = op1[i]
            if val > 127:
                val = 127
            if val < -128:
                val = -128
            res[i] = val & 0xFF
        for i in range(4):
            val = op2[i]
            if val > 127:
                val = 127
            if val < -128:
                val = -128
            res[i + 4] = val & 0xFF
        return res

    def packssdw(self, op1, op2):
        res = [0] * 4
        for i in range(2):
            val = op1[i]
            if val > 32767:
                val = 32767
            if val < -32768:
                val = -32768
            res[i] = val & 0xFFFF
        for i in range(2):
            val = op2[i]
            if val > 32767:
                val = 32767
            if val < -32768:
                val = -32768
            res[i + 2] = val & 0xFFFF
        return res

    def read_mm64(self, mod, rm, seg, addr):
        if mod == 3:
            return self.state.mmx[rm]
        return self.mmu.read_qword(seg, addr)

    def write_mm64(self, mod, rm, seg, addr, val):
        if mod == 3:
            self.state.mmx[rm] = val & 0xFFFFFFFFFFFFFFFF
        else:
            self.mmu.write_qword(seg, addr, val)

    ########################### GOOD ABOVE #########################

    def step(self):
        if self.state.halted:
            return
        self.oso = False
        self.sro = -1
        self.rep = False
        self.ext = False
        self.oeip = self.state.eip

        try:
            while True:
                op = self.fetch8()
                if op == 0x66:
                    self.oso = True
                elif op == 0xF3:
                    self.rep = True
                elif op == 0x2E:
                    self.sro = 1
                elif op == 0x3E:
                    self.sro = 3
                elif op == 0x36:
                    self.sro = 2
                elif op == 0x26:
                    self.sro = 0
                elif op == 0x64:
                    self.sro = 4
                elif op == 0x65:
                    self.sro = 5
                elif op == 0x0F:
                    self.ext = True
                    op = self.fetch8()
                    break
                else:
                    break

            if self.ext:
                if op in (0x85, 0x87):  # JN(B)E rel16/32
                    rel = self.fetch16() if self.oso else self.fetch32()
                    if self.oso and (rel & 0x8000):
                        rel -= 65536
                    elif not self.oso and (rel & 0x80000000):
                        rel -= 0x100000000
                    cond = 5 if op == 0x85 else 7
                    if self.check_cond(cond):
                        if self.mmu.check_segment(
                            (self.state.eip + rel)
                            & (0xFFFF if self.oso else 0xFFFFFFFF),
                            1,
                        ):
                            self.state.eip = (self.state.eip + rel) & (
                                0xFFFF if self.oso else 0xFFFFFFFF
                            )
                        else:
                            raise Exception("GP_FAULT")
                elif op == 0x42:  # CMOVC r16/32, r/m16/32
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    size = 2 if self.oso else 4
                    seg, addr = self.get_rm(mod, rm)
                    if self.state.eflags["CF"] == 1:
                        self.set_reg(reg, self.read_rm(seg, addr, size), size)
                    else:
                        dummy = self.read_rm(seg, addr, size)
                elif op == 0xA0:  # PUSH FS (16/32-bit)
                    self.push(self.state.seg[4], 2 if self.oso else 4)
                elif op == 0xA1:  # POP FS (16/32-bit)
                    self.state.seg[4] = self.pop(2 if self.oso else 4) & 0xFFFF
                elif op == 0xA8:  # PUSH GS (16/32-bit)
                    self.push(self.state.seg[5], 2 if self.oso else 4)
                elif op == 0xA9:  # POP GS (16/32-bit)
                    self.state.seg[5] = self.pop(2 if self.oso else 4) & 0xFFFF
                elif op in (0xB0, 0xB1):  # CMPXCHG r/m8, r8 (16 and 32)
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    size = 1 if op == 0xB0 else (2 if self.oso else 4)
                    seg, addr = self.get_rm(mod, rm)
                    rm_val = self.read_rm(seg, addr, size)
                    al_val = self.get_reg(0, size)
                    self.calc_alu(5, al_val, rm_val, size)
                    if al_val == rm_val:
                        self.write_rm(seg, addr, self.get_reg(reg, size), size)
                    else:
                        self.set_reg(0, rm_val, size)
                elif op == 0xBC:  # BSF r16/32, r/m16/32
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    size = 2 if self.oso else 4
                    seg, addr = self.get_rm(mod, rm)
                    rm_val = self.read_rm(seg, addr, size)
                    if rm_val == 0:
                        self.state.eflags["ZF"] = 1
                    else:
                        self.state.eflags["ZF"] = 0
                        idx = 0
                        while (rm_val & (1 << idx)) == 0:
                            idx += 1
                        self.set_reg(reg, idx, size)
                elif op == 0x63:  # PACKSSWB mm1, mm/mm64; dest goes into lower bytes
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    seg, addr = self.get_rm(mod, rm)
                    op1_val = self.state.mmx[reg]
                    op2_val = self.read_mm64(mod, rm, seg, addr)
                    op1_words = [((op1_val >> (i * 16)) & 0xFFFF) for i in range(4)]
                    op2_words = [((op2_val >> (i * 16)) & 0xFFFF) for i in range(4)]
                    op1_words = [w if w < 0x8000 else w - 0x10000 for w in op1_words]
                    op2_words = [w if w < 0x8000 else w - 0x10000 for w in op2_words]
                    res_bytes = self.packsswb(op1_words, op2_words)
                    res_val = sum((res_bytes[i] & 0xFF) << (i * 8) for i in range(8))
                    self.state.mmx[reg] = res_val
                elif op == 0x6B:  # PACKSSDW mm1, mm/mm64
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    seg, addr = self.get_rm(mod, rm)
                    op1_val = self.state.mmx[reg]
                    op2_val = self.read_mm64(mod, rm, seg, addr)
                    op1_dwords = [
                        ((op1_val >> (i * 32)) & 0xFFFFFFFF) for i in range(2)
                    ]
                    op2_dwords = [
                        ((op2_val >> (i * 32)) & 0xFFFFFFFF) for i in range(2)
                    ]
                    op1_dwords = [
                        d if d < 0x80000000 else d - 0x100000000 for d in op1_dwords
                    ]
                    op2_dwords = [
                        d if d < 0x80000000 else d - 0x100000000 for d in op2_dwords
                    ]
                    res_words = self.packssdw(op1_dwords, op2_dwords)
                    res_val = sum((res_words[i] & 0xFFFF) << (i * 16) for i in range(4))
                    self.state.mmx[reg] = res_val
                elif op == 0x6F:  # MOVQ mm, mm/m64
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    seg, addr = self.get_rm(mod, rm)
                    self.state.mmx[reg] = self.read_mm64(mod, rm, seg, addr)
                elif op == 0x7F:  # MOVQ mm/m64, mm
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    seg, addr = self.get_rm(mod, rm)
                    self.write_mm64(mod, rm, seg, addr, self.state.mmx[reg])
                elif op == 0xE0:  # PAVGB mm1, mm2/m64
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    seg, addr = self.get_rm(mod, rm)
                    op1_val = self.state.mmx[reg]
                    op2_val = self.read_mm64(mod, rm, seg, addr)
                    res = 0
                    for i in range(8):
                        b1 = (op1_val >> (i * 8)) & 0xFF
                        b2 = (op2_val >> (i * 8)) & 0xFF
                        avg = (b1 + b2 + 1) >> 1
                        res |= avg << (i * 8)
                    self.state.mmx[reg] = res
                elif op == 0xE3:  # PAVGW mm1, mm2/m64
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    seg, addr = self.get_rm(mod, rm)
                    op1_val = self.state.mmx[reg]
                    op2_val = self.read_mm64(mod, rm, seg, addr)
                    res = 0
                    for i in range(4):
                        w1 = (op1_val >> (i * 16)) & 0xFFFF
                        w2 = (op2_val >> (i * 16)) & 0xFFFF
                        avg = (w1 + w2 + 1) >> 1
                        res |= avg << (i * 16)
                    self.state.mmx[reg] = res
                elif op == 0xFD:  # PADDW mm, mm/m64
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    seg, addr = self.get_rm(mod, rm)
                    op1_val = self.state.mmx[reg]
                    op2_val = self.read_mm64(mod, rm, seg, addr)
                    res = 0
                    for i in range(4):
                        w1 = (op1_val >> (i * 16)) & 0xFFFF
                        w2 = (op2_val >> (i * 16)) & 0xFFFF
                        added = (w1 + w2) & 0xFFFF
                        res |= added << (i * 16)
                    self.state.mmx[reg] = res
                elif op == 0xFE:  # PADDD mm, mm/m64
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    seg, addr = self.get_rm(mod, rm)
                    op1_val = self.state.mmx[reg]
                    op2_val = self.read_mm64(mod, rm, seg, addr)
                    res = 0
                    for i in range(2):
                        d1 = (op1_val >> (i * 32)) & 0xFFFFFFFF
                        d2 = (op2_val >> (i * 32)) & 0xFFFFFFFF
                        added = (d1 + d2) & 0xFFFFFFFF
                        res |= added << (i * 32)
                    self.state.mmx[reg] = res
            else:
                if (
                    op < 0x40 and (op & 0x07) < 6
                ):  # ADD r/m8, r8; ADD r8, r/m8, ADD AL, imm8, same for OR/AND/ADC/SBB
                    alu_op = (
                        op >> 3
                    ) & 7  # 000 = ADD, 001 = OR, 010 = ADC, 011 = SBB, 100 = AND
                    size = (
                        1 if (op & 1) == 0 else (2 if self.oso else 4)
                    )  # even = 1, odd = 2 or 4
                    d = (op & 2) >> 1  # d = 1 if dst is r_ instead of r/m_ or EAX[X:X]
                    if (op & 4) == 0:
                        modrm = self.fetch8()
                        mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                        seg, addr = self.get_rm(mod, rm)
                        rm_val = self.read_rm(seg, addr, size)
                        r_val = self.get_reg(reg, size)
                        v1 = rm_val if d == 0 else r_val
                        v2 = r_val if d == 0 else rm_val
                        res = self.calc_alu(alu_op, v1, v2, size)
                        if d == 0:
                            self.write_rm(seg, addr, res, size)
                        else:
                            self.set_reg(reg, res, size)
                    else:  # EAX[X:X] is destination, has immediate as 2nd operand
                        v1 = self.get_reg(0, size)
                        v2 = (
                            self.fetch8()
                            if size == 1
                            else (self.fetch16() if size == 2 else self.fetch32())
                        )
                        res = self.calc_alu(alu_op, v1, v2, size)
                        self.set_reg(0, res, size)

                elif op in (
                    0x80,
                    0x81,
                    0x83,
                ):  # ADD r/m8, imm8; ADD r8, r/m8, ADD AL, imm8, same for OR/AND/ADC/SBB
                    modrm = self.fetch8()
                    mod, alu_op, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    size = 1 if op == 0x80 else (2 if self.oso else 4)
                    seg, addr = self.get_rm(mod, rm)
                    v1 = self.read_rm(seg, addr, size)
                    if op == 0x81:
                        v2 = self.fetch16() if size == 2 else self.fetch32()
                    else:
                        v2 = self.fetch8()
                        if op == 0x83 and (v2 & 0x80):
                            v2 = v2 - 256
                            v2 &= (1 << (size * 8)) - 1
                    res = self.calc_alu(alu_op, v1, v2, size)
                    self.write_rm(seg, addr, res, size)

                elif op >= 0x50 and op <= 0x57:  # PUSH r16 / PUSH r32
                    size = 2 if self.oso else 4
                    self.push(self.get_reg(op - 0x50, size), size)

                elif op >= 0x58 and op <= 0x5F:  # POP r16 / POP r32
                    size = 2 if self.oso else 4
                    self.set_reg(op - 0x58, self.pop(size), size)

                elif op in (0x6A, 0x68):  # PUSH imm8/16/32
                    size = 2 if self.oso else 4
                    if op == 0x6A:
                        val = self.fetch8()
                        if val & 0x80:
                            val -= 256
                        val &= (1 << (size * 8)) - 1
                    else:
                        val = self.fetch16() if size == 2 else self.fetch32()
                    self.push(val, size)

                elif op == 0x8F:  # POP r/m16 | POP r/m32
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    size = 2 if self.oso else 4
                    val = self.pop(size)
                    seg, addr = self.get_rm(mod, rm)
                    self.write_rm(seg, addr, val, size)

                elif op >= 0x88 and op <= 0x8B:  # MOV r, r/m and MOV r/m, r
                    size = 1 if (op & 1) == 0 else (2 if self.oso else 4)
                    d = (op & 2) >> 1
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    seg, addr = self.get_rm(mod, rm)
                    if d == 0:
                        self.write_rm(seg, addr, self.get_reg(reg, size), size)
                    else:
                        self.set_reg(reg, self.read_rm(seg, addr, size), size)

                elif op >= 0xB0 and op <= 0xBF:  # MOV r, imm
                    size = 1 if op < 0xB8 else (2 if self.oso else 4)
                    idx = op & 7
                    val = (
                        self.fetch8()
                        if size == 1
                        else (self.fetch16() if size == 2 else self.fetch32())
                    )
                    self.set_reg(idx, val, size)

                elif op in (0xC6, 0xC7):  # MOV r/m, imm
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    size = 1 if op == 0xC6 else (2 if self.oso else 4)
                    seg, addr = self.get_rm(mod, rm)
                    val = (
                        self.fetch8()
                        if size == 1
                        else (self.fetch16() if size == 2 else self.fetch32())
                    )
                    self.write_rm(seg, addr, val, size)

                elif op >= 0x90 and op <= 0x97:  # XCHG (E)AX, r
                    if op == 0x90:
                        pass
                    else:
                        size = 2 if self.oso else 4
                        tmp = self.get_reg(0, size)
                        self.set_reg(0, self.get_reg(op - 0x90, size), size)
                        self.set_reg(op - 0x90, tmp, size)

                elif op in (0x86, 0x87):  # XCHG r/m, r
                    size = 1 if op == 0x86 else (2 if self.oso else 4)
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    seg, addr = self.get_rm(mod, rm)
                    v1 = self.read_rm(seg, addr, size)
                    v2 = self.get_reg(reg, size)
                    self.write_rm(seg, addr, v2, size)
                    self.set_reg(reg, v1, size)

                elif op in (
                    0xE8,
                    0xE9,
                    0xEB,
                ):  # CALL rel16/32 | JMP rel16/32 | JMP rel8
                    if op == 0xEB:
                        rel = self.fetch8()
                        if rel & 0x80:
                            rel -= 256
                    else:
                        rel = self.fetch16() if self.oso else self.fetch32()
                        if self.oso and (rel & 0x8000):
                            rel -= 65536
                        elif not self.oso and (rel & 0x80000000):
                            rel -= 0x100000000
                    if op == 0xE8:
                        if self.mmu.check_segment(
                            (self.state.eip + rel)
                            & (0xFFFF if self.oso else 0xFFFFFFFF),
                            1,
                        ):
                            self.push(self.state.eip, 2 if self.oso else 4)
                        else:
                            raise Exception("GP_FAULT")
                    if self.mmu.check_segment(
                        (self.state.eip + rel) & (0xFFFF if self.oso else 0xFFFFFFFF), 1
                    ):
                        self.state.eip = (self.state.eip + rel) & (
                            0xFFFF if self.oso else 0xFFFFFFFF
                        )
                    else:
                        raise Exception("GP_FAULT")

                elif op in (0x75, 0x77):  # JN(B)E rel8
                    rel = self.fetch8()
                    if rel & 0x80:
                        rel -= 256
                    cond = 5 if op == 0x75 else 7
                    if self.check_cond(cond):
                        if self.mmu.check_segment(
                            (self.state.eip + rel)
                            & (0xFFFF if self.oso else 0xFFFFFFFF),
                            1,
                        ):
                            self.state.eip = (self.state.eip + rel) & (
                                0xFFFF if self.oso else 0xFFFFFFFF
                            )
                        else:
                            raise Exception("GP_FAULT")

                elif op == 0xC3:  # RET (near return)
                    temp = self.pop(
                        2 if self.oso else 4
                    )  # Be careful not to pop twice by accident
                    if self.mmu.check_segment(temp, 1):
                        self.state.eip = temp
                    else:
                        raise Exception("GP_FAULT")

                elif op == 0xCF:  # IRETD
                    temp = self.pop(4)
                    if self.mmu.check_segment(temp, 1):
                        self.state.eip = temp
                        self.state.seg[1] = self.pop(4) & 0xFFFF
                        eflags_val = self.pop(4)
                        self.state.eflags["CF"] = eflags_val & 1
                        self.state.eflags["PF"] = (eflags_val >> 2) & 1
                        self.state.eflags["AF"] = (eflags_val >> 4) & 1
                        self.state.eflags["ZF"] = (eflags_val >> 6) & 1
                        self.state.eflags["SF"] = (eflags_val >> 7) & 1
                        self.state.eflags["DF"] = (eflags_val >> 10) & 1
                        self.state.eflags["OF"] = (eflags_val >> 11) & 1
                    else:
                        raise Exception("GP_FAULT")

                elif op == 0x06:  # PUSH ES (16/32-bit)
                    self.push(self.state.seg[0], 2 if self.oso else 4)
                elif op == 0x07:  # POP ES (16/32-bit)
                    self.state.seg[0] = self.pop(2 if self.oso else 4) & 0xFFFF
                elif op == 0x0E:  # PUSH CS (16/32-bit)
                    self.push(self.state.seg[1], 2 if self.oso else 4)
                elif op == 0x16:  # PUSH SS (16/32-bit)
                    self.push(self.state.seg[2], 2 if self.oso else 4)
                elif op == 0x17:  # POP SS (16/32-bit)
                    self.state.seg[2] = self.pop(2 if self.oso else 4) & 0xFFFF
                elif op == 0x1E:  # PUSH DS (16/32-bit)
                    self.push(self.state.seg[3], 2 if self.oso else 4)
                elif op == 0x1F:  # POP DS (16/32-bit)
                    self.state.seg[3] = self.pop(2 if self.oso else 4) & 0xFFFF
                elif op == 0x37:  # AAA
                    al = self.get_reg8(0)
                    af = self.state.eflags["AF"]
                    if (al & 0x0F) > 9 or af == 1:
                        al = (al + 6) & 0xFF
                        ah = (self.get_reg8(4) + 1) & 0xFF
                        self.set_reg8(0, al)
                        self.set_reg8(4, ah)
                        self.state.eflags["CF"] = 1
                        self.state.eflags["AF"] = 1
                    else:
                        self.state.eflags["CF"] = 0
                        self.state.eflags["AF"] = 0
                    self.set_reg8(0, self.get_reg8(0) & 0x0F)
                elif op == 0x8C:  # MOV r/m16, Sreg
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    seg, addr = self.get_rm(mod, rm)
                    self.write_rm(seg, addr, self.state.seg[reg], 2)
                elif op == 0x8E:  # MOV Sreg, r/m16
                    modrm = self.fetch8()
                    mod, reg, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    seg, addr = self.get_rm(mod, rm)
                    if (reg != 1): # Cannot do MOV CS, ---
                        self.state.seg[reg] = self.read_rm(seg, addr, 2)
                elif op == 0x9A:  # CALL ptr16:16/32
                    eip_val = self.fetch16() if self.oso else self.fetch32()
                    cs_val = self.fetch16()
                    if self.mmu.check_segment(eip_val, 1):
                        # self.push(self.state.seg[1], 2 if self.oso else 4)
                        # self.push(self.state.eip, 2 if self.oso else 4)
                        push_data = ((self.state.seg[1]<<16) | (self.state.eip & 0xFFFF)) if self.oso else ((self.state.seg[1]<<32) | self.state.eip )
                        self.push(push_data, 4 if self.oso else 8)
                        self.state.seg[1] = cs_val
                        self.state.eip = eip_val
                    else:
                        raise Exception("GP_FAULT")
                elif op == 0xEA:  # JMP ptr16:16/32
                    eip_val = self.fetch16() if self.oso else self.fetch32()
                    cs_val = self.fetch16()
                    if self.mmu.check_segment(eip_val, 1):
                        self.state.seg[1] = cs_val
                        self.state.eip = eip_val
                    else:
                        raise Exception("GP_FAULT")
                elif op in (0xA4, 0xA5):  # (REP) MOVS m8/16/32, m8/16/32
                    size = 1 if op == 0xA4 else (2 if self.oso else 4)
                    src_seg = 3 if self.sro == -1 else self.sro
                    dst_seg = 0
                    while True:
                        if self.rep and self.get_reg(1, 4) == 0:
                            break
                        esi = self.get_reg(6, 4)
                        edi = self.get_reg(7, 4)
                        val = (
                            self.mmu.read_dword(src_seg, esi, check_lim=1)
                            if size == 4
                            else (
                                self.mmu.read_word(src_seg, esi, check_lim=1)
                                if size == 2
                                else self.mmu.read_byte(src_seg, esi, check_lim=1)
                            )
                        )
                        if size == 4:
                            self.mmu.write_dword(dst_seg, edi, val, check_lim=1)
                        elif size == 2:
                            self.mmu.write_word(dst_seg, edi, val, check_lim=1)
                        else:
                            self.mmu.write_byte(dst_seg, edi, val, check_lim=1)
                        inc = size if self.state.eflags["DF"] == 0 else -size
                        self.set_reg(6, (esi + inc) & 0xFFFFFFFF, 4)
                        self.set_reg(7, (edi + inc) & 0xFFFFFFFF, 4)
                        if self.rep:
                            self.set_reg(1, (self.get_reg(1, 4) - 1) & 0xFFFFFFFF, 4)
                        else:
                            break
                elif op == 0xA7:  # REPE CMPS m32, m32
                    size = 4
                    src_seg = 3 if self.sro == -1 else self.sro
                    dst_seg = 0
                    while True:
                        if self.rep and self.get_reg(1, 4) == 0:
                            break
                        esi = self.get_reg(6, 4)
                        edi = self.get_reg(7, 4)
                        v1 = self.mmu.read_dword(src_seg, esi, check_lim=1)
                        v2 = self.mmu.read_dword(dst_seg, edi, check_lim=1)
                        self.calc_alu(5, v1, v2, size)
                        inc = size if self.state.eflags["DF"] == 0 else -size
                        self.set_reg(6, (esi + inc) & 0xFFFFFFFF, 4)
                        self.set_reg(7, (edi + inc) & 0xFFFFFFFF, 4)
                        if self.rep:
                            self.set_reg(1, (self.get_reg(1, 4) - 1) & 0xFFFFFFFF, 4)
                            if self.state.eflags["ZF"] == 0:
                                break
                        else:
                            break
                elif op in (0xC0, 0xC1, 0xD0, 0xD1, 0xD2, 0xD3):  # SAL / SAR
                    modrm = self.fetch8()
                    mod, sub_op, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    size = 1 if op in (0xC0, 0xD0, 0xD2) else (2 if self.oso else 4)
                    seg, addr = self.get_rm(mod, rm)
                    val = self.read_rm(seg, addr, size)
                    if op in (0xC0, 0xC1):
                        count = self.fetch8() & 0x1F
                    elif op in (0xD0, 0xD1):
                        count = 1
                    else:
                        count = self.get_reg8(1) & 0x1F
                    if count > 0:
                        mask = (1 << (size * 8)) - 1
                        if sub_op == 4:  # SAL
                            res = (val << count) & mask
                            temp = (val << (count - 1)) & mask
                            temp = temp >> (size * 8 - 1)
                            self.state.eflags["CF"] = temp & 1
                            self.update_flags(res, size)  # Only sets PF, SF, ZF
                            if (count == 1):
                              self.state.eflags["OF"] = self.state.eflags["CF"] ^ (
                                  (res >> (size * 8 - 1)) & 1
                              ) # Same behavior for count == 1 and otherwise
                            else:
                              self.state.eflags["OF"] = ((val >> (size * 8 - 1)) & 1) ^ ((val >> (size * 8 - 2)) & 1)
                            self.write_rm(seg, addr, res, size)
                        elif sub_op == 7:  # SAR
                            sign = (val >> (size * 8 - 1)) & 1
                            res = val
                            for _ in range(count):
                                self.state.eflags["CF"] = res & 1
                                res = (res >> 1) | (sign << (size * 8 - 1))
                            res &= mask
                            self.update_flags(res, size)
                            self.state.eflags["OF"] = 0 # Same behavior for count == 1 & otherwise...
                            self.write_rm(seg, addr, res, size)
                elif op == 0xC2:  # RET imm16 (near, 16/32-bit pop)
                    imm = self.fetch16()
                    eip_val = self.pop(2 if self.oso else 4)
                    self.state.gpr[4] = (self.state.gpr[4] + imm) & 0xFFFFFFFF
                    if self.mmu.check_segment(eip_val, 1):
                        self.state.eip = eip_val
                    else:
                        raise Exception("GP_FAULT")
                elif op == 0xCA:  # RET imm16 (far, 16/32-bit pop)
                    imm = self.fetch16()
                    eip_val = self.pop(2 if self.oso else 4)
                    cs_val = self.pop(2 if self.oso else 4) & 0xFFFF
                    self.state.gpr[4] = (self.state.gpr[4] + imm) & 0xFFFFFFFF
                    if self.mmu.check_segment(eip_val, 1):
                        self.state.seg[1] = cs_val
                        self.state.eip = eip_val
                    else:
                        raise Exception("GP_FAULT")
                elif op == 0xCB:  # RET (far, 16/32-bit pop)
                    eip_val = self.pop(2 if self.oso else 4)
                    cs_val = self.pop(2 if self.oso else 4) & 0xFFFF
                    if self.mmu.check_segment(eip_val, 1):
                        self.state.seg[1] = cs_val
                        self.state.eip = eip_val
                    else:
                        raise Exception("GP_FAULT")
                elif op in (0xF6, 0xF7):  # NOT r/m8/16/32
                    modrm = self.fetch8()
                    mod, sub_op, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    size = 1 if op == 0xF6 else (2 if self.oso else 4)
                    if sub_op == 2:
                        seg, addr = self.get_rm(mod, rm)
                        val = self.read_rm(seg, addr, size)
                        self.write_rm(seg, addr, (~val) & ((1 << (size * 8)) - 1), size)
                elif op == 0xFC:  # CLD
                    self.state.eflags["DF"] = 0
                elif op == 0xFD:  # STD
                    self.state.eflags["DF"] = 1
                elif op == 0xFF:  # CALL/JMP/PUSH r/m16/32
                    modrm = self.fetch8()
                    mod, sub_op, rm = (modrm >> 6) & 3, (modrm >> 3) & 7, modrm & 7
                    size = 2 if self.oso else 4
                    seg, addr = self.get_rm(mod, rm)
                    val = self.read_rm(seg, addr, size)
                    if sub_op == 2:  # CALL
                        if self.mmu.check_segment(val, 1):
                            self.push(self.state.eip, size)
                            self.state.eip = val
                        else:
                            raise Exception("GP_FAULT")
                    elif sub_op == 4:  # JMP
                        if self.mmu.check_segment(val, 1):
                            self.state.eip = val
                        else:
                            raise Exception("GP_FAULT")
                    elif sub_op == 6:  # PUSH
                        self.push(val, size)
                elif op == 0xF4:  # HLT
                    self.state.halted = True

        except Exception as e:
            if str(e) == "GP_FAULT":
                # print("GP_FAULT")
                self.state.eip = self.oeip
                self.do_int(13)
            elif str(e) == "PAGE_FAULT":
                # print("PAGE_FAULT")
                self.state.eip = self.oeip
                self.do_int(14)
