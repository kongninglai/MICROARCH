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


def gate_structure(num_inputs, my_v_info):
    ret_val = ""
    
    if (num_inputs == 1):
      input_list_1 = num_inputs * ["i"]
      input_list = my_v_info.inputs[my_v_info.input_num:((my_v_info.input_num)+num_inputs)]

      ret_val += (f"{my_v_info.gate_name}{num_inputs}({','.join(input_list_1)})")
      my_v_info.outputs.append(f"{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out")
      my_v_info.gates.append(f"\tbuffer$ buffer_{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}({my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out,{','.join(input_list)});\n")
      return ret_val

    elif (num_inputs <= 4):
      input_list_1 = num_inputs * ["i"]
      input_list = my_v_info.inputs[my_v_info.input_num:((my_v_info.input_num)+num_inputs)]

      ret_val += (f"{my_v_info.gate_name}{num_inputs}({','.join(input_list_1)})")
      my_v_info.outputs.append(f"{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out")
      my_v_info.gates.append(f"\t{my_v_info.gate_name}{num_inputs}$ {my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}({my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out,{','.join(input_list)});\n")
      return ret_val
    else:
      if (num_inputs >= 5 and num_inputs <= 7):
        my_v_info.outputs.append(f"{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out")
        my_v_info.gates.append(f"\t{my_v_info.gate_name}4$ {my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}({my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out,{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num+1}_out,{my_v_info.inputs[my_v_info.input_num]},{my_v_info.inputs[my_v_info.input_num+1]},{my_v_info.inputs[my_v_info.input_num+2]});\n")
        my_v_info.gate_num = my_v_info.gate_num + 1
        my_v_info.input_num = my_v_info.input_num + 3

        ret_val += (f"{my_v_info.gate_name}4({gate_structure(num_inputs - 3, my_v_info)},i,i,i)")
        return ret_val
      elif (num_inputs >= 8 and num_inputs <= 10):
        my_v_info.outputs.append(f"{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out")
        my_v_info.gates.append(f"\t{my_v_info.gate_name}4$ {my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}({my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out,{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num+1}_out,{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num+2}_out,{my_v_info.inputs[my_v_info.input_num]},{my_v_info.inputs[my_v_info.input_num+1]});\n")
        my_v_info.gate_num = my_v_info.gate_num + 1
        my_v_info.input_num = my_v_info.input_num + 2

        my_v_info.outputs.append(f"{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out")
        my_v_info.gates.append(f"\t{my_v_info.gate_name}4$ {my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}({my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out,{my_v_info.inputs[my_v_info.input_num]},{my_v_info.inputs[my_v_info.input_num+1]},{my_v_info.inputs[my_v_info.input_num+2]},{my_v_info.inputs[my_v_info.input_num+3]});\n")
        my_v_info.gate_num = my_v_info.gate_num + 1
        my_v_info.input_num = my_v_info.input_num + 4

        ret_val += (f"{my_v_info.gate_name}4({my_v_info.gate_name}4(i,i,i,i),{gate_structure(num_inputs - 6, my_v_info)},i,i)")
        return ret_val
      elif (num_inputs >= 11 and num_inputs <= 13):
        my_v_info.outputs.append(f"{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out")
        my_v_info.gates.append(f"\t{my_v_info.gate_name}4$ {my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}({my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out,{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num+1}_out,{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num+2}_out,{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num+3}_out,{my_v_info.inputs[my_v_info.input_num]});\n")
        my_v_info.gate_num = my_v_info.gate_num + 1
        my_v_info.input_num = my_v_info.input_num + 1

        for i in range(2):
          my_v_info.outputs.append(f"{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out")
          my_v_info.gates.append(f"\t{my_v_info.gate_name}4$ {my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}({my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out,{my_v_info.inputs[my_v_info.input_num]},{my_v_info.inputs[my_v_info.input_num+1]},{my_v_info.inputs[my_v_info.input_num+2]},{my_v_info.inputs[my_v_info.input_num+3]});\n")
          my_v_info.gate_num = my_v_info.gate_num + 1
          my_v_info.input_num = my_v_info.input_num + 4

        ret_val += (f"{my_v_info.gate_name}4({my_v_info.gate_name}4(i,i,i,i),{my_v_info.gate_name}4(i,i,i,i),{gate_structure(num_inputs - 9, my_v_info)},i)")
        return ret_val
      elif (num_inputs >= 14 and num_inputs <= 16):
        my_v_info.outputs.append(f"{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out")
        my_v_info.gates.append(f"\t{my_v_info.gate_name}4$ {my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}({my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out,{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num+1}_out,{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num+2}_out,{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num+3}_out,{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num+4}_out);\n")
        my_v_info.gate_num = my_v_info.gate_num + 1

        for i in range(3):
          my_v_info.outputs.append(f"{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out")
          my_v_info.gates.append(f"\t{my_v_info.gate_name}4$ {my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}({my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out,{my_v_info.inputs[my_v_info.input_num]},{my_v_info.inputs[my_v_info.input_num+1]},{my_v_info.inputs[my_v_info.input_num+2]},{my_v_info.inputs[my_v_info.input_num+3]});\n")
          my_v_info.gate_num = my_v_info.gate_num + 1
          my_v_info.input_num = my_v_info.input_num + 4

        ret_val += (f"{my_v_info.gate_name}4({my_v_info.gate_name}4(i,i,i,i),{my_v_info.gate_name}4(i,i,i,i),{my_v_info.gate_name}4(i,i,i,i),{gate_structure(num_inputs - 12, my_v_info)})")
        return ret_val
      else:
        my_v_info.outputs.append(f"{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out")
        my_v_info.gates.append(f"\t{my_v_info.gate_name}4$ {my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}({my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out,{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num+1}_out,{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num+2}_out,{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num+3}_out,{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num+4}_out);\n")
        my_v_info.gate_num = my_v_info.gate_num + 1

        for i in range(3):
          my_v_info.outputs.append(f"{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out")
          my_v_info.gates.append(f"\t{my_v_info.gate_name}4$ {my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}({my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out,{my_v_info.inputs[my_v_info.input_num]},{my_v_info.inputs[my_v_info.input_num+1]},{my_v_info.inputs[my_v_info.input_num+2]},{my_v_info.inputs[my_v_info.input_num+3]});\n")
          my_v_info.gate_num = my_v_info.gate_num + 1
          my_v_info.input_num = my_v_info.input_num + 4
        
        my_v_info.outputs.append(f"{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out")
        my_v_info.gates.append(f"\t{my_v_info.gate_name}4$ {my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}({my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num}_out,{my_v_info.inputs[my_v_info.input_num]},{my_v_info.inputs[my_v_info.input_num+1]},{my_v_info.inputs[my_v_info.input_num+2]},{my_v_info.gate_name}_{my_v_info.prod_num}_{my_v_info.gate_num+1}_out);\n")
        my_v_info.gate_num = my_v_info.gate_num + 1
        my_v_info.input_num = my_v_info.input_num + 3

        ret_val += (f"{my_v_info.gate_name}4({my_v_info.gate_name}4(i,i,i,i),{my_v_info.gate_name}4(i,i,i,i),{my_v_info.gate_name}4(i,i,i,i),{my_v_info.gate_name}4(i,i,i,{gate_structure(num_inputs - 15, my_v_info)}))")
        return ret_val

num_inputs = 1
my_v_info = V_info(0, [], [], ["inp"+str(i) for i in range(num_inputs)], 0, 0, "and")   
# print(gate_structure(num_inputs, my_v_info))
# for output in my_v_info.outputs:
#    print("\twire " + output + ";\n")
# for gate in my_v_info.gates:
#    print(gate)