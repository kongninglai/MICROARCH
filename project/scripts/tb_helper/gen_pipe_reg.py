import re
import sys


CONTROL_PORTS = {"clk", "rst_n", "rst", "we"}


def strip_comments(text: str) -> str:
    text = re.sub(r"//.*", "", text)
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return text


def parse_width(width_str: str) -> int:
    if not width_str:
        return 1

    m = re.match(r"\[(\d+)\s*:\s*(\d+)\]", width_str.strip())
    if not m:
        raise ValueError(f"Unsupported width format: {width_str}")

    hi = int(m.group(1))
    lo = int(m.group(2))
    return abs(hi - lo) + 1


def parse_module(text: str):
    text = strip_comments(text)

    m = re.search(r"\bmodule\s+(\w+)\s*\((.*?)\)\s*;", text, re.S)
    if not m:
        raise ValueError("Cannot find module declaration.")

    module_name = m.group(1)
    port_block = m.group(2)

    items = [x.strip() for x in port_block.split(",") if x.strip()]

    ports = []
    current_dir = None
    current_width = ""

    for item in items:
        m_full = re.match(r"^(input|output)\s*(\[[^\]]+\])?\s*(\w+)$", item)
        if m_full:
            direction = m_full.group(1)
            width = m_full.group(2) or ""
            name = m_full.group(3)

            current_dir = direction
            current_width = width

            ports.append({
                "dir": direction,
                "width": width,
                "name": name,
            })
            continue
            
        m_name_only = re.match(r"^(\w+)$", item)
        if m_name_only and current_dir is not None:
            name = m_name_only.group(1)
            ports.append({
                "dir": current_dir,
                "width": current_width,
                "name": name,
            })
            continue

        raise ValueError(f"Unrecognized port declaration: {item}")

    return module_name, ports


def format_module_header(module_name: str, ports):
    lines = [f"module {module_name}("]
    for i, p in enumerate(ports):
        comma = "," if i != len(ports) - 1 else ""
        width = f"{p['width']} " if p["width"] else ""
        lines.append(f"    {p['dir']} {width}{p['name']}{comma}")
    lines.append(");")
    return "\n".join(lines)


def build_pipeline_reg_module(text: str) -> str:
    module_name, ports = parse_module(text)

    data_inputs = []
    outputs = []

    total_width = 0

    for p in ports:
        name = p["name"]
        width = parse_width(p["width"])

        if p["dir"] == "input" and name not in CONTROL_PORTS:
            data_inputs.append(p)
            total_width += width
        elif p["dir"] == "output":
            outputs.append(p)

    if total_width == 0:
        raise ValueError("No data inputs found to pack into pipeline register.")

    header = format_module_header(module_name, ports)

    din_names = ", ".join(p["name"] for p in data_inputs)
    out_names = ", ".join(p["name"] for p in outputs)

    reg_module_name = f"reg{total_width}e"
    inst_name = f"reg_{module_name}"

    body = []
    body.append(header)
    body.append("")
    body.append(f"wire [{total_width - 1}:0] reg_din, reg_q, reg_qb;")
    body.append(f"assign reg_din = {{{din_names}}};")
    body.append(f"assign {{{out_names}}} = reg_q;")
    body.append(
        f"{reg_module_name} {inst_name}(clk, reg_din, reg_q, reg_qb, rst_n, 1'b1, we);"
    )
    body.append("")
    body.append("endmodule")

    return "\n".join(body)


def main():
    if len(sys.argv) < 2:
        print("Usage: python gen_pipe_reg.py <input_file> [output_file]")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) >= 3 else None

    with open(input_file, "r", encoding="utf-8") as f:
        text = f.read()

    out = build_pipeline_reg_module(text)

    if output_file:
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(out)
    else:
        print(out)


if __name__ == "__main__":
    main()