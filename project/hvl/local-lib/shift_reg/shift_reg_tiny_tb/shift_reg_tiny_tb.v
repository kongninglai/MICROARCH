module shift_reg_tiny_tb;

initial begin
  $vcdplusfile("shift_reg_tiny_tb.dump.vpd");
  $vcdpluson(0, shift_reg_tiny_tb);
  $vcdpluson(0, shift_reg_tiny_tb.dut.q);
end

reg clk;
reg rst_n;
reg shift;
reg flush;
reg [3:0] instr_len;
reg [30:0] inbytes;
reg global_wr_en;
reg [4:0] wr_cl_byte_cnt;
reg [30:0] wr_en;

wire [15:0] outbytes;
wire [4:0] tail_ptr;
wire ready;

wire [15:0] outbytes_exp;
wire [4:0] tail_ptr_exp;
wire ready_exp;

localparam CYCLE_TIME = 10.0;

shift_reg_tiny dut(
    .clk(clk),
    .rst_n(rst_n),
    .shift(shift),
    .flush(flush),
    .instr_len(instr_len),
    .inbytes(inbytes),
    .global_wr_en(global_wr_en),
    .wr_cl_byte_cnt(wr_cl_byte_cnt),
    .wr_en(wr_en),
    .outbytes(outbytes),
    .tail_ptr(tail_ptr),
    .ready(ready)
);

shift_reg_tiny_behav ref(
    .clk(clk),
    .rst_n(rst_n),
    .shift(shift),
    .flush(flush),
    .instr_len(instr_len),
    .inbytes(inbytes),
    .global_wr_en(global_wr_en),
    .wr_cl_byte_cnt(wr_cl_byte_cnt),
    .wr_en(wr_en),
    .outbytes(outbytes_exp),
    .tail_ptr(tail_ptr_exp),
    .ready(ready_exp)
);

integer FAILURES = 0;
integer SUCCESSES = 0;

initial begin
  clk = 0;
  forever #(CYCLE_TIME/2.0) clk = ~clk;
end

reg [30:0] mask;

