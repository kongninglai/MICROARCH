#!/bin/bash
set -e

/usr/bin/python3.11 /home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/readmemh.py
/usr/bin/python3.11 /home/ecelrc/students/aak3265/MICROARCH/project/scripts/verification/gen_test_cases.py
/usr/bin/python3.11 /home/ecelrc/students/aak3265/MICROARCH/project/scripts/verification/main.py > /home/ecelrc/students/aak3265/MICROARCH/project/hvl/top/backend_top/backend_top_tb/results_script.txt