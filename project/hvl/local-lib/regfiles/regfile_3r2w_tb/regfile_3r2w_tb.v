module regfile_3r2w_tb;
initial begin
  // $vcdplusfile("regfile_3r2w_tb.dump.vpd");
  // $vcdpluson(0, regfile_3r2w_tb); 
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

  // DUT instantiation
  regfile_3r2w_bh #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH),
    .IDX_SIZE(IDX_SIZE)
  ) dut_bh (
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
    .wr1_en(wr1_en)
  );

  regfile_3r2w dut (
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
    .wr1_en(wr1_en)
  );

  // clock: 10ns period
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // simple "wait for rising edge then small delay"
  task tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  // check helper
  task check;
    input [WIDTH-1:0] got;
    input [WIDTH-1:0] exp;
    input [8*80:1]    msg; // string
    begin
      if (got !== exp) begin
        $display("FAIL: %0s  got=%h exp=%h (t=%0t)", msg, got, exp, $time);
        FAILURES = FAILURES + 1;
        // $finish;
      end else begin
        // $display("PASS: %0s (t=%0t)", msg, $time);
        SUCCESSES = SUCCESSES + 1;
      end
    end
  endtask

  integer i;

  initial begin
    // init signals
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

    // apply reset for 1-2 cycles
    tick;
    tick;
    rst_n = 1;
    tick;

    // -------------------------
    // Test 0: after reset, all regs are 0
    // We'll just spot-check a few addresses
    // -------------------------
    for (i = 0; i < DEPTH; i = i + 1) begin
      rd_reg0_idx = i[IDX_SIZE-1:0];
      #1;
      if (rd_reg0_data !== {WIDTH{1'b0}}) begin
        FAILURES = FAILURES + 1;
        $display("FAIL: reset check reg[%0d] got=%h exp=0", i, rd_reg0_data);
      end
    end
    // $display("PASS: reset clears all regs");

    // -------------------------
    // Test 1: single write on port0
    // -------------------------
    wr0_en       = 1;
    wr_reg0_idx  = 3;
    wr_reg0_data = 32'hAAAA_BBBB;
    tick;
    wr0_en = 0;
    tick; // wait one more cycle for stable read (not strictly necessary with async read)

    rd_reg0_idx = 3;
    #1;
    check(rd_reg0_data_bh, 32'hAAAA_BBBB, "single write port0 to reg3 behavioral check");
    check(rd_reg0_data, rd_reg0_data_bh, "single write port0 to reg3");

    // -------------------------
    // Test 2: dual write different regs in same cycle
    // -------------------------
    wr0_en       = 1;
    wr_reg0_idx  = 1;
    wr_reg0_data = 32'h1111_1111;

    wr1_en       = 1;
    wr_reg1_idx  = 2;
    wr_reg1_data = 32'h2222_2222;

    rd_reg0_idx = 1;
    rd_reg1_idx = 2;
    #1;
    check(rd_reg0_data_bh, 32'h1111_1111, "dual write: port0 to reg1 behavioral check");
    check(rd_reg1_data_bh, 32'h2222_2222, "dual write: port1 to reg2 behavioral check");
    check(rd_reg0_data, rd_reg0_data_bh, "dual write: port0 to reg1");
    check(rd_reg1_data, rd_reg1_data_bh, "dual write: port1 to reg2");
    // -------------------------
    // Test 3: dual write same reg in same cycle (wr0 wins)
    // -------------------------
    wr0_en       = 1;
    wr_reg0_idx  = 4;
    wr_reg0_data = 32'hDEAD_BEEF;

    wr1_en       = 1;
    wr_reg1_idx  = 4;
    wr_reg1_data = 32'h1234_5678;

    rd_reg0_idx = 4;
    #1;
    check(rd_reg0_data_bh, 32'hDEAD_BEEF, "same-reg dual write: wr0 wins at reg4 behavioral check");
    check(rd_reg0_data, rd_reg0_data_bh, "same-reg dual write: wr0 wins at reg4");

    // -------------------------
    // Test 4: read 3 ports
    // -------------------------
    rd_reg0_idx = 1;
    rd_reg1_idx = 2;
    rd_reg2_idx = 3;
    #1;

        // --------------------------------------------------
    // Test 4: BYPASS - single write and read same reg in same cycle
    // Expect read port returns the write data immediately (write-first)
    // --------------------------------------------------
    // $display("---- Test4: bypass single write ----");

    // prepare: set read indices to target reg BEFORE the write edge
    rd_reg0_idx = 5;
    rd_reg1_idx = 0;
    rd_reg2_idx = 0;

    // schedule a write to same reg on port0
    wr0_en       = 1;
    wr_reg0_idx  = 5;
    wr_reg0_data = 32'hCAFE_BABE;

    wr1_en = 0;

    // At the active clock edge, regfile writes, and bypass mux should select wr0_data
    tick;   // @(posedge clk); #1 inside tick

    // Now check that read sees forwarded data (even if memory write is also done)
    check(rd_reg0_data_bh, 32'hCAFE_BABE, "bypass: rd0 sees wr0_data same cycle behavioral check");
    check(rd_reg0_data_bh, 32'hCAFE_BABE, "bypass: rd0 sees wr0_data same cycle behavioral check");
    check(rd_reg0_data, rd_reg0_data_bh, "bypass: rd0 sees wr0_data same cycle");
    check(rd_reg0_data, rd_reg0_data_bh, "bypass: rd0 sees wr0_data same cycle");
    wr0_en = 0;
    tick;


    // --------------------------------------------------
    // Test 5: BYPASS - dual write different regs, read both
    // rd0 matches port0, rd1 matches port1
    // --------------------------------------------------
    // $display("---- Test5: bypass dual write different regs ----");

    rd_reg0_idx = 6;   // will match wr0
    rd_reg1_idx = 7;   // will match wr1
    rd_reg2_idx = 0;

    wr0_en       = 1;
    wr_reg0_idx  = 6;
    wr_reg0_data = 32'h1111_AAAA;

    wr1_en       = 1;
    wr_reg1_idx  = 7;
    wr_reg1_data = 32'h2222_BBBB;

    tick;

    check(rd_reg0_data_bh, 32'h1111_AAAA, "bypass: rd0 sees wr0_data behavioral check");
    check(rd_reg1_data_bh, 32'h2222_BBBB, "bypass: rd1 sees wr1_data behavioral check");
    check(rd_reg0_data, rd_reg0_data_bh, "bypass: rd0 sees wr0_data");
    check(rd_reg1_data, rd_reg1_data_bh, "bypass: rd1 sees wr1_data");
    wr0_en = 0;
    wr1_en = 0;
    tick;


    // --------------------------------------------------
    // Test 6: BYPASS - dual write same reg (wr0 wins), read that reg
    // Expect read returns wr0_data (because wr1 is suppressed / lower priority)
    // --------------------------------------------------
    // $display("---- Test6: bypass same-reg dual write (wr0 wins) ----");

    rd_reg0_idx = 2;   // choose some reg
    rd_reg1_idx = 0;
    rd_reg2_idx = 0;

    wr0_en       = 1;
    wr_reg0_idx  = 2;
    wr_reg0_data = 32'hAAAA_0001;

    wr1_en       = 1;
    wr_reg1_idx  = 2;
    wr_reg1_data = 32'hBBBB_0002;

    tick;

    // because your design: wr0 has priority and wr1 is not effective on same idx
    check(rd_reg0_data_bh, 32'hAAAA_0001, "bypass: same-reg dual write, wr0 wins behavioral check");
    check(rd_reg0_data, rd_reg0_data_bh, "bypass: same-reg dual write, wr0 wins");


    // --------------------------------------------------
    // Test 7: random test
    // --------------------------------------------------
    rd_reg0_idx = $random;   
    rd_reg1_idx = $random;
    rd_reg2_idx = $random;

    wr0_en       = $random;
    wr_reg0_idx  = $random;
    wr_reg0_data = $random;

    wr1_en       = $random;
    wr_reg1_idx  = $random;
    wr_reg1_data = $random;

    repeat (1 << 5) begin
      #40;
      check(rd_reg0_data, rd_reg0_data_bh, "random tests reg0");
      check(rd_reg1_data, rd_reg1_data_bh, "random tests reg1");
      check(rd_reg2_data, rd_reg2_data_bh, "random tests reg2");
      rd_reg0_idx = $random;   
      rd_reg1_idx = $random;
      rd_reg2_idx = $random;

      wr0_en       = $random;
      wr_reg0_idx  = $random;
      wr_reg0_data = $random;

      wr1_en       = $random;
      wr_reg1_idx  = $random;
      wr_reg1_data = $random;
    end

    $display("FAILURES = %0d out of %0d\n", FAILURES, FAILURES + SUCCESSES);
    $display("SUCCESSES = %0d out of %0d\n", SUCCESSES, FAILURES + SUCCESSES);
    $finish;
  end

endmodule
