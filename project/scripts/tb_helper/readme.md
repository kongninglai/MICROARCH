## Testbench Generate Helper

Given a Verilog module declaration, the script will:
- Parse all input and output ports

- Declare
    - input → reg
    - output → wire

- Instantiate the module as dut

- Automatically connect all ports

- Generate a clear_inputs task that resets all inputs to zero

### Usage
```
python tb_helper.py module.txt

// or redirect to a txt file:
python tb_helper.py module.txt > tb.out
```

### Example
**Input File**
```
module regfile_seg (
    input clk,
    input rst_n,

    input [2:0] segrd0_idx,
    input [2:0] segrd1_idx,
    output [15:0] segrd0_data,
    output [15:0] segrd1_data
);
```

**Output**
```
reg clk;
reg rst_n;

reg  [2:0] segrd0_idx;
reg  [2:0] segrd1_idx;

wire [15:0] segrd0_data;
wire [15:0] segrd1_data;

regfile_seg dut (
    .clk(clk),
    .rst_n(rst_n),
    .segrd0_idx(segrd0_idx),
    .segrd1_idx(segrd1_idx),
    .segrd0_data(segrd0_data),
    .segrd1_data(segrd1_data)
);

task clear_inputs;
begin
    segrd0_idx = 3'd0;
    segrd1_idx = 3'd0;
end
endtask
```

