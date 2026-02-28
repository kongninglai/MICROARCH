# Combinational Logic Generator

The purpose of this script is to turn a truth table into a syntactically and functionally correct structural Verilog module which implements the table. The script was written in Python. The structural Verilog may only use standard cells provided in the ECE382N.19 [library](https://users.ece.utexas.edu/~patt/26s.382N/lib/list_of_modules.txt).

## Steps to run from a fresh Linux environment
1. Download the Espresso [executable](https://users.ece.utexas.edu/~patt/26s.382N/tools/espresso.linux) for Linux machines. Espresso is a two-level logic minimizer tool developed in UC Berkeley.
2. Place the executable `espresso.linux` into your home directory.
3. In your environment, run `cd; ls` and ensure that `espresso.linux` is there.
4. Run `chmod +x espresso.linux` so that you may run the executable.
5. Run `cd; sudo apt update; sudo apt install -y python3` to make sure you can use `python3`.
6. Run `cd; python3 --version` to make sure the installation is complete.
7. Download my source code files `comb_log_gen.py` and `gate_structure.py`.
8. Place the two source code files into your home directory.
9. Run `cd; ls` and ensure that `comb_log_gen.py` and `gate_structure.py` are there.
10. Create a new truth table file of your choosing in your home directory. For example, `cd; touch example_comb.in; vim example_comb.in`.
11. Fill out the truth table with your desired input and output behavior. The next section will describe the required format for this table.
12. Once you are done writing to the truth table file, exit your editor (e.g. `:wq`).
13. Run `cd; ./espresso.linux example_comb.in`.
14. Use the output of the previous command to fix any errors in your truth table. If any input lines are ignored, the most common cause is that you did not set the number of inputs or outputs correctly.
15. If the output looks right, you are good to pipe it into my script. Run `cd; ./espresso.linux example_comb.in | python3 moore_log_gen.py`
16. Run `cd; ls` and, if your truth table format was correct, you'll see a new file called `comb_logic_gen.v`.
17. You can now run `cd; cat comb_logic_gen.v` to see the Verilog. It will be a correct Verilog module which compiles.
~
## Truth Table Format
Following is an example of a truth table file `example_comb.in`:
```bash
.i 4		
.o 3		
.ilb INP3 INP2 INP1 INP0
.ob OUT2 OUT1 OUT0

00-- 101
0100 001
0101 110
011- ---
1--- 000
```

`.i 4` means there are four 1-bit inputs. Name them appropriately. In this example, they are `INP3`, `INP2`, `INP1`, and `INP0`.

`.o 3` means there are three 1-bit outputs. Name them appropriately. In this example, they are `OUT2`, `OUT1`, and `OUT0`.

`.ilb INP3 INP2 INP1 INP0` lists the inputs' names.

`.ob OUT2 OUT1 OUT0` lists the outputs' names.

The rest of the file is a truth table. `0` denotes a logical 0, `1` denotes a logical 1, and a `-` denotes a don't care.

Separate the inputs and outputs in each row of the truth table with a space. In this example, you should have four truth values to the left of the space and three truth values to the right of the space.

The first row of the truth table means that if `INP3` and `INP2` are `0`, then `OUT2` should be `1`, `OUT1` should be `0`, and `OUT0` should be `1`,
