# State Machine Generator

The purpose of this script is to turn a truth table (representing a Moore finite state machine) into a syntactically and functionally correct structural Verilog module which implements the table. The script was written in Python. The structural Verilog may only use standard cells provided in the ECE382N.19 [library](https://users.ece.utexas.edu/~patt/26s.382N/lib/list_of_modules.txt).

## Steps to run from a fresh Linux environment
1. Download the Espresso [executable](https://users.ece.utexas.edu/~patt/26s.382N/tools/espresso.linux) for Linux machines. Espresso is a two-level logic minimizer tool developed in UC Berkeley.
2. Place the executable `espresso.linux` into your home directory.
3. In your environment, run `cd; ls` and ensure that `espresso.linux` is there.
4. Run `chmod +x espresso.linux` so that you may run the executable.
5. Run `cd; sudo apt update; sudo apt install -y python3` to make sure you can use `python3`.
6. Run `cd; python3 --version` to make sure the installation is complete.
7. Download my source code files `moore_log_gen.py` and `gate_structure.py`.
8. Place the two source code files into your home directory.
9. Run `cd; ls` and ensure that `moore_log_gen.py` and `gate_structure.py` are there.
10. Create a new truth table file of your choosing in your home directory. For example, `cd; touch example_statemachine.in; vim example_statemachine.in`.
11. Fill out the truth table with your desired input and output behavior. The next section will describe the required format for this table.
12. Once you are done writing to the truth table file, exit your editor (e.g. `:wq`).
13. Run `cd; ./espresso.linux example_statemachine.in`.
14. Use the output of the previous command to fix any errors in your truth table. If any input lines are ignored, the most common cause is that you did not set the number of inputs or outputs correctly.
15. If the output looks right, you are good to pipe it into my script. Run `cd; ./espresso.linux example_statemachine.in | python3 moore_log_gen.py`
16. Run `cd; ls` and, if your truth table format was correct, you'll see a new file called `moore_logic_gen.v`.
17. You can now run `cd; cat moore_logic_gen.v` to see the Verilog. It will be a correct Verilog module which compiles.

## Truth Table Format
Following is an example of a truth table file `example_statemachine.in`:
```bash
.s 000
.n 3
.i 9
.o 8
.ilb Q2 Q1 Q0 RD WR MAX_RD MAX_BRST MAX_WR MAX_WRTOT
.ob D2 D1 D0 CE OE WR_out CT DATAN

00000---- 00011101
00001---- 00111101
00010---- 10011101
00011---- 00011101

001--0--- 00100111
001--1--- 01000111

010------ 01100100

011---0-- 01111110
011---1-- 00011110

100----0- 10001011
100----1- 10101011

101-----0 10111111
101-----1 00011111
```

`.s 000` means the reset state of the state machine will be state `000`.

`.n 3` means that the state needs 3 bits to be represented.

`.i 9` means there are nine 1-bit inputs, INCLUDING the 3-bit current state `Q[2:0]`. Name them appropriately. In this example, they are `Q2`, `Q1`, `Q0`, `RD`, `WR`, `MAX_RD`, `MAX_BRST`, `MAX_WR`, and `MAX_WRTOT`.

`.o 8` means there are eight 1-bit outputs, INCLUDING the 3-bit next state. Name them appropriately. In this example, they are `D2`, `D1`, `D0`, `CE`, `OE`, `WR_out`, `CT`, and `DATAN`.

`.ilb Q2 Q1 Q0 RD WR MAX_RD MAX_BRST MAX_WR MAX_WRTOT` lists the inputs' names.

`.ob D2 D1 D0 CE OE WR_out CT DATAN` lists the outputs' names.

The rest of the file is a truth table. `0` denotes a logical 0, `1` denotes a logical 1, and a `-` denotes a don't care.

Separate the inputs and outputs in each row of the truth table with a space. In this example, you should have nine truth values to the left of the space and eight truth values to the right of the space.

The first row of the truth table means that if the current state `Q[2:0]` is `000` (i.e. `Q2`, `Q1`, and `Q0` are all `0`), and the inputs `RD` and `WR` are both `0`, then the next state `D[2:0]` should be `000`, and the outputs for the CURRENT state are `CE = 1`, `OE = 1`, `WR_out = 1`, `CT = 0`, and `DATAN = 1`.
