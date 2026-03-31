module mem_to_ex_tb;

initial begin
  // $vcdplusfile("mem_to_ex_tb.dump.vpd");
  // $vcdpluson(0, mem_to_ex_tb); 
end

localparam WIDTH = 684;
localparam CYCLE_TIME = 10.0;

reg clk, rst_n, we;
reg [WIDTH-1:0] din;
wire [WIDTH-1:0] q_out;
reg [WIDTH-1:0] out_exp;

always #(CYCLE_TIME/2.0) clk = ~clk;

mem_to_ex DUT (
    .clk(clk), .rst_n(rst_n), .we(we),
    .from_mem_control_sigs(din[683:631]),
    .from_mem_dstidA(din[630:628]),
    .from_mem_dstidB(din[627:625]),
    .from_mem_srcregA(din[624:593]),
    .from_mem_srcregB(din[592:561]),
    .from_mem_srcregC(din[560:529]),
    .from_mem_srcSREG(din[528:513]),
    .from_mem_MMA(din[512:449]),
    .from_mem_MMB(din[448:385]),
    .from_mem_target_cs(din[384:369]),
    .from_mem_load_result(din[368:305]),
    .from_mem_inc_esp(din[304:273]),
    .from_mem_dec_esp(din[272:241]),
    .from_mem_imm(din[240:209]),
    .from_mem_rel_eip(din[208:177]),
    .from_mem_store_is_io_line_0(din[176]),
    .from_mem_store_addr_line_0(din[175:165]),
    .from_mem_store_mask_line_0(din[164:149]),
    .from_mem_store_queue_alloc_line_0(din[148]),
    .from_mem_store_addr_line_1(din[147:137]),
    .from_mem_store_mask_line_1(din[136:121]),
    .from_mem_store_queue_alloc_line_1(din[120]),
    .from_mem_store_data_shf_amt(din[119:115]),
    .from_mem_cs(din[114:99]),
    .from_mem_oeip(din[98:67]),
    .from_mem_ieip(din[66:35]),
    .from_mem_pred_eip(din[34:3]),
    .from_mem_exception(din[2:1]),
    .from_mem_valid(din[0]),

    .to_ex_control_sigs(q_out[683:631]),
    .to_ex_dstidA(q_out[630:628]),
    .to_ex_dstidB(q_out[627:625]),
    .to_ex_srcregA(q_out[624:593]),
    .to_ex_srcregB(q_out[592:561]),
    .to_ex_srcregC(q_out[560:529]),
    .to_ex_srcSREG(q_out[528:513]),
    .to_ex_MMA(q_out[512:449]),
    .to_ex_MMB(q_out[448:385]),
    .to_ex_target_cs(q_out[384:369]),
    .to_ex_load_result(q_out[368:305]),
    .to_ex_inc_esp(q_out[304:273]),
    .to_ex_dec_esp(q_out[272:241]),
    .to_ex_imm(q_out[240:209]),
    .to_ex_rel_eip(q_out[208:177]),
    .to_ex_store_is_io_line_0(q_out[176]),
    .to_ex_store_addr_line_0(q_out[175:165]),
    .to_ex_store_mask_line_0(q_out[164:149]),
    .to_ex_store_queue_alloc_line_0(q_out[148]),
    .to_ex_store_addr_line_1(q_out[147:137]),
    .to_ex_store_mask_line_1(q_out[136:121]),
    .to_ex_store_queue_alloc_line_1(q_out[120]),
    .to_ex_store_data_shf_amt(q_out[119:115]),
    .to_ex_cs(q_out[114:99]),
    .to_ex_oeip(q_out[98:67]),
    .to_ex_ieip(q_out[66:35]),
    .to_ex_pred_eip(q_out[34:3]),
    .to_ex_exception(q_out[2:1]),
    .to_ex_valid(q_out[0])
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [WIDTH-1:0] out, out_exp;
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h\n", 
              $time, out_exp, out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  clk = 0; rst_n = 0; we = 1; din = 0; out_exp = 0;
  #(CYCLE_TIME);
  rst_n = 1;
  
  repeat (1 << 12) begin
    din = { {$random}, {$random}, {$random}, {$random}, {$random}, 
            {$random}, {$random}, {$random}, {$random}, {$random}, 
            {$random}, {$random}, {$random}, {$random}, {$random}, 
            {$random}, {$random}, {$random}, {$random}, {$random}, 
            {$random}, {$random} };
    out_exp = din;
    #(CYCLE_TIME);
    check(q_out, out_exp);
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
  $finish;
end

endmodule