from dataclasses import dataclass
from typing import List

@dataclass
class V_info:
   gate_num: int
   outputs: List[str]
   gates: List[str]
   inputs: List[str]
   input_num: int
   prod_num: int
   gate_name: str
   extra: str
   gate_type: str


def gate_structure_nand(num_inputs, my_v_info):
    ret_val = ""
    
    if (num_inputs == 1):
      input_list_1 = num_inputs * ["i"]
      input_list = my_v_info.inputs[my_v_info.input_num:((my_v_info.input_num)+num_inputs)]

      ret_val += (f"{my_v_info.gate_name}{num_inputs}({','.join(input_list_1)})")
      my_v_info.outputs.append(f"{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_{my_v_info.extra}_out")
      # my_v_info.gates.append(f"\tbuffer$ buffer_{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_{my_v_info.extra}({my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_{my_v_info.extra}_out,{','.join(input_list)});\n")
      my_v_info.gates.append(f"\tinv1$ {my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_{my_v_info.extra}({my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_{my_v_info.extra}_out, {','.join(input_list)});\n")
      return ret_val

    elif (num_inputs <= 4):
      input_list_1 = num_inputs * ["i"]
      input_list = my_v_info.inputs[my_v_info.input_num:((my_v_info.input_num)+num_inputs)]

      ret_val += (f"{my_v_info.gate_name}{num_inputs}({','.join(input_list_1)})")
      my_v_info.outputs.append(f"{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_{my_v_info.extra}_out")
      my_v_info.gates.append(f"\t{my_v_info.gate_type}{num_inputs}$ {my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_{my_v_info.extra}({my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_{my_v_info.extra}_out,{','.join(input_list)});\n")
      return ret_val
    else: # ASSUME 5 <= NUM_INPUTS <= 7
      my_v_info.outputs.append(f"{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_{my_v_info.extra}_out")
      my_v_info.gates.append(f"\t{my_v_info.gate_name}4$ {my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_{my_v_info.extra}({my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_{my_v_info.extra}_out,{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num+1}_{my_v_info.extra}_out,{my_v_info.inputs[my_v_info.input_num]},{my_v_info.inputs[my_v_info.input_num+1]},{my_v_info.inputs[my_v_info.input_num+2]});\n")
      my_v_info.gate_num = my_v_info.gate_num + 1
      my_v_info.input_num = my_v_info.input_num + 3

      my_v_info.gate_type = "and"

      ret_val += (f"{my_v_info.gate_name}4({gate_structure_nand(num_inputs - 3, my_v_info)},i,i,i)")
      return ret_val
    

num_inputs = 5
my_v_info = V_info(0, [], [], ["inp"+str(i) for i in range(num_inputs)], 0, 0, "nand", "0", "nand")   
print(gate_structure_nand(num_inputs, my_v_info))
for output in my_v_info.outputs:
   print("\twire " + output + ";\n")
for gate in my_v_info.gates:
   print(gate)