module fetch_buffer_tail_tb;

initial begin
  $vcdplusfile("fetch_buffer_tail_tb.dump.vpd");
  $vcdpluson(0, fetch_buffer_tail_tb);
  $vcdpluson(0, fetch_buffer_tail_tb.dut);
end

reg clk;
reg rst_bar;
reg [3:0] from_de_instr_len;
reg [3:0] from_de_eip_lower_bits;
reg from_f_icache_valid;
reg from_de_valid_and_load_rr;
reg from_wb_flush;
reg from_ex_flush;
reg from_f_cl_pf;
reg [127:0] from_f_cache_line, from_f_cache_line_prev, saved_from_f_cache_line_prev;
reg from_de_eip_redirection;

wire [127:0] to_de_outbytes;
reg  [127:0] to_de_outbytes_prev;
wire to_de_pf_expn;

localparam CYCLE_TIME = 10.0;

integer FAILURES = 0;
integer SUCCESSES = 0;

fetch_buffer dut(
  .clk(clk),
  .rst_bar(rst_bar),
  .from_de_instr_len(from_de_instr_len),
  .from_de_eip_lower_bits(from_de_eip_lower_bits),
  .from_f_icache_valid(from_f_icache_valid),
  .from_de_valid_and_load_rr(from_de_valid_and_load_rr),
  .from_wb_flush(from_wb_flush),
  .from_ex_flush(from_ex_flush),
  .from_f_cl_pf(from_f_cl_pf),
  .from_f_cache_line(from_f_cache_line),
  .from_de_eip_redirection(from_de_eip_redirection),
  .to_de_outbytes(to_de_outbytes),
  .to_de_pf_expn(to_de_pf_expn),
  .tail_ptr(),
  .global_wr_en()
);

integer i;

always begin
  clk = 0;
  forever #(CYCLE_TIME/2.0) clk = ~clk;
end

always @(posedge clk) begin
  from_f_cache_line_prev <= from_f_cache_line;
  to_de_outbytes_prev <= to_de_outbytes;
  from_f_cache_line <= {$random, $random, $random, $random};
end

task disable_all;
begin
  from_de_instr_len <= 0;
  from_de_eip_lower_bits <= 0;
  from_f_icache_valid <= 0;
  from_de_valid_and_load_rr <= 0;
  from_wb_flush <= 0;
  from_ex_flush <= 0;
  from_f_cl_pf <= 0;
  from_de_eip_redirection <= 0;
end
endtask

task check;
  input [127:0] outbytes_exp;
  input [4:0] tail_ptr_exp;
  input exception_exp;
