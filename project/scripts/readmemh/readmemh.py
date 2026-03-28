import re
import os

ROW_BITS  = 7
RANK_BITS = 4
CHIP_BITS = 4

ROW_COUNT  = 1 << ROW_BITS
RANK_COUNT = 1 << RANK_BITS
CHIP_COUNT = 1 << CHIP_BITS

<<<<<<< HEAD
OUT_DIR = "/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init_sample" 
=======
OUT_DIR = "/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/mem_init" 
>>>>>>> origin/predecoder

mem = {}
for r in range(RANK_COUNT):
    for c in range(CHIP_COUNT):
        mem[(r, c)] = ["xx"] * ROW_COUNT

def decode_addr(addr):
    chip = addr & 0xF
    rank = (addr >> 4) & 0xF
    row  = (addr >> 8) & 0x7F
    return rank, chip, row

def parse_file(filename):
    current_addr = None

    with open(filename, "r") as f:
        for line in f:
            line = line.strip()

            if not line:
                continue

            if line.startswith("0x"):
                m = re.match(r'0x([0-9a-fA-F]+):', line)
                if not m:
                    continue

                current_addr = int(m.group(1), 16)
                data_part = line.split(":")[1].split("//")[0]
            else:
                if current_addr is None:
                    continue
                data_part = line.split("//")[0]

            byte_list = data_part.strip().split()

            for b in byte_list:
                if len(b) != 2:
                    continue

                rank, chip, row = decode_addr(current_addr)
                mem[(rank, chip)][row] = b.lower()

                current_addr += 1

def dump_hex_files():
    if not os.path.exists(OUT_DIR):
        os.makedirs(OUT_DIR)

    for (r, c), rows in mem.items():
        path = os.path.join(OUT_DIR, "mem_rank%d_chip%d.hex" % (r, c))
        with open(path, "w") as f:
            for byte in rows:
                f.write(byte + "\n")


def generate_verilog_file():
    if not os.path.exists(OUT_DIR):
        os.makedirs(OUT_DIR)

    outpath = os.path.join(OUT_DIR, "init_mem.v")

    with open(outpath, "w") as f:
        f.write("// Auto-generated memory initialization (Verilog-2005)\n\n")
        f.write("initial begin\n")

        for r in range(RANK_COUNT):
            for c in range(CHIP_COUNT):
                hier = (
                    "DUT.full_cc_off_core_inst.off_core_top_inst."
                    "mcu_inst.main_memory_inst.rank_generation[%d].rank_inst."
                    "chip_generation[%d].sram128x8$_inst.mem"
                ) % (r, c)

                hexfile = "%s/mem_rank%d_chip%d.hex" % (OUT_DIR, r, c)

                f.write('  $readmemh("%s", %s);\n' % (hexfile, hier))

        f.write("end\n")


if __name__ == "__main__":
    parse_file("/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/program.txt")
    dump_hex_files()
    generate_verilog_file()