N = 32
filename = "comparator32bit.in"

def write_32bit_comparator():
    with open(filename, "w") as f:
        f.write(f".i {2*N}\n")
        f.write(".o 2\n")
        ilb_list = [f"A{i}" for i in reversed(range(N))] + [f"B{i}" for i in reversed(range(N))]
        f.write(".ilb " + " ".join(ilb_list) + "\n")
        f.write(".ob lt gt\n")
        f.write(".type fr\n")

        # LT rows: first differing bit is 0/1
        for i in reversed(range(N)):
            row = ['-']*N + ['-']*N  # 32 bits for A, 32 bits for B
            row[i] = '0'       # A[i]
            row[N + i] = '1'   # B[i]
            row += ['1','0']   # lt=1, gt=0
            f.write("".join(row) + "\n")

        # GT rows: first differing bit is 1/0
        for i in reversed(range(N)):
            row = ['-']*N + ['-']*N
            row[i] = '1'       # A[i]
            row[N + i] = '0'   # B[i]
            row += ['0','1']   # lt=0, gt=1
            f.write("".join(row) + "\n")

        f.write(".e\n")

if __name__ == "__main__":
    write_32bit_comparator()
    print(f"Espresso input written to '{filename}' (64 rows, 32-bit comparator)")
