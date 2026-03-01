## How to compile

### Project-Specific Instructions:

Structural Verilog modules belong in `project/hdl`.
- If desired, create a directory within `project/hdl` to hold your module.
  - For example, we have placed `xor3LL.v` into `project/hdl/local-lib/gates`.
  - `local-lib` is a local library of simple parts which may be commonly used.
  - `xor3LL.v` implements a 3-input XOR gate. `LL` means local library. This distinguishes our module from any other existing xor3 implementation.
- Once you've finalized the directory structure in `project/hdl`, please modify the directory structure in `project/hvl` to match this structure.
  - Instead of holding a structural Verilog file, `project/hvl` directories hold behavioral Verilog modules, testbenches, `master` files and simulation data.
  - In our example earlier, under `project/hvl/local-lib/gates`, there will be a folder for each module in the companion directory `project/hdl/local-lib/gates`. The folder for each module will be `<module_name>_tb`.
  - Most `<module_name>_tb` directories will contain the following:
    - `sim` directory: this is for simulation data.
    - `<module_name>_behav.v`: behavioral implementation (if needed) of the module. This is often convenient for testing structural modules. We recommend creating a behavioral module whose port list exactly matches its structural counterpart.
    - `<module_name>_tb.v`: testbench for this module. We recommend instantiating the structural and behavioral versions of the module, applying input patterns, and comparing the two modules' outputs. Whenever possible, exhaustively test the module (test all input patterns). If this is not possible (perhaps there are too many input combinations), a subset of input patterns may be tested. We recommend using the `$random` function of Verilog to generate patterns as well as manually applying special edge cases to the modules.
    - `master_<module_name>_tb`: this master file contains paths to every module that is needed for this testbench to run.

Here is the general workflow:
- Modify directory structure of `project/hdl` and `project/hvl` as described above.
- Implement your module in structural Verilog.
- Implement your module in behavioral Verilog.
- Write a testbench.
- Fill out a `master` file.
- `cd` into the `sim` directory (run `mkdir sim` if needed to create the directory)
- Run `vcs -full64 -v2005 -debug_all -f ../master*`
- Run `./simv`
- If you want to view waveforms, run `dve -full64 &`. We suggest just using `$display` statements in the testbench as much as possible. This can save unnecessary effort to scroll through a waveform.

### General Instructions from Dr. Patt's [Tutorial](https://users.ece.utexas.edu/~patt/26s.382N/tools/vcs_manual.html):

Note: this workflow violates the rules listed above. We must run these commands in the `sim` directory to avoid cluttering the workspace.
```
Vcs -full64 -v2005 -debug_all -f master
./simv
dve -full64 &
```
