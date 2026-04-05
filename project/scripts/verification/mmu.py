class MMU:
    def __init__(self, state):
        self.state = state
        self.memory = {}
        self.tlb = {}

    def load_tlb_entry(self, entry_str):
        if len(entry_str) != 27:
            return
        vpn = int(entry_str[0:20], 2)
        pfn = int(entry_str[20:23], 2)
        valid = int(entry_str[23])
        present = int(entry_str[24])
        rw = int(entry_str[25])
        cache_en = int(entry_str[26])
        self.tlb[vpn] = {
            "pfn": pfn,
            "valid": valid,
            "present": present,
            "rw": rw,
            "cache": cache_en,
        }

    def check_segment(self, offset, seg_idx):
        if seg_idx == 2:
            return True
        if (offset >> 20) != 0:
            return False
        if (offset & 0xFFFFF) > self.state.seg_limit[seg_idx]:
            return False
        return True

    def translate(self, va, is_write):
        vpn = va >> 12
        offset = va & 0xFFF
        if vpn not in self.tlb:
            raise Exception("PAGE_FAULT")

        entry = self.tlb[vpn]
        if not entry["valid"] or not entry["present"]:
            raise Exception("PAGE_FAULT")
        if is_write and entry["rw"]:
            raise Exception("GP_FAULT")

        return (entry["pfn"] << 12) | offset

    def read_byte(self, seg_idx, offset, check_lim=1, should_print=1):
        if check_lim == 1 and seg_idx == 2:
            check_lim = 0
        if check_lim and not self.check_segment(offset, seg_idx):
            raise Exception("GP_FAULT")

        va = (self.state.seg[seg_idx] << 16) + offset
        pa = self.translate(va, is_write=False)
        if should_print == 1:
            print(
                f"Read  0x{self.memory.get(pa, 0):02x} from va = 0x{va:08x} and pa = 0x{pa:04x}"
            )
        return self.memory.get(pa, 0)

    def write_byte(
        self, seg_idx, offset, val, check_lim=1, populating=False, should_print=1
    ):
        if check_lim == 1 and seg_idx == 2:
            check_lim = 0
        if check_lim and not populating and not self.check_segment(offset, seg_idx):
            raise Exception("GP_FAULT")

        va = (self.state.seg[seg_idx] << 16) + offset
        pa = offset if populating else self.translate(va, is_write=not populating)
        self.memory[pa] = val & 0xFF
        if should_print == 1 and not populating:
            print(
                f"Wrote 0x{self.memory[pa]:02x} to   va = 0x{va:08x} and pa = 0x{pa:04x}"
            )

    def read_word(self, seg_idx, offset, check_lim=1, should_print=1):
        b0 = self.read_byte(seg_idx, offset, check_lim, should_print)
        b1 = self.read_byte(seg_idx, offset + 1, check_lim, should_print)
        return b0 | (b1 << 8)

    def read_dword(self, seg_idx, offset, check_lim=1, should_print=1):
        b0 = self.read_byte(seg_idx, offset, check_lim, should_print)
        b1 = self.read_byte(seg_idx, offset + 1, check_lim, should_print)
        b2 = self.read_byte(seg_idx, offset + 2, check_lim, should_print)
        b3 = self.read_byte(seg_idx, offset + 3, check_lim, should_print)
        return b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)

    def read_qword(self, seg_idx, offset, check_lim=1):
        b0 = self.read_byte(seg_idx, offset, check_lim)
        b1 = self.read_byte(seg_idx, offset + 1, check_lim)
        b2 = self.read_byte(seg_idx, offset + 2, check_lim)
        b3 = self.read_byte(seg_idx, offset + 3, check_lim)
        b4 = self.read_byte(seg_idx, offset + 4, check_lim)
        b5 = self.read_byte(seg_idx, offset + 5, check_lim)
        b6 = self.read_byte(seg_idx, offset + 6, check_lim)
        b7 = self.read_byte(seg_idx, offset + 7, check_lim)
        return (
            b0
            | (b1 << 8)
            | (b2 << 16)
            | (b3 << 24)
            | (b4 << 32)
            | (b5 << 40)
            | (b6 << 48)
            | (b7 << 56)
        )

    def write_word(self, seg_idx, offset, val, check_lim=1, populating=False):
        if check_lim == 1 and seg_idx != 2:
            if not self.check_segment(offset + 1, seg_idx):
                raise Exception("GP_FAULT")
            else:
                self.write_byte(seg_idx, offset, val & 0xFF, check_lim, populating)
                self.write_byte(
                    seg_idx, offset + 1, (val >> 8) & 0xFF, check_lim, populating
                )
        else:
            self.write_byte(seg_idx, offset, val & 0xFF, check_lim, populating)
            self.write_byte(
                seg_idx, offset + 1, (val >> 8) & 0xFF, check_lim, populating
            )

    def write_dword(self, seg_idx, offset, val, check_lim=1, populating=False):
        if check_lim == 1 and seg_idx != 2:
            if not self.check_segment(offset + 3, seg_idx):
                raise Exception("GP_FAULT")
            else:
                self.write_byte(seg_idx, offset, val & 0xFF, check_lim, populating)
                self.write_byte(
                    seg_idx, offset + 1, (val >> 8) & 0xFF, check_lim, populating
                )
                self.write_byte(
                    seg_idx, offset + 2, (val >> 16) & 0xFF, check_lim, populating
                )
                self.write_byte(
                    seg_idx, offset + 3, (val >> 24) & 0xFF, check_lim, populating
                )
        else:
            self.write_byte(seg_idx, offset, val & 0xFF, check_lim, populating)
            self.write_byte(
                seg_idx, offset + 1, (val >> 8) & 0xFF, check_lim, populating
            )
            self.write_byte(
                seg_idx, offset + 2, (val >> 16) & 0xFF, check_lim, populating
            )
            self.write_byte(
                seg_idx, offset + 3, (val >> 24) & 0xFF, check_lim, populating
            )

    def write_qword(self, seg_idx, offset, val, check_lim=1, populating=False):
        if check_lim == 1 and seg_idx != 2:
            if not self.check_segment(offset + 7, seg_idx):
                raise Exception("GP_FAULT")
            else:
                self.write_byte(seg_idx, offset, val & 0xFF, check_lim, populating)
                self.write_byte(
                    seg_idx, offset + 1, (val >> 8) & 0xFF, check_lim, populating
                )
                self.write_byte(
                    seg_idx, offset + 2, (val >> 16) & 0xFF, check_lim, populating
                )
                self.write_byte(
                    seg_idx, offset + 3, (val >> 24) & 0xFF, check_lim, populating
                )
                self.write_byte(
                    seg_idx, offset + 4, (val >> 32) & 0xFF, check_lim, populating
                )
                self.write_byte(
                    seg_idx, offset + 5, (val >> 40) & 0xFF, check_lim, populating
                )
                self.write_byte(
                    seg_idx, offset + 6, (val >> 48) & 0xFF, check_lim, populating
                )
                self.write_byte(
                    seg_idx, offset + 7, (val >> 56) & 0xFF, check_lim, populating
                )
        else:
            self.write_byte(seg_idx, offset, val & 0xFF, check_lim, populating)
            self.write_byte(
                seg_idx, offset + 1, (val >> 8) & 0xFF, check_lim, populating
            )
            self.write_byte(
                seg_idx, offset + 2, (val >> 16) & 0xFF, check_lim, populating
            )
            self.write_byte(
                seg_idx, offset + 3, (val >> 24) & 0xFF, check_lim, populating
            )
            self.write_byte(
                seg_idx, offset + 4, (val >> 32) & 0xFF, check_lim, populating
            )
            self.write_byte(
                seg_idx, offset + 5, (val >> 40) & 0xFF, check_lim, populating
            )
            self.write_byte(
                seg_idx, offset + 6, (val >> 48) & 0xFF, check_lim, populating
            )
            self.write_byte(
                seg_idx, offset + 7, (val >> 56) & 0xFF, check_lim, populating
            )
