#!/bin/bash
set -e

/usr/bin/python3.11 /home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/readmemh.py
/usr/bin/python3.11 /home/ecelrc/students/var2427/MICROARCH/project/scripts/verification/gen_test_cases.py
/usr/bin/python3.11 /home/ecelrc/students/var2427/MICROARCH/project/scripts/verification/gen_eip_idx_map.py
/usr/bin/python3.11 /home/ecelrc/students/var2427/MICROARCH/project/scripts/verification/main.py > /home/ecelrc/students/var2427/MICROARCH/project/hvl/top/backend_top/backend_top_tb/results_script.txt

cd sim
./simv
cd ..

if diff results_script.txt results_cmp.txt > diff_output.txt; then
    echo "
    
    PASS: RESULTS MATCH
    
    "
else
    cat diff_output.txt
fi