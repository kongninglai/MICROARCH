# Optimized NAND Gate Module Documentation

Please see `comb_log_gen_nand.py` and `moore_log_gen_nand.py` for optimized version of the Verilog code generators.

These use NAND gates as much as possible instead of AND / OR gates.

## Caveat

The output of the optimized modules is only correct if the following 2 conditions are met: 
1. EVERY PRODUCT TERM has 7 or fewer input contributions
2. EVERY SUM TERM has 7 or fewer product contributions

## How to identify the caveat

In this example, I'll use the state machine generator.

When you run `cd; ./espresso.linux example_statemachine.in | python3 moore_log_gen_nand.py`, the script will do 2 things:
1. Print some debug info + the actual Verilog code to `stdout`.
2. Create a file called `moore_logic_gen.v` in the same directory with only the Verilog code.

To fix any possible bugs with the Verilog code, you must scroll up in the `stdout` output until you see something like this:
```
Product 12
Product 11
Product 5
Product 5
Product 5
Product 4
Product 4
Product 4
Product 3
Product 4
Product 4
Product 4
Product 3
Product 5
Product 5
Product 5
Output 2
Output 4
Output 7
Output 1
Output 1
Output 1
Output 1
Output 1
Output 1
Output 1
Output 1
```
This information tells you the number of contributions for each product and sum term. If ANY of these numbers are 8 or greater, YOU NEED TO MODIFY THE SCRIPT'S VERILOG OUTPUT.

## How to modify the Verilog output to fix the bug

Following this example, scroll down in the generated Verilog code until you find the problem-causing product or sum term. In our case, the problems are with the first two product terms, which are delineated with a `/* Product Expressions */` comment. (Sum terms have a `/* Sum Expressions */` comment).

Note that the wire numbering convention is `<term #>_<gate #>_<prod or sum>`. Whenever the gate number in this convention is `0`, this is a true final product or a true final sum term. The last number is a `0` for product terms and a `1` for sum terms. For example, So, `nand_0_0_0_out` is the very first (zero-indexed) product term, and `nand_5_0_1` is the SIXTH (again, zero-indexed) sum term.

Here is the code for the first two problem-causing product terms (`nand_0_0_0_out`, `nand_1_0_0_out`):

```
wire nand_0_0_0_out;
wire nand_0_1_0_out;
wire nand_0_2_0_out;
wire nand_0_3_0_out;
nand4$ nand_0_0_0(nand_0_0_0_out,nand_0_1_0_out,Q2_bar,Q1_bar,Q0_bar);
nand4$ nand_0_1_0(nand_0_1_0_out,nand_0_2_0_out,NOBODY_BUSY,DC_MEM_RD_RQ_bar,DC_DMA_RD_RQ_bar);
nand4$ nand_0_2_0(nand_0_2_0_out,nand_0_3_0_out,DC_KB_RD_RQ_bar,DC_MEM_WR_RQ_bar,DC_DMA_WR_RQ_bar);
and3$ nand_0_3_0(nand_0_3_0_out,DC_KB_WR_RQ_bar,IC_MEM_RD_RQ_bar,DMA_MEM_WR_RQ);
wire nand_1_0_0_out;
wire nand_1_1_0_out;
wire nand_1_2_0_out;
wire nand_1_3_0_out;
nand4$ nand_1_0_0(nand_1_0_0_out,nand_1_1_0_out,Q2_bar,Q1_bar,Q0_bar);
nand4$ nand_1_1_0(nand_1_1_0_out,nand_1_2_0_out,NOBODY_BUSY,DC_MEM_RD_RQ_bar,DC_DMA_RD_RQ_bar);
nand4$ nand_1_2_0(nand_1_2_0_out,nand_1_3_0_out,DC_KB_RD_RQ_bar,DC_MEM_WR_RQ_bar,DC_DMA_WR_RQ_bar);
and2$ nand_1_3_0(nand_1_3_0_out,DC_KB_WR_RQ_bar,IC_MEM_RD_RQ);
```

The ONLY fix you need to do is delete the `n` that begins each line which does NOT produce the final product or sum term. In this case, the fix would be as shown below, with the changed lines marked by a comment at the end of the line:
```
wire nand_0_0_0_out;
wire nand_0_1_0_out;
wire nand_0_2_0_out;
wire nand_0_3_0_out;
nand4$ nand_0_0_0(nand_0_0_0_out,nand_0_1_0_out,Q2_bar,Q1_bar,Q0_bar);
and4$ nand_0_1_0(nand_0_1_0_out,nand_0_2_0_out,NOBODY_BUSY,DC_MEM_RD_RQ_bar,DC_DMA_RD_RQ_bar);      /* Change */
and4$ nand_0_2_0(nand_0_2_0_out,nand_0_3_0_out,DC_KB_RD_RQ_bar,DC_MEM_WR_RQ_bar,DC_DMA_WR_RQ_bar);  /* Change */
and3$ nand_0_3_0(nand_0_3_0_out,DC_KB_WR_RQ_bar,IC_MEM_RD_RQ_bar,DMA_MEM_WR_RQ);
wire nand_1_0_0_out;
wire nand_1_1_0_out;
wire nand_1_2_0_out;
wire nand_1_3_0_out;
nand4$ nand_1_0_0(nand_1_0_0_out,nand_1_1_0_out,Q2_bar,Q1_bar,Q0_bar);
and4$ nand_1_1_0(nand_1_1_0_out,nand_1_2_0_out,NOBODY_BUSY,DC_MEM_RD_RQ_bar,DC_DMA_RD_RQ_bar);      /* Change */
and4$ nand_1_2_0(nand_1_2_0_out,nand_1_3_0_out,DC_KB_RD_RQ_bar,DC_MEM_WR_RQ_bar,DC_DMA_WR_RQ_bar);  /* Change */
and2$ nand_1_3_0(nand_1_3_0_out,DC_KB_WR_RQ_bar,IC_MEM_RD_RQ);
```