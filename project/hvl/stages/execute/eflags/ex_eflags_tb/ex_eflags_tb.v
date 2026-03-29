module ex_eflags_tb;
initial begin
    $vcdplusfile("ex_eflags_tb.dump.vpd");
    $vcdpluson(0, ex_eflags_tb); 
end

reg clk;
reg rst_n;
reg [31:0] alu_eflags;
reg [31:0] shf_eflags;
reg [31:0] bsf_eflags;
reg [31:0] aaa_eflags;
reg [31:0] cmp_eflags;
reg [31:0] alu_eflags_mask;
reg [31:0] shf_eflags_mask;
reg [31:0] bsf_eflags_mask;
reg [31:0] aaa_eflags_mask;
reg [31:0] cmp_eflags_mask;
reg [2:0] sig_eflags_mux;
reg ldEFLAGS;
wire [31:0] eflags, eflags_bh;

ex_eflags dut (
    .clk(clk),
    .rst_n(rst_n),
    .alu_eflags(alu_eflags),
    .shf_eflags(shf_eflags),
    .bsf_eflags(bsf_eflags),
    .aaa_eflags(aaa_eflags),
    .cmp_eflags(cmp_eflags),
    .alu_eflags_mask(alu_eflags_mask),
    .shf_eflags_mask(shf_eflags_mask),
    .bsf_eflags_mask(bsf_eflags_mask),
    .aaa_eflags_mask(aaa_eflags_mask),
    .cmp_eflags_mask(cmp_eflags_mask),
    .sig_eflags_mux(sig_eflags_mux),
    .ldEFLAGS(ldEFLAGS),
    .eflags(eflags)
);

ex_eflags_bh dut_bh (
    .clk(clk),
    .rst_n(rst_n),
    .alu_eflags(alu_eflags),
    .shf_eflags(shf_eflags),
    .bsf_eflags(bsf_eflags),
    .aaa_eflags(aaa_eflags),
    .cmp_eflags(cmp_eflags),
    .alu_eflags_mask(alu_eflags_mask),
    .shf_eflags_mask(shf_eflags_mask),
    .bsf_eflags_mask(bsf_eflags_mask),
    .aaa_eflags_mask(aaa_eflags_mask),
    .cmp_eflags_mask(cmp_eflags_mask),
    .sig_eflags_mux(sig_eflags_mux),
    .ldEFLAGS(ldEFLAGS),
    .eflags(eflags_bh)
);

always #6 clk = ~clk;

task clear_inputs;
begin
        alu_eflags = 32'd0;
        shf_eflags = 32'd0;
        bsf_eflags = 32'd0;
        aaa_eflags = 32'd0;
        cmp_eflags = 32'd0;
        alu_eflags_mask = 32'd0;
        shf_eflags_mask = 32'd0;
        bsf_eflags_mask = 32'd0;
        aaa_eflags_mask = 32'd0;
        cmp_eflags_mask = 32'd0;
        sig_eflags_mux = 3'd0;
        ldEFLAGS = 1'b0;
end
endtask

task set_random_inputs;
begin
        alu_eflags = $random;
        shf_eflags = $random;
        bsf_eflags = $random;
        aaa_eflags = $random;
        cmp_eflags = $random;
        alu_eflags_mask = $random;
        shf_eflags_mask = $random;
        bsf_eflags_mask = $random;
        aaa_eflags_mask = $random;
        cmp_eflags_mask = $random;
        sig_eflags_mux = $random;
        ldEFLAGS = $random;
end
endtask

task print_outputs;
begin
        $display("eflags = %h", eflags);
end
endtask

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [31:0] out, out_exp;
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h\n", 
              $time, out_exp, out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin 
    clk = 1'b0;
    rst_n = 1'b0;
    clear_inputs();
    @(posedge clk);
    @(posedge clk);
    rst_n = 1'b1;

    set_random_inputs();
    repeat (1 << 12) begin
    #5; 
    check(eflags, eflags_bh);
    set_random_inputs();
  end
end
endmodule