begin
  if (to_de_outbytes != outbytes_exp ||
      dut.tail_ptr !== tail_ptr_exp ||
      to_de_pf_expn != exception_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t: outbytes exp=%h got %h || tail_ptr exp=%h got %h", $time, outbytes_exp, to_de_outbytes, tail_ptr_exp, dut.tail_ptr);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

initial begin
  rst_bar = 1'b0;
  disable_all();
  #(1.5 * CYCLE_TIME);
  rst_bar = 1'b1;
  #(20 * CYCLE_TIME);
  check(128'd0, 5'd0, 1'bX);

  /* Skip 3 bytes, initial load of 16 - 3 = 13 bytes (0xD) */
  from_de_eip_lower_bits <= 4'd3;
  from_f_icache_valid <= 1;
  #(CYCLE_TIME);
  from_de_eip_lower_bits <= 0;
  from_f_icache_valid <= 0;
  #(CYCLE_TIME); check({24'hXXXXXX, from_f_cache_line_prev[127:24]}, 5'hD, 1'b0);
  #(20 * CYCLE_TIME);

  /* DE consumes 10 bytes, 3 bytes left */
  from_de_instr_len <= 4'd10;
  from_de_valid_and_load_rr <= 1;
  #(CYCLE_TIME);
  from_de_instr_len <= 0;
  from_de_valid_and_load_rr <= 0;
  #(CYCLE_TIME); check({104'hXXXXXX, to_de_outbytes_prev[103:80]}, 5'h3, 1'b0);

  /* Add cache line, tail_ptr = 3 + 16 = 19 (0x13) */
  #(20 * CYCLE_TIME);
  from_f_icache_valid <= 1;
  #(CYCLE_TIME);
  from_f_icache_valid <= 0;
  #(CYCLE_TIME);
  saved_from_f_cache_line_prev <= from_f_cache_line_prev;
  check({from_f_cache_line_prev[103:0], to_de_outbytes_prev[23:0]}, 5'h13, 1'b0);

  /* DE Consumes 4 bytes, 15 bytes left (0xF) */
  #(20 * CYCLE_TIME);
  from_de_instr_len <= 4'd4;
  from_de_valid_and_load_rr <= 1;
  #(CYCLE_TIME);
  from_de_instr_len <= 0;
  from_de_valid_and_load_rr <= 0;
  #(CYCLE_TIME); check({8'hXX, saved_from_f_cache_line_prev[127:8]}, 5'hF, 1'b0);

  /* Add cache line AND CONSUME 15 BYTES (tail_ptr = 16 = 0x10) */
  #(20 * CYCLE_TIME);
  from_f_icache_valid <= 1;
  from_de_instr_len <= 4'd15;
  from_de_valid_and_load_rr <= 1;
  #(CYCLE_TIME);
  from_f_icache_valid <= 0;
  from_de_instr_len <= 0;
  from_de_valid_and_load_rr <= 0;
  #(CYCLE_TIME); check(from_f_cache_line_prev, 5'h10, 1'b0);

  /* Consume 15 bytes (tail_ptr = 1) */
  #(20 * CYCLE_TIME);
  from_de_instr_len <= 4'd15;
  from_de_valid_and_load_rr <= 1;
  #(CYCLE_TIME);
  from_de_instr_len <= 4'd0;
  from_de_valid_and_load_rr <= 0;
  #(CYCLE_TIME); check({{120{1'bX}}, to_de_outbytes_prev[127:120]}, 5'h01, 1'b0);

  /* Consume 1 byte (tail_ptr = 0) */
  #(20 * CYCLE_TIME);
  from_de_instr_len <= 4'd1;
  from_de_valid_and_load_rr <= 1;
  #(CYCLE_TIME);
  from_de_instr_len <= 4'd0;
  from_de_valid_and_load_rr <= 0;
  #(CYCLE_TIME); check({128{1'bX}}, 5'h0, 1'bX);

  /* ICACHE line with page fault (tail_ptr = 0x10 = 16) */
  #(20 * CYCLE_TIME);
  from_f_icache_valid <= 1;
  from_f_cl_pf <= 1;
  #(CYCLE_TIME);
  from_f_icache_valid <= 0;
  from_f_cl_pf <= 0;
  #(CYCLE_TIME); check(from_f_cache_line_prev[127:0], 5'h10, 1'b1);

  /* Consume 8 bytes (tail_ptr = 8) */
  #(20 * CYCLE_TIME);
  from_de_instr_len <= 4'd8;
  from_de_valid_and_load_rr <= 1;
  #(CYCLE_TIME);
  from_de_instr_len <= 4'd0;
  from_de_valid_and_load_rr <= 0;
  #(CYCLE_TIME); check({{64{1'bX}}, to_de_outbytes_prev[127:64]}, 5'h8, 1'b1);

  /* Consume 8 bytes (tail_ptr = 0) */
  #(20 * CYCLE_TIME);
  from_de_instr_len <= 4'd8;
  from_de_valid_and_load_rr <= 1;
  #(CYCLE_TIME);
  from_de_instr_len <= 4'd0;
  from_de_valid_and_load_rr <= 0;
  #(CYCLE_TIME); check({128{1'bX}}, 5'h0, 1'bX);

  /* ICACHE line (tail_ptr = 0x10 = 16) */
  #(20 * CYCLE_TIME);
  from_f_icache_valid <= 1;
  #(CYCLE_TIME);
  from_f_icache_valid <= 0;
  from_f_cl_pf <= 0;
  #(CYCLE_TIME); check(from_f_cache_line_prev[127:0], 5'h10, 1'b0);

  from_wb_flush <= 1;
  #(CYCLE_TIME); from_wb_flush <= 0; #(CYCLE_TIME); check({128{1'bX}}, 5'h0, 1'bX);

  /* ICACHE line (tail_ptr = 0x10 = 16) */
  #(20 * CYCLE_TIME);
  from_f_icache_valid <= 1;
  #(CYCLE_TIME);
  from_f_icache_valid <= 0;
  from_f_cl_pf <= 0;
  #(CYCLE_TIME); check(from_f_cache_line_prev[127:0], 5'h10, 1'b0);

  from_ex_flush <= 1;
  #(CYCLE_TIME); from_ex_flush <= 0; #(CYCLE_TIME); check({128{1'bX}}, 5'h0, 1'bX);

  /* ICACHE line (tail_ptr = 0x10 = 16) */
  #(20 * CYCLE_TIME);
  from_f_icache_valid <= 1;
  #(CYCLE_TIME);
  from_f_icache_valid <= 0;
  from_f_cl_pf <= 0;
  #(CYCLE_TIME); check(from_f_cache_line_prev[127:0], 5'h10, 1'b0);

  from_de_eip_redirection <= 1;
  from_de_valid_and_load_rr <= 1;
  #(CYCLE_TIME); from_de_eip_redirection<= 0; from_de_valid_and_load_rr <= 0; #(CYCLE_TIME); check({128{1'bX}}, 5'h0, 1'bX);

  
        
  #(20 * CYCLE_TIME);
  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
  $finish;

end

endmodule