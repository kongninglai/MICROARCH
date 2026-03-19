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

    input_ports = []
    output_ports = []

    for p in ports:

        name = p["name"]
        width = p["width"]
        direction = p["dir"]

        width_str = f" {width}" if width else ""

        if direction == "input":

            decl.append(f"reg{width_str} {name};")

            if name not in ["clk", "rst", "rst_n"]:
                input_ports.append(p)

                bits = width_to_bits(width)

                if bits == 1:
                    clear.append(f"        {name} = 1'b0;")
                else:
                    clear.append(f"        {name} = {bits}'d0;")

        else:
            decl.append(f"wire{width_str} {name};")
            output_ports.append(p)

    inst.append(f"{module_name} dut (")

    for i, p in enumerate(ports):

        comma = "," if i < len(ports) - 1 else ""

        inst.append(f"    .{p['name']}({p['name']}){comma}")

    inst.append(");")

    # clear task
    clear_task = []
    clear_task.append("task clear_inputs;")
    clear_task.append("begin")
    clear_task.extend(clear)
    clear_task.append("end")
    clear_task.append("endtask")

    # set_inputs task
    set_task = []
    set_task.append("task set_inputs;")

    # task arguments
    args = []
    for p in input_ports:
        width = p["width"]
        name = p["name"]

        width_str = f"{width} " if width else ""
        args.append(f"input {width_str}{name}_i")

    set_task.append("(" + ", ".join(args) + ");")
    set_task.append("begin")

    for p in input_ports:
        name = p["name"]
        set_task.append(f"        {name} = {name}_i;")

    set_task.append("end")
    set_task.append("endtask")

    # print_outputs task
    print_task = []
    print_task.append("task print_outputs;")
    print_task.append("begin")

    for p in output_ports:
        name = p["name"]
        print_task.append(
            f'        $display("{name} = %h", {name});'
        )

    print_task.append("end")
    print_task.append("endtask")

    return (
        "\n".join(decl)
        + "\n\n"
        + "\n".join(inst)
        + "\n\n"
        + "\n".join(clear_task)
        + "\n\n"
        + "\n".join(set_task)
        + "\n\n"
        + "\n".join(print_task)
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