always @(posedge clk) begin
  if (tail_ptr !== tail_ptr_exp ||
      ready !== ready_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t: tail_ptr exp=%h got %h", $time, tail_ptr_exp, tail_ptr);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
  if (tail_ptr_exp !== 5'd0) begin
    mask = (32'b1 << (tail_ptr_exp)) - 1'b1;
    if ((outbytes & mask) !== (outbytes_exp & mask)) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE (outbytes) AT TIME %t: outbytes exp=%h got=%h", $time, outbytes_exp, outbytes);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
end

always @(posedge clk) begin
  inbytes <= {$random, $random};
end

task disable_all;
begin
  shift <= 0;
  flush <= 0;
  instr_len <= 0;
  global_wr_en <= 0;
  wr_cl_byte_cnt <= 0;
  wr_en <= 0;
end
endtask

task write_full_line;
begin
  if (ready_exp === 1'b1) begin
    global_wr_en <= 1'b1;
    wr_en <= ({{15{1'b0}}, {16{1'b1}}} << tail_ptr_exp);
    wr_cl_byte_cnt <= 5'd16;
    #(CYCLE_TIME);
    disable_all();
  end else begin
    $display("\n\n*************************************ILLEGAL WRITE. FIX THE TESTBENCH.*************************************\n\n");
  end
end
endtask

task write_partial_line;
  input integer num_bytes;
  reg [31:0] mask;
begin
  if (tail_ptr_exp === 5'd0) begin
    global_wr_en <= 1'b1;
    mask = (32'hFFFF_FFFF >> (32 - num_bytes));
    wr_en <= (mask << tail_ptr_exp);
    wr_cl_byte_cnt <= num_bytes[4:0];
    #(CYCLE_TIME);
    disable_all();
  end else begin
    $display("\n\n*************************************ILLEGAL PARTIAL WRITE at %t. FIX THE TESTBENCH.*************************************\n\n", $time);
  end
end
endtask

task shift_the_buffer;
  input integer num_bytes;
begin
  if (tail_ptr_exp !== 5'd0) begin
    shift <= 1'b1;
    instr_len <= num_bytes[3:0];
    #(CYCLE_TIME);
    disable_all();
  end else begin
    $display("\n\n*************************************ILLEGAL SHIFT. FIX THE TESTBENCH.*************************************\n\n");
  end
end
endtask

task read_randomly_until_empty;
  integer amount;
begin
  while (tail_ptr_exp !== 5'd0) begin
    amount = $random & 32'h0000000F;
    if (amount >= tail_ptr_exp) begin
      amount = tail_ptr_exp;
    end
    shift_the_buffer(amount);
    #(CYCLE_TIME);
  end
end
endtask

task read_and_write_randomly_until_empty;
  integer amount;
begin
  while (tail_ptr_exp !== 5'd0) begin
    amount = $random & 32'h0000000F;
    if (amount > tail_ptr_exp) begin
      amount = tail_ptr_exp;
    end
    if (ready_exp === 1'b1 && ($random % 4 == 0)) begin
      global_wr_en <= 1'b1;
      wr_en <= ({{15{1'b0}}, {16{1'b1}}} << tail_ptr_exp);
      wr_cl_byte_cnt <= 5'd16;
    end
    shift_the_buffer(amount);
    #(CYCLE_TIME);
  end
end
endtask

integer i;

initial begin
  rst_n <= 0;
  disable_all();
  #(1.5 * CYCLE_TIME);
  rst_n <= 1;
  #(10 * CYCLE_TIME);

  for (i = 1; i <= 16; i = i + 1) begin
    write_partial_line(i);
    #(CYCLE_TIME);
    read_randomly_until_empty();
  end

  #(20 * CYCLE_TIME);
  repeat (1 << 8) begin
    write_full_line();
    #(CYCLE_TIME);
    read_and_write_randomly_until_empty();
  end

  #(100 * CYCLE_TIME);

  write_partial_line(6);
  #(CYCLE_TIME);
  global_wr_en <= 1'b1;
  wr_en <= ({{15{1'b0}}, {16{1'b1}}} << tail_ptr_exp);
  wr_cl_byte_cnt <= 5'd16;
  shift <= 1'b1;
  instr_len <= 4'd2;
  #(CYCLE_TIME);
  global_wr_en <= 1'b0;
  wr_en <= 31'd0;
  wr_cl_byte_cnt <= 5'd0;
  shift <= 1'b1;
  instr_len <= 4'd1;
  #(CYCLE_TIME);
  shift <= 1'b1;
  instr_len <= 4'd3;
  #(CYCLE_TIME);
  shift <= 1'b1;
  instr_len <= 4'd1;
  #(CYCLE_TIME); disable_all(); #(CYCLE_TIME);
  global_wr_en <= 1'b1;
  wr_en <= ({{15{1'b0}}, {16{1'b1}}} << tail_ptr_exp);
  wr_cl_byte_cnt <= 5'd16;
  shift <= 1'b1;
  instr_len <= 4'd1;
  #(CYCLE_TIME);
  disable_all();
  #(CYCLE_TIME);
  read_randomly_until_empty();

  write_partial_line(6);
  #(CYCLE_TIME);
  global_wr_en <= 1'b1;
  wr_en <= ({{15{1'b0}}, {16{1'b1}}} << tail_ptr_exp);
  wr_cl_byte_cnt <= 5'd16;
  shift <= 1'b1;
  instr_len <= 4'd2;
  #(CYCLE_TIME);
  global_wr_en <= 1'b0;
  wr_en <= 31'd0;
  wr_cl_byte_cnt <= 5'd0;
  shift <= 1'b1;
  instr_len <= 4'd1;
  #(CYCLE_TIME);
  shift <= 1'b1;
  instr_len <= 4'd3;
  #(CYCLE_TIME);
  shift <= 1'b1;
  instr_len <= 4'd2;
  #(CYCLE_TIME); disable_all(); #(CYCLE_TIME);
  global_wr_en <= 1'b1;
  wr_en <= ({{15{1'b0}}, {16{1'b1}}} << tail_ptr_exp);
  wr_cl_byte_cnt <= 5'd16;
  shift <= 1'b0;
  instr_len <= 4'd0;
  #(CYCLE_TIME);
  disable_all();
  #(CYCLE_TIME);
  read_randomly_until_empty();

  write_partial_line(6);
  #(CYCLE_TIME);
  global_wr_en <= 1'b1;
  wr_en <= ({{15{1'b0}}, {16{1'b1}}} << tail_ptr_exp);
  wr_cl_byte_cnt <= 5'd16;
  shift <= 1'b1;
  instr_len <= 4'd2;
  #(CYCLE_TIME);
  global_wr_en <= 1'b0;
  wr_en <= 31'd0;
  wr_cl_byte_cnt <= 5'd0;
  shift <= 1'b1;
  instr_len <= 4'd1;
  #(CYCLE_TIME);
  shift <= 1'b1;
  instr_len <= 4'd3;
  #(CYCLE_TIME);
  shift <= 1'b1;
  instr_len <= 4'd1;
  #(CYCLE_TIME); disable_all(); #(CYCLE_TIME);
  global_wr_en <= 1'b1;
  wr_en <= ({{15{1'b0}}, {16{1'b1}}} << tail_ptr_exp);
  wr_cl_byte_cnt <= 5'd16;
  shift <= 1'b0;
  instr_len <= 4'd0;
  #(CYCLE_TIME);
  disable_all();
  #(CYCLE_TIME);
  flush <= 1;
  #(CYCLE_TIME);
  flush <= 0;
  
  #(10 * CYCLE_TIME);

        
  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
  $finish;
end

endmodule