module  regfile_mmx_tb;

initial begin
  $vcdplusfile("regfile_mmx_tb.dump.vpd");
  $vcdpluson(0, regfile_mmx_tb); 
end

localparam WIDTH = 64;
localparam DEPTH = 8;
localparam IDX_SIZE = 3;
reg clk;
reg rst_n;

reg  [IDX_SIZE-1:0] rd_reg0_idx;
reg  [IDX_SIZE-1:0] rd_reg1_idx;

wire [WIDTH-1:0]    rd_reg0_data_bh;
wire [WIDTH-1:0]    rd_reg1_data_bh;

wire [WIDTH-1:0]    rd_reg0_data;
wire [WIDTH-1:0]    rd_reg1_data;

reg  [IDX_SIZE-1:0] wr_reg0_idx;
reg  [WIDTH-1:0]    wr_reg0_data;
reg                 wr0_en;

regfile_mmx_bh #(
  .WIDTH(WIDTH),
  .DEPTH(DEPTH),
  .IDX_SIZE(IDX_SIZE)
) dut_bh (
    .clk(clk),
    .rst_n(rst_n),

    .rd_reg0_idx(rd_reg0_idx),
    .rd_reg1_idx(rd_reg1_idx),
    .rd_reg0_data(rd_reg0_data_bh),
    .rd_reg1_data(rd_reg1_data_bh),

    .wr_reg0_idx(wr_reg0_idx),
    .wr_reg0_data(wr_reg0_data),
    .wr0_en(wr0_en)
);

regfile_mmx #(
  .WIDTH(WIDTH)
) dut (
    .clk(clk),
    .rst_n(rst_n),

    .rd_reg0_idx(rd_reg0_idx),
    .rd_reg1_idx(rd_reg1_idx),
    .rd_reg0_data(rd_reg0_data),
    .rd_reg1_data(rd_reg1_data),

    .wr_reg0_idx(wr_reg0_idx),
    .wr_reg0_data(wr_reg0_data),
    .wr0_en(wr0_en)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end
integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [WIDTH-1:0] out, out_exp;
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

    rd_reg0_idx = 0;
    rd_reg1_idx = 0;

    wr0_en = 0;
    wr_reg0_idx  = 0;
    wr_reg0_data = 0;

    repeat (5) @(posedge clk);
    rst_n = 1;
    @(posedge clk);
  end
endtask

task single_write_test;
  begin
    wr0_en = 1'b1;
    wr_reg0_idx = 3'b001;
    wr_reg0_data = 64'h1111_1111_1111_1111;
    @(posedge clk);
    wr0_en = 1'b0;
    rd_reg0_idx = 3'b001;
    #1;
    check(rd_reg0_data_bh, 64'h1111_1111_1111_1111, "single write to register 1 and read behavioral check");
    check(rd_reg0_data, rd_reg0_data_bh, "single write to register 1 and read");
    @(posedge clk);
  end
endtask

task consecutive_write_test;
  begin
    wr0_en = 1'b1;
    wr_reg0_idx = 3'b010;
    wr_reg0_data = 64'h2222_2222_2222_2222;
    @(posedge clk);
    wr0_en = 1'b1;
    wr_reg0_idx = 3'b011;
    wr_reg0_data = 64'h3333_3333_3333_3333;
    @(posedge clk);
    wr0_en = 1'b0;
    rd_reg0_idx = 3'b010;  
    rd_reg1_idx = 3'b011;
    #1;
    check(rd_reg0_data_bh, 64'h2222_2222_2222_2222, "consecutively write to register 2 and read behavioral check");
    check(rd_reg1_data_bh, 64'h3333_3333_3333_3333, "consecutively write to register 3 and read behavioral check");
    check(rd_reg0_data, rd_reg0_data_bh, "consecutively write to register 2 and read");
    check(rd_reg1_data, rd_reg1_data_bh, "consecutively write to register 3 and read");
    @(posedge clk);
  end
endtask

task bypass_raw_test;
  begin
    wr0_en = 1'b1;
    wr_reg0_idx = 3'b100;
    wr_reg0_data = 64'h4444_4444_4444_4444;

    rd_reg0_idx = 3'b100;  
    #1;
    check(rd_reg0_data_bh, 64'h4444_4444_4444_4444, "write to register 4 and read in the same cycle behavioral check");
    check(rd_reg0_data, rd_reg0_data_bh, "write to register 4 and read in the same cycle");
    @(posedge clk);
    wr0_en = 1'b0;
    @(posedge clk);
  end
endtask

initial begin
  apply_reset();
  single_write_test();
  consecutive_write_test();
  bypass_raw_test();

  @(negedge clk);
  rd_reg0_idx = $random;   
  rd_reg1_idx = $random;

  wr0_en       = $random;
  wr_reg0_idx  = $random;
  wr_reg0_data = $random;
  
  repeat (1 << 8) begin
    @(negedge clk);
    check(rd_reg0_data, rd_reg0_data_bh, "Random test register 0");
    check(rd_reg1_data, rd_reg1_data_bh, "Random test register 1");

    @(negedge clk);
    wr0_en       = 0;

    @(negedge clk);
    rd_reg0_idx = $random;   
    rd_reg1_idx = $random;
    wr0_en       = $random;
    wr_reg0_idx  = $random;
    wr_reg0_data = $random;
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule