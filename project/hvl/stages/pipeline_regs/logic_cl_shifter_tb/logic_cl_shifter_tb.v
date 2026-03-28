module logic_cl_shifter_tb;

initial begin
  $vcdplusfile("logic_cl_shifter_tb.dump.vpd");
  $vcdpluson(0, logic_cl_shifter_tb); 
end

localparam WIDTH = 9;

reg   [WIDTH-1:0] in_long;
reg   [127:0] cl;

wire  [247:0] cl_aligned, cl_aligned_exp;
wire  [4:0]   wr_cl_byte_cnt, wr_cl_byte_cnt_exp;

wire  [3:0] eip_lower_bits   = in_long[8:5];
wire  [4:0] tail_ptr         = in_long[4:0];

localparam CYCLE_TIME = 2;

logic_cl_shifter DUT(
  .eip_lower_bits(eip_lower_bits),
  .cl(cl),
  .tail_ptr(tail_ptr),
  .cl_aligned(cl_aligned),
  .wr_cl_byte_cnt(wr_cl_byte_cnt)
);

logic_cl_shifter_behav REF(
  .eip_lower_bits(eip_lower_bits),
  .cl(cl),
  .tail_ptr(tail_ptr),
  .cl_aligned(cl_aligned_exp),
  .wr_cl_byte_cnt(wr_cl_byte_cnt_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [247:0] cl_aligned, cl_aligned_exp;
  input [4:0] wr_cl_byte_cnt, wr_cl_byte_cnt_exp;
  if ((cl_aligned !== cl_aligned_exp) || (wr_cl_byte_cnt !== wr_cl_byte_cnt_exp)) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. cl_exp = %h, cl = %h, cnt_exp = %h, cnt = %h\n",
              $time, cl_aligned_exp, cl_aligned, wr_cl_byte_cnt_exp, wr_cl_byte_cnt);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

integer i;

initial begin
  for (i = 0; i < (1 << WIDTH) + 1; i = i + 1) begin
    in_long = i[WIDTH-1:0];
    cl = {$random, $random, $random, $random};
    #(CYCLE_TIME);
    check(cl_aligned, cl_aligned_exp, wr_cl_byte_cnt, wr_cl_byte_cnt_exp);
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule