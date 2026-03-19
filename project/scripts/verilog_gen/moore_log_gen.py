import sys
from gate_structure import *
import re

with open("moore_logic_gen.v", "w") as f:
  for line in sys.stdin:
    cleaned_line = line.strip()

    if not cleaned_line:
      continue

    if (cleaned_line.startswith(".s ")):
      init_state = cleaned_line.split()[1]
      # print("Init State =", init_state)

    elif (cleaned_line.startswith(".n ")):
      state_bits = cleaned_line.split()[1]
      # print("State bits =", state_bits)
    
    elif (cleaned_line.startswith(".i ")):
      num_inputs = cleaned_line.split()[1]
      # print("Inputs =", num_inputs)

    elif (cleaned_line.startswith(".o ")):
      num_outputs = cleaned_line.split()[1]
      # print("Outputs =", num_outputs)

    elif (cleaned_line.startswith(".ilb")):
      input_list = cleaned_line.split()[1:]
      # print("Input list =", input_list)

    elif (cleaned_line.startswith(".ob")):
      output_list = cleaned_line.split()[1:]
      # print("Output list =", output_list)

    elif (cleaned_line.startswith(".p")):
      num_products = cleaned_line.split()[1]
      # print("# products= ", num_products)
      f.write(f"/* AUTO GENERATED MOORE LOGIC */\n")
      f.write(f"module moore_logic_gen(rst,clk,{','.join(input_list[int(state_bits):])},{','.join(output_list[int(state_bits):])});\n")
      f.write(f"\n\t/* I/Os */\n")
      f.write(f"\tinput rst, clk, {','.join(input_list[int(state_bits):])};\n")
      f.write(f"\toutput {','.join(output_list[int(state_bits):])};\n")
      f.write(f"\twire {','.join(input_list[:int(state_bits)])};\n")
      f.write(f"\twire {','.join(output_list[:int(state_bits)])};\n")

      inverted_list = set()
      output_contributions = [[] for i in range(int(num_outputs))]
      product_inputs = [[] for i in range(int(num_products))]

      # print("Output Contributions =", output_contributions)
      # print("Product Inputs =", product_inputs)
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
          output_contributions[i].append(f"and_{product_num}_0_out")

      product_num += 1



  f.write(f"\n\t/* Inverters */\n")
  inp_num = 0
  for input_name in inverted_list:
      f.write(f"\twire {input_name}_bar;\n")
      if input_name not in input_list[:int(state_bits)]:
        f.write(f"\tinv1$ inv_{inp_num}({input_name}_bar, {input_name});\n")
      inp_num += 1

  f.write(f"\n\t/* Product Expressions */\n")
  for i in range(int(num_products)):
    my_v_info = V_info(0, [], [], product_inputs[i], 0, i, "and")   
    gate_structure(len(product_inputs[i]), my_v_info)
    for output in my_v_info.outputs:
      f.write(f"\twire {output};\n")
    if (len(product_inputs[i]) == 0):
      f.write(f"\tassign {output} = 1'b1;\n")
      # f.write(f"\tbuffer$ buffer_empty_{i}({output}, 1'b1);\n")
    else:
      for gate in my_v_info.gates:
        f.write(gate)
  
  
  f.write(f"\n\t/* Sum Expressions */\n")
  for i in range(int(num_outputs)):
    my_v_info = V_info(0, [], [], output_contributions[i], 0, i, "or")   
    gate_structure(len(output_contributions[i]), my_v_info)
    if (len(output_contributions[i]) == 0):
      f.write(f"\tassign {output_list[i]} = 1'b0;\n")
      # f.write(f"\tbuffer$ buffer_empty_cont_{i}({output_list[i]}, 1'b0);\n")
    else:
      for output in my_v_info.outputs:
        if (int(output.split('_')[2]) != 0):
          f.write(f"\twire {output};\n")

      for gate in my_v_info.gates:
        pattern = r'or_\d+_0_out'
        new_gate = re.sub(pattern, output_list[i], gate, count=1)
        # print(f"Gate = {gate}, NewGate = {new_gate}")
        f.write(new_gate)

  
  f.write(f"\n\t/* State Flip Flops */\n")
  state_index = int(state_bits) - 1
  for i in range(int(state_bits)):
    if int(init_state[state_index] == '1'):
      f.write(f"\tdff$ dff_{i}(clk, D{i}, Q{i}, Q{i}_bar, 1'b1, rst);\n")
    else:
      f.write(f"\tdff$ dff_{i}(clk, D{i}, Q{i}, Q{i}_bar, rst, 1'b1);\n")
    state_index -= 1

  f.write("\nendmodule\n\r")
  
  # print("Product Inputs =", product_inputs)
  # print("Inverted List =", inverted_list)
  # print("Output Contributions =", output_contributions)
