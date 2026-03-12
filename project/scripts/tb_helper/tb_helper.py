import re
import sys


def parse_module_ports(verilog_text):

    m = re.search(r'\bmodule\s+(\w+)\s*\((.*?)\)\s*;', verilog_text, re.S)
    if not m:
        raise ValueError("Cannot find module declaration.")

    module_name = m.group(1)
    port_block = m.group(2)

    port_block = re.sub(r'//.*', '', port_block)

    raw_items = [x.strip() for x in port_block.split(',') if x.strip()]

    ports = []

    for item in raw_items:

        m = re.match(r'(input|output)\s*(\[[^\]]+\])?\s*(\w+)', item)

        if not m:
            raise ValueError(f"Bad port line: {item}")

        direction = m.group(1)
        width = m.group(2) or ""
        name = m.group(3)

        ports.append({
            "dir": direction,
            "width": width,
            "name": name
        })

    return module_name, ports


def width_to_bits(width):

    if width == "":
        return 1

    m = re.match(r'\[(\d+):(\d+)\]', width)

    hi = int(m.group(1))
    lo = int(m.group(2))

    return abs(hi - lo) + 1


def build_tb_helper(verilog_text):

    module_name, ports = parse_module_ports(verilog_text)

    decl = []
    inst = []
    clear = []

    for p in ports:

        name = p["name"]
        width = p["width"]
        direction = p["dir"]

        width_str = f" {width}" if width else ""

        if direction == "input":
            decl.append(f"reg{width_str} {name};")

            if name not in ["clk", "rst", "rst_n"]:

                bits = width_to_bits(width)

                if bits == 1:
                    clear.append(f"        {name} = 1'b0;")
                else:
                    clear.append(f"        {name} = {bits}'d0;")

        else:
            decl.append(f"wire{width_str} {name};")

    inst.append(f"{module_name} dut (")

    for i, p in enumerate(ports):

        comma = "," if i < len(ports) - 1 else ""

        inst.append(f"    .{p['name']}({p['name']}){comma}")

    inst.append(");")

    task = []
    task.append("task clear_inputs;")
    task.append("begin")
    task.extend(clear)
    task.append("end")
    task.append("endtask")

    return (
        "\n".join(decl)
        + "\n\n"
        + "\n".join(inst)
        + "\n\n"
        + "\n".join(task)
    )


def main():

    if len(sys.argv) < 2:
        print("Usage: python tb_helper.py module.v")
        return

    with open(sys.argv[1]) as f:
        text = f.read()

    print(build_tb_helper(text))


if __name__ == "__main__":
    main()