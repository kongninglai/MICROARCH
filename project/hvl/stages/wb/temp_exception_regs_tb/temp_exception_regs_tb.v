module  temp_exception_regs_tb;

initial begin
  // $vcdplusfile("temp_exception_regs_tb.dump.vpd");
  // $vcdpluson(0, temp_exception_regs_tb); 
end


reg clk;
reg rst_n;
reg [15:0] from_wb_temp_cs;
reg [31:0] from_wb_temp_eip;
reg [1:0]  from_wb_temp_exception;
reg        from_wb_flush;

wire [15:0] to_ex_tempCS, to_ex_tempCS_bh;
wire [31:0] to_ex_tempEIP, to_ex_tempEIP_bh;

wire [47:0] dout, dout_exp;
assign dout = {to_ex_tempCS, to_ex_tempEIP};
assign dout_exp = {to_ex_tempCS_bh, to_ex_tempEIP_bh};

temp_exception_regs_bh REF(
    .clk(clk),
    .rst_n(rst_n),
    .from_wb_temp_cs(from_wb_temp_cs),
    .from_wb_temp_eip(from_wb_temp_eip),
    .from_wb_temp_exception(from_wb_temp_exception),
    .from_wb_flush(from_wb_flush),
    .to_ex_tempCS(to_ex_tempCS_bh),
    .to_ex_tempEIP(to_ex_tempEIP_bh)
); 

temp_exception_regs DUT(
    .clk(clk),
    .rst_n(rst_n),
    .from_wb_temp_cs(from_wb_temp_cs),
    .from_wb_temp_eip(from_wb_temp_eip),
    .from_wb_temp_exception(from_wb_temp_exception),
    .from_wb_flush(from_wb_flush),
    .to_ex_tempCS(to_ex_tempCS),
    .to_ex_tempEIP(to_ex_tempEIP)
); 

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end
integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [47:0] out, out_exp;
  input [8*80:1]    msg; // string
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %0t: %0s. out_exp = %h, out = %h\n", 
              $time, msg, out_exp, out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

task apply_reset;
  begin
    rst_n = 0;

    from_wb_temp_cs = 16'b0;
    from_wb_temp_eip = 32'b0;
    from_wb_temp_exception = 2'b0;
    from_wb_flush = 1'b0;

    #10
    rst_n = 1;
  end
endtask


initial begin
  apply_reset();
  
  repeat (1 << 8) begin
    @(negedge clk);
    from_wb_temp_cs = $random;
    from_wb_temp_eip = $random;
    from_wb_temp_exception = $random;
    from_wb_flush = $random;

    @(posedge clk);
    #1
    check(dout, dout_exp, "Random test");
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule