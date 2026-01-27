module regfile_gp_tb;
initial begin
  $vcdplusfile("regfile_gp_tb.dump.vpd");
  $vcdpluson(0, regfile_gp_tb); 
end

  integer FAILURES  = 0;
  integer SUCCESSES = 0;

  parameter WIDTH    = 32;
  parameter DEPTH    = 8;
  parameter IDX_SIZE = 3;

  reg clk;
  reg rst_n;

  reg  [IDX_SIZE-1:0] rd_reg0_idx;
  reg  [IDX_SIZE-1:0] rd_reg1_idx;
  reg  [IDX_SIZE-1:0] rd_reg2_idx;
  wire [WIDTH-1:0]    rd_reg0_data_bh;
  wire [WIDTH-1:0]    rd_reg1_data_bh;
  wire [WIDTH-1:0]    rd_reg2_data_bh;

  wire [WIDTH-1:0]    rd_reg0_data;
  wire [WIDTH-1:0]    rd_reg1_data;
  wire [WIDTH-1:0]    rd_reg2_data;

  reg  [IDX_SIZE-1:0] wr_reg0_idx;
  reg  [WIDTH-1:0]    wr_reg0_data;
  reg                 wr0_en;

  reg  [IDX_SIZE-1:0] wr_reg1_idx;
  reg  [WIDTH-1:0]    wr_reg1_data;
  reg                 wr1_en;
  reg  [1:0] datasize;
  // DUT instantiation
  regfile_gp_bh dut_bh (
    .clk(clk),
    .rst_n(rst_n),

    .rd_reg0_idx(rd_reg0_idx),
    .rd_reg1_idx(rd_reg1_idx),
    .rd_reg2_idx(rd_reg2_idx),
    .rd_reg0_data(rd_reg0_data_bh),
    .rd_reg1_data(rd_reg1_data_bh),
    .rd_reg2_data(rd_reg2_data_bh),

    .wr_reg0_idx(wr_reg0_idx),
    .wr_reg0_data(wr_reg0_data),
    .wr0_en(wr0_en),

    .wr_reg1_idx(wr_reg1_idx),
    .wr_reg1_data(wr_reg1_data),
    .wr1_en(wr1_en),

    .datasize(datasize)
  );

  regfile_gp dut (
    .clk(clk),
    .rst_n(rst_n),

    .rd_reg0_idx(rd_reg0_idx),
    .rd_reg1_idx(rd_reg1_idx),
    .rd_reg2_idx(rd_reg2_idx),
    .rd_reg0_data(rd_reg0_data),
    .rd_reg1_data(rd_reg1_data),
    .rd_reg2_data(rd_reg2_data),

    .wr_reg0_idx(wr_reg0_idx),
    .wr_reg0_data(wr_reg0_data),
    .wr0_en(wr0_en),

    .wr_reg1_idx(wr_reg1_idx),
    .wr_reg1_data(wr_reg1_data),
    .wr1_en(wr1_en),

    .datasize(datasize)
  );



  // clock: 10ns period
  initial begin
    clk = 0;
    forever #20 clk = ~clk;
  end



  // check helper
  task check;
    input [WIDTH-1:0] got;
    input [WIDTH-1:0] exp;
    input [8*80:1]    msg; // string
    begin
      if (got !== exp) begin
        $display("FAIL: %0s  got=%h exp=%h (t=%0t)", msg, got, exp, $time);
        FAILURES = FAILURES + 1;
        $finish;
      end else begin
        // $display("PASS: %0s (t=%0t)", msg, $time);
        SUCCESSES = SUCCESSES + 1;
      end
    end
  endtask

  integer i;

  initial begin
    // init signals
    @(posedge clk);
    rst_n = 0;

    rd_reg0_idx = 0;
    rd_reg1_idx = 0;
    rd_reg2_idx = 0;

    wr0_en = 0;
    wr1_en = 0;
    wr_reg0_idx  = 0;
    wr_reg1_idx  = 0;
    wr_reg0_data = 0;
    wr_reg1_data = 0;

    datasize = 2'b00;

    // apply reset for 1-2 cycles
    @(posedge clk);
    rst_n = 1;

    // -------------------------
    // Test 0: after reset, all regs are 0
    // We'll just spot-check a few addresses
    // -------------------------
    for (i = 0; i < DEPTH; i = i + 1) begin
      rd_reg0_idx = i[IDX_SIZE-1:0];
      @(negedge clk);
      if (rd_reg0_data !== {WIDTH{1'b0}}) begin
        FAILURES = FAILURES + 1;
        $display("FAIL: reset check reg[%0d] got=%h exp=0", i, rd_reg0_data_bh);
      end
    end
    // $display("PASS: reset clears all regs");

    // -------------------------
    // Test 1: single write low 8-bit on port0
    // -------------------------
    @(negedge clk);
    datasize = 2'b00;

    wr0_en       = 1;
    wr_reg0_idx  = 0;
    wr_reg0_data = 32'h12345678;
    @(negedge clk);
    wr0_en = 0;
    rd_reg0_idx = 0;

    @(negedge clk);
    check(rd_reg0_data_bh, 32'h0000_0078, "single write low 8-bit on port0 to reg0 behavioral check");
    check(rd_reg0_data, rd_reg0_data_bh, "single write low 8-bit on port0 to reg0");
    // check(rd_reg0_data, rd_reg0_data_bh, "single write port0 to reg3");

    // -------------------------
    // Test 2: single write high 8-bit on port0
    // -------------------------
    @(negedge clk);
    datasize = 2'b00;

    wr0_en       = 1;
    wr_reg0_idx  = 4;
    wr_reg0_data = 32'hAB12_3456;
    @(negedge clk);
    wr0_en = 0;
    rd_reg0_idx = 4;

    @(negedge clk);
    check(rd_reg0_data_bh, 32'h0000_0056, "single write high 8-bit on port0 to reg0 behavioral check");
    check(rd_reg0_data, rd_reg0_data_bh, "single write high 8-bit on port0 to reg0");
    // check(rd_reg0_data, rd_reg0_data_bh, "single write port0 to reg3");



    // -------------------------
    // Test 3: dual write 16-bit to different regs in same cycle
    // -------------------------
    @(negedge clk);
    datasize = 2'b10;

    wr0_en       = 1;
    wr_reg0_idx  = 1;
    wr_reg0_data = 32'h1111_1111;

    wr1_en       = 1;
    wr_reg1_idx  = 2;
    wr_reg1_data = 32'h2222_2222;
    @(negedge clk);
    wr0_en = 0;
    wr1_en = 0;
    rd_reg0_idx = 1;
    rd_reg1_idx = 2;

    @(negedge clk);
    check(rd_reg0_data_bh, 32'h0000_1111, "dual write 16-bit: port0 to reg1 behavioral check");
    check(rd_reg1_data_bh, 32'h0000_2222, "dual write 16-bit : port1 to reg2 behavioral check");

    check(rd_reg0_data, rd_reg0_data_bh, "dual write 16-bit: port0 to reg1");
    check(rd_reg1_data, rd_reg1_data_bh, "dual write 16-bit : port1 to reg2");

    // -------------------------
    // Test 4: dual write 32-bit same reg in same cycle (wr0 wins)
    // -------------------------
    @(negedge clk);
    datasize = 2'b11;
    wr0_en       = 1;
    wr_reg0_idx  = 4;
    wr_reg0_data = 32'h4444_4444;

    wr1_en       = 1;
    wr_reg1_idx  = 4;
    wr_reg1_data = 32'hDEAD_BEEF;
    @(negedge clk);
    wr0_en = 0;
    wr1_en = 0;
    rd_reg0_idx = 4;

    @(negedge clk);
    check(rd_reg0_data_bh, 32'h4444_4444, "same-reg dual write: wr0 wins at reg4 behavioral check");
    check(rd_reg0_data, rd_reg0_data_bh, "same-reg dual write: wr0 wins at reg4");
    // check(rd_reg0_data, rd_reg0_data_bh, "same-reg dual write: wr0 wins at reg4");

    // -------------------------
    // Test 5: dual write 8-bit same reg low/high 8-bit in same cycle (wr0 wins)
    // -------------------------
    @(negedge clk);
    datasize = 2'b00;

    wr0_en       = 1;
    wr_reg0_idx  = 0;
    wr_reg0_data = 32'hAAAA_AAAA;

    wr1_en       = 1;
    wr_reg1_idx  = 4;
    wr_reg1_data = 32'hBBBB_BBBB;

    @(negedge clk);
    wr0_en = 0;
    wr1_en = 0;

    rd_reg0_idx = 0;
    datasize = 2'b10;
    
    @(negedge clk);
    check(rd_reg0_data_bh, 32'h0000_BBAA, "same-reg low/high 8-bit dual write at reg0 behavioral check");
    check(rd_reg0_data, rd_reg0_data_bh, "same-reg low/high 8-bit dual write at reg0");
    // check(rd_reg0_data, rd_reg0_data_bh, "same-reg dual write: wr0 wins at reg4");

    // -------------------------
    // Test 6: read 3 ports 8-bit
    // -------------------------
    @(negedge clk);
    datasize = 2'b00;
    rd_reg0_idx = 0;
    rd_reg1_idx = 4;
    rd_reg2_idx = 1;
    
    @(negedge clk);
    check(rd_reg0_data_bh, 32'h0000_00AA, "read 3 ports 8-bit: at reg0 behavioral check");
    check(rd_reg1_data_bh, 32'h0000_00BB, "read 3 ports 8-bit: at reg1 behavioral check");
    check(rd_reg2_data_bh, 32'h0000_0011, "read 3 ports 8-bit: at reg2 behavioral check");

    check(rd_reg0_data, rd_reg0_data_bh, "read 3 ports 8-bit: at reg0");
    check(rd_reg1_data, rd_reg1_data_bh, "read 3 ports 8-bit: at reg1");
    check(rd_reg2_data, rd_reg2_data_bh, "read 3 ports 8-bit: at reg2");

    // --------------------------------------------------
    // Test 7: BYPASS - single write and read same 16-bit reg in same cycle
    // --------------------------------------------------
    @(negedge clk);
    datasize = 2'b10;

    rd_reg0_idx = 5;
    rd_reg1_idx = 6;
    rd_reg2_idx = 7;

    // schedule a write to same reg on port0
    wr0_en       = 1;
    wr_reg0_idx  = 5;
    wr_reg0_data = 32'hCAFE_BABE;

    wr1_en = 0;

    @(negedge clk);

    check(rd_reg0_data_bh, 32'h0000_BABE, "bypass: rd0 sees wr0_data same cycle behavioral check");
    check(rd_reg0_data, rd_reg0_data_bh, "bypass: rd0 sees wr0_data same cycle");
    @(posedge clk);
    wr0_en = 0;


    // --------------------------------------------------
    // Test 8: BYPASS - dual write different regs, read both
    // rd1 matches wr0, rd2 matches port1
    // --------------------------------------------------
    @(negedge clk);
    datasize = 2'b11;

    rd_reg0_idx = 5;   
    rd_reg1_idx = 6;   
    rd_reg2_idx = 7;

    wr0_en       = 1;
    wr_reg0_idx  = 6;
    wr_reg0_data = 32'h6666_6666;

    wr1_en       = 1;
    wr_reg1_idx  = 7;
    wr_reg1_data = 32'h7777_7777;

    @(negedge clk);

    check(rd_reg1_data_bh, 32'h6666_6666, "bypass: rd1 sees wr0_data behavioral check");
    check(rd_reg2_data_bh, 32'h7777_7777, "bypass: rd2 sees wr1_data behavioral check");
    check(rd_reg1_data, rd_reg1_data_bh, "bypass: rd1 sees wr0_data");
    check(rd_reg2_data, rd_reg2_data_bh, "bypass: rd2 sees wr1_data");

    @(negedge clk);
    wr0_en = 0;
    wr1_en = 0;

    // --------------------------------------------------
    // Test 9: BYPASS - dual write same reg (wr0 wins), read that reg
    // --------------------------------------------------
    @(negedge clk);
    datasize = 2'b11;

    rd_reg0_idx = 2;   // choose some reg
    rd_reg1_idx = 0;
    rd_reg2_idx = 0;

    wr0_en       = 1;
    wr_reg0_idx  = 2;
    wr_reg0_data = 32'hABCD_2020;

    wr1_en       = 1;
    wr_reg1_idx  = 2;
    wr_reg1_data = 32'hBABE_0101;
    @(negedge clk);
    check(rd_reg0_data_bh, 32'hABCD_2020, "bypass: same-reg dual write, wr0 wins behavioral check");
    check(rd_reg0_data, rd_reg0_data_bh, "bypass: same-reg dual write, wr0 wins");
    @(posedge clk);
    wr0_en = 0;
    wr1_en = 0;

    // --------------------------------------------------
    // Test 10: BYPASS - dual write same reg low/high 8-bit, read that reg
    // --------------------------------------------------
    @(negedge clk);
    datasize = 2'b00;

    rd_reg0_idx = 6;   // choose some reg
    rd_reg1_idx = 0;
    rd_reg2_idx = 0;

    wr0_en       = 1;
    wr_reg0_idx  = 2;
    wr_reg0_data = 32'h2222_2222;

    wr1_en       = 1;
    wr_reg1_idx  = 6;
    wr_reg1_data = 32'h6666_6666;
    @(negedge clk);
    check(rd_reg0_data_bh, 32'h0000_0066, "bypass: same-reg low/high 8-bit dual write, wr0 wins behavioral check");
    check(rd_reg0_data, rd_reg0_data_bh, "bypass: same-reg low/high 8-bit dual write, wr0 wins behavioral check");

    @(posedge clk);
    wr0_en = 0;
    wr1_en = 0;


    // --------------------------------------------------
    // Test 11: random test
    // --------------------------------------------------
    @(negedge clk);
    rd_reg0_idx = $random;   
    rd_reg1_idx = $random;
    rd_reg2_idx = $random;

    wr0_en       = $random;
    wr_reg0_idx  = $random;
    wr_reg0_data = $random;

    wr1_en       = $random;
    wr_reg1_idx  = $random;
    wr_reg1_data = $random;
    datasize     = $random;

    repeat (1 << 5) begin
      @(negedge clk);
      check(rd_reg0_data, rd_reg0_data_bh, "random tests reg0");
      check(rd_reg1_data, rd_reg1_data_bh, "random tests reg1");
      check(rd_reg2_data, rd_reg2_data_bh, "random tests reg2");

      @(posedge clk);
      wr0_en = 0;
      wr1_en = 0;

      @(negedge clk);
      rd_reg0_idx = $random;   
      rd_reg1_idx = $random;
      rd_reg2_idx = $random;

      wr0_en       = $random;
      wr_reg0_idx  = $random;
      wr_reg0_data = $random;

      wr1_en       = $random;
      wr_reg1_idx  = $random;
      wr_reg1_data = $random;
      datasize     = $random;
    end

    $display("FAILURES = %0d out of %0d\n", FAILURES, FAILURES + SUCCESSES);
    $display("SUCCESSES = %0d out of %0d\n", SUCCESSES, FAILURES + SUCCESSES);
    $finish;
  end

endmodule
