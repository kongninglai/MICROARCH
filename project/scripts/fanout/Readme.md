# Instructions to Fix Fanout Violations

1. `cd` to the directory in `project/hvl` with your TOP LEVEL FILE (not necessary, but recommended)
2. `mkdir fanout; cd fanout`
3. `rm -r ./*; module load synopsys/syn; design_vision -no_gui;`
4. Construct a complete file list to compile your top-level module. The top-level `.v` file should be listed first. Don't include any `lib` files directly. Instead, include `~/MICROARCH/project/scripts/fanout/junk.v`. Most of the file list should resemble the `master` file for the top level module's testbench. Your command should look like:
```
analyze -format Verilog {<top level file> <~/MICROARCH/project/scripts/fanout/junk.v> <all other files separated by spaces or new lines>}; elaborate <top level module name>; current_design <top level module name>; set target_library ""; set link_library "*"; link;
```
Example:
```
analyze -format Verilog {analyze -format Verilog {~/MICROARCH/project/hdl/stages/fetch/stage_fetch_a.v ~/MICROARCH/project/scripts/fanout/junk.v  
~/MICROARCH/project/hdl/stages/fetch/fetch_pointer.v
~/MICROARCH/project/hdl/local-lib/comparators/big_eq.v
~/MICROARCH/project/hdl/local-lib/comparators/big_neq.v
~/MICROARCH/project/hdl/local-lib/gates/big_and.v 
~/MICROARCH/project/hdl/local-lib/regs/reg_n.v 
~/MICROARCH/project/hdl/local-lib/gates/big_or.v 
~/MICROARCH/project/hdl/local-lib/gates/xor3LL.v 
~/MICROARCH/project/hdl/local-lib/adders/gen_prop.v
~/MICROARCH/project/hdl/local-lib/adders/gen_prop_2.v
~/MICROARCH/project/hdl/local-lib/adders/PA_4b.v
~/MICROARCH/project/hdl/local-lib/adders/PA_32b.v
~/MICROARCH/project/hdl/local-lib/adders/big_decrement.v
~/MICROARCH/project/hdl/local-lib/adders/big_increment.v
~/MICROARCH/project/hdl/stages/decoder/pf_expn.v
~/MICROARCH/project/hdl/local-lib/muxes/mux2_32.v
~/MICROARCH/project/hdl/local-lib/muxes/mux4_32.v
~/MICROARCH/project/hdl/local-lib/muxes/mux4_48.v
~/MICROARCH/project/hdl/local-lib/muxes/mux8.v
~/MICROARCH/project/hdl/local-lib/muxes/mux8_8.v
~/MICROARCH/project/hdl/local-lib/muxes/mux8_32.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16_16.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16_32.v
~/MICROARCH/project/hdl/local-lib/muxes/mux16_48.v
}; elaborate stage_fetch_a; current_design stage_fetch_a; set target_library ""; set link_library "*"; link;}; elaborate full_cache; current_design full_cache; set target_library ""; set link_library "*"; link;
```
5. Copy-paste the contents of `fanout_script.tcl` in this folder into the shell. This will write a list of all fanout violations to a file in the new `fanout` folder called `fanout_violations.txt`. It lists the fanout of each offending wire so you can use the appropriate buffer.
6. Useful tip: `bufferHInv16$` has the same delay as `inv1$`. So if your original wire has a fanout of, say `12`, and it is driven by an `or4$`, you can actually just pair a `nor4$` with a `bufferHInv16$` to solve fanout without changing the delay.