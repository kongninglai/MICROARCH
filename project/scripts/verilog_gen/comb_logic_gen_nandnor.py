import sys
from gate_structure import *
import re

with open("comb_logic_gen.v", "w") as f:
    for line in sys.stdin:
        cleaned_line = line.strip()

        if not cleaned_line:
            continue
        
        if (cleaned_line.startswith(".i ")):
            num_inputs = cleaned_line.split()[1]

        elif (cleaned_line.startswith(".o ")):
            num_outputs = cleaned_line.split()[1]

        elif (cleaned_line.startswith(".ilb")):
            input_list = cleaned_line.split()[1:]

        elif (cleaned_line.startswith(".ob")):
            output_list = cleaned_line.split()[1:]

        elif (cleaned_line.startswith(".p")):
            num_products = cleaned_line.split()[1]
            f.write(f"/* AUTO GENERATED NAND-NAND LOGIC */\n")
            # Note: Using standard inverters (delay 0.15) and NANDs (delay 0.2-0.25)
            f.write(f"module comb_logic_gen({','.join(input_list)},{','.join(output_list)});\n")
            f.write(f"\n\t/* I/Os */\n")
            f.write(f"\tinput {','.join(input_list)};\n")
            f.write(f"\toutput {','.join(output_list)};\n")

            inverted_list = set()
            output_contributions = [[] for i in range(int(num_outputs))]
            product_inputs = [[] for i in range(int(num_products))]
            product_num = 0
        
        elif (cleaned_line.startswith(".e")):
            break

        else:
            product_expression = cleaned_line.split()[0]
            for i in range(len(product_expression)):
                if (product_expression[i] == '0'):
                    inverted_list.add(input_list[i])
                    product_inputs[product_num].append(input_list[i] + "_bar")
                elif (product_expression[i] == '1'):
                    product_inputs[product_num].append(input_list[i])
            
            sum_expression = cleaned_line.split()[1]
            for i in range(len(sum_expression)):
                if (sum_expression[i] == '1'):
                    # The output of the Level 1 NAND becomes the input for Level 2
                    output_contributions[i].append(f"nand_{product_num}_0_out")

            product_num += 1

    f.write(f"\n\t/* Inverters (Delay: 0.15) */\n")
    inp_num = 0
    for input_name in sorted(inverted_list):
        f.write(f"\twire {input_name}_bar;\n")
        f.write(f"\tinv1$ inv_{inp_num}({input_name}_bar, {input_name});\n")
        inp_num += 1

    f.write(f"\n\t/* Level 1: Product Terms (NAND Gates) */\n")
    # nand2/3 delay: 0.2, nand4 delay: 0.25
    for i in range(int(num_products)):
        my_v_info = V_info(0, [], [], product_inputs[i], 0, i, "nand")   
        gate_structure(len(product_inputs[i]), my_v_info)
        for output in my_v_info.outputs:
            f.write(f"\twire {output};\n")
        if (len(product_inputs[i]) == 0):
            f.write(f"\tbuffer$ buffer_empty_{i}({output}, 1'b1);\n")
        else:
            for gate in my_v_info.gates:
                f.write(gate)
    
    f.write(f"\n\t/* Level 2: Sum Terms (NAND Gates - SOP Equivalence) */\n")
    for i in range(int(num_outputs)):
        # NAND-NAND implementation converts the "OR" stage to a "NAND" stage
        my_v_info = V_info(0, [], [], output_contributions[i], 0, i, "nand")   
        gate_structure(len(output_contributions[i]), my_v_info)
        if (len(output_contributions[i]) == 0):
            f.write(f"\tbuffer$ buffer_empty_cont_{i}({output_list[i]}, 1'b0);\n")
        else:
            for output in my_v_info.outputs:
                if (int(output.split('_')[2]) != 0):
                    f.write(f"\twire {output};\n")

            for gate in my_v_info.gates:
                # Use regex to map internal NAND outputs to module output ports
                pattern = r'nand_\d+_0_out'
                new_gate = re.sub(pattern, output_list[i], gate, count=1)
                f.write(new_gate)

    f.write("\nendmodule\n\r")