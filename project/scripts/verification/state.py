class CPUState:
    def __init__(self):
        self.gpr = [0] * 8
        self.mmx = [0] * 8
        self.seg = [0] * 6
        self.seg_limit = [0] * 6
        self.eflags = {"CF": 0, "PF": 0, "AF": 0, "ZF": 0, "SF": 0, "OF": 0, "DF": 0}
        self.eip = 0
        self.idtr_base = 0
        self.keyboard = [0] * 32
        self.dma = [0] * 16
        self.count = 0
        self.halted = False

        self._prev = {
            "gpr": self.gpr.copy(),
            "mmx": self.mmx.copy(),
            "seg": self.seg.copy(),
            "eflags": self.eflags.copy(),
        }

    def _color(self, val_str, changed):
        if changed:
            return val_str
            # return f"\033[92m{val_str}\033[0m"
        return val_str

    def dump_state(self, mmu):
        print("Architectural State", self.count)
        self.count = self.count + 1

        prev = self._prev

        # -------- GPR --------
        gpr_names = ["EAX", "ECX", "EDX", "EBX", "ESP", "EBP", "ESI", "EDI"]
        gpr_out = []

        for i in range(8):
            val = f"0x{self.gpr[i]:08x}"
            changed = prev is not None and (self.gpr[i] != prev["gpr"][i])
            val = self._color(val, changed)
            gpr_out.append(f"{gpr_names[i]}: {val}")

        print("    ".join(gpr_out[:4]))
        print("    ".join(gpr_out[4:]))

        # -------- MMX --------
        for row in range(0, 8, 2):
            line = []
            for i in range(row, row + 2):
                val = f"0x{self.mmx[i]:016x}"
                changed = prev is not None and (self.mmx[i] != prev["mmx"][i])
                val = self._color(val, changed)
                line.append(f"MM{i}: {val}          ")
            print("     ".join(line))

        # -------- SEG --------
        seg_names = ["ES", "CS", "SS", "DS", "FS", "GS"]
        seg_out = []

        for i in range(6):
            val = f"0x{self.seg[i]:04x}"
            changed = prev is not None and (self.seg[i] != prev["seg"][i])
            val = self._color(val, changed)
            seg_out.append(f"{seg_names[i]}: {val}")

        print(" " + " ".join(seg_out))

        # -------- FLAGS --------
        flag_names = ["CF", "PF", "AF", "ZF", "SF", "OF", "DF"]
        flags_out = []

        for name in flag_names:
            val = self.eflags[name]
            changed = prev is not None and self.eflags[name] != prev["eflags"][name]

            val_str = self._color(f"{val}", changed)
            flags_out.append(f"{name}: {val_str}")

        print(" " + "      ".join(flags_out))

        # -------- EIP --------
        print(f"EIP: 0x{self.eip:08x}")

        print("-" * 40)

        # -------- SAVE SNAPSHOT --------
        self._prev = {
            "gpr": self.gpr.copy(),
            "mmx": self.mmx.copy(),
            "seg": self.seg.copy(),
            "eflags": self.eflags.copy(),
        }
