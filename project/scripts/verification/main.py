import sys
from state import CPUState
from mmu import MMU
from execute import Executor
from parse_program_file import parse_program_file


def main():
    state = CPUState()
    state.idtr_base = 0x02000000
    state.seg_limit[0] = 0x003FF
    state.seg_limit[1] = 0x04FFF
    state.seg_limit[2] = 0x04000
    state.seg_limit[3] = 0x011FF
    state.seg_limit[4] = 0x003FF
    state.seg_limit[5] = 0x007FF

    mmu = MMU(state)

    tlb_data = [
        "000000000000000000000001111",
        "000000100000000000000101101",
        "000001000000000000001011101",
        "000010110000000000001001101",
        "000011000000000000001111101",
        "000010100000000000001011101",
        "000001100000000000000011100",
        "000010000000000000000111100",
    ]
    for line in tlb_data:
        mmu.load_tlb_entry(line.strip())

    mmu.write_qword(
        1, state.idtr_base + (8 * 2), 0x0000000000000700, check_lim=0, populating=True
    )  # DMA_INT
    mmu.write_qword(
        1, state.idtr_base + (8 * 13), 0x0000000000000800, check_lim=0, populating=True
    )  # GEN PROT
    mmu.write_qword(
        1, state.idtr_base + (8 * 14), 0x0000000000000900, check_lim=0, populating=True
    )  # PF

    test_prog = parse_program_file("/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/program.txt")

    #    test_prog = [
    #       (0x0, [0xba, 0x00, 0x0a, 0x00, 0x00]),
    #       (0x5, [0x66, 0x8e, 0xda]),
    #       (0x8, [0x66, 0x81, 0xc2, 0x00, 0x01]),
    #       (0xd, [0x66, 0x8e, 0xe2]),
    #       (0x10, [0xb   8, 0x0b, 0x0a, 0x09, 0x08]),
    #       (0x15, [0xbb, 0xfd, 0x00, 0x00, 0x00]),
    #       (0x1a, [0xc7, 0x43, 0xff, 0x06, 0x05, 0x04, 0x03]),
    #       (0x21, [0x89, 0x43, 0x03]),
    #       (0x24, [0xd1, 0x3b]),
    #       (0x26, [0x88, 0x63, 0x02]),
    #       (0x29, [0x89, 0x83, 0x00, 0x08, 0x00, 0x00]),
    #       (0x2f, [0x64, 0x89, 0x13]),
    #       (0x32, [0x03, 0x03]),
    #       (0x34, [0xf4])
    #    ]

    for addr, bytes_list in test_prog:
        for i, b in enumerate(bytes_list):
            mmu.write_byte(1, addr + i, b, populating=True)

    state.eip = 0x0

    executor = Executor(state, mmu)

    while not state.halted:
        executor.step()
        executor.state.dump_state(mmu)


if __name__ == "__main__":
    main()
