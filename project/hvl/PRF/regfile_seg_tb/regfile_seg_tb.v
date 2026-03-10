module regfile_seg_tb;
    initial begin
        $vcdplusfile("regfile_seg_tb.dump.vpd");
        $vcdpluson(0, regfile_seg_tb); 
    end

    reg clk;
    reg rst_n;

    reg  [2:0] segrd0_idx;
    reg  [2:0] segrd1_idx;

    wire [15:0] segrd0_data, segrd0_data_bh;
    wire [15:0] segrd1_data, segrd1_data_bh;
    wire [19:0] segrd0_limit, segrd0_limit_bh;
    wire [19:0] segrd1_limit, segrd1_limit_bh;
    wire [15:0] cs, cs_bh;

    reg  [2:0] segwr_idx;
    reg  [15:0] segwr_data;
    reg  segwr_en;

    reg  cs_wr_en;
    reg  [15:0] cs_wr_data;

    regfile_seg_bh dut_bh (
        .clk(clk),
        .rst_n(rst_n),
        .segrd0_idx(segrd0_idx),
        .segrd1_idx(segrd1_idx),
        .segrd0_data(segrd0_data_bh),
        .segrd1_data(segrd1_data_bh),
        .segrd0_limit(segrd0_limit_bh),
        .segrd1_limit(segrd1_limit_bh),
        .cs(cs_bh),
        .segwr_idx(segwr_idx),
        .segwr_data(segwr_data),
        .segwr_en(segwr_en),
        .cs_wr_en(cs_wr_en),
        .cs_wr_data(cs_wr_data)
    );

    regfile_seg dut (
        .clk(clk),
        .rst_n(rst_n),
        .segrd0_idx(segrd0_idx),
        .segrd1_idx(segrd1_idx),
        .segrd0_data(segrd0_data),
        .segrd1_data(segrd1_data),
        .segrd0_limit(segrd0_limit),
        .segrd1_limit(segrd1_limit),
        .cs(cs),
        .segwr_idx(segwr_idx),
        .segwr_data(segwr_data),
        .segwr_en(segwr_en),
        .cs_wr_en(cs_wr_en),
        .cs_wr_data(cs_wr_data)
    );

    always #5 clk = ~clk;

    task clear_inputs;
    begin
        segrd0_idx = 3'd0;
        segrd1_idx = 3'd0;
        segwr_idx  = 3'd0;
        segwr_data = 16'h0000;
        segwr_en   = 1'b0;
        cs_wr_en   = 1'b0;
        cs_wr_data = 16'h0000;
    end
    endtask

    task check16;
        input [15:0] got_bh;
        input [15:0] got_st;
        input [15:0] exp;
        input [255:0] msg;
    begin
        if (got_bh !== exp) begin
            $display("[BEHAVIORAL FAIL] %s: got_bh=%h exp=%h time=%0t", msg, got_bh, exp, $time);
            $finish;
        end else if (got_st !== got_bh) begin 
            $display("[STRUCTURAL FAIL] %s: got_bh=%h got_st=%h time=%0t", msg, got_bh, got_st, $time);
            $finish;
        end else begin
            $display("[PASS] %s: %h=%h", msg, got_bh, got_st);
        end
    end
    endtask

    task check20;
        input [19:0] got_bh;
        input [19:0] got_st;
        input [19:0] exp;
        input [255:0] msg;
    begin
        if (got_bh !== exp) begin
            $display("[BEHAVIORAL FAIL] %s: got_bh=%h exp=%h time=%0t", msg, got_bh, exp, $time);
            $finish;
        end else if (got_st !== got_bh) begin 
            $display("[STRUCTURAL FAIL] %s: got_bh=%h got_st=%h time=%0t", msg, got_bh, got_st, $time);
            $finish;
        end else begin
            $display("[PASS] %s: %h=%h", msg, got_bh, got_st);
        end
    end
    endtask

    integer k;

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        clear_inputs();

        // ============================================================
        // Test 1: reset all
        // ============================================================
        @(posedge clk);
        @(posedge clk);

        // release reset
        rst_n = 1'b1;
        @(negedge clk);

        // check all segment regs are zero
        for (k = 0; k < 8; k = k + 1) begin
            segrd0_idx = k[2:0];
            #1;
            check16(segrd0_data_bh, segrd0_data, 16'h0000, "reset clears segment register");
        end

        check16(cs_bh, cs, 16'h0000, "reset clears cs");

        // also check limit outputs for a few known indices
        @(negedge clk);
        segrd0_idx = 3'd0; #2; check20(segrd0_limit_bh, segrd0_limit, 20'h003ff, "limit idx0");
        segrd0_idx = 3'd1; #2; check20(segrd0_limit_bh, segrd0_limit, 20'h04fff, "limit idx1");
        segrd0_idx = 3'd5; #2; check20(segrd0_limit_bh, segrd0_limit, 20'h007ff, "limit idx5");

        // ============================================================
        // Test 2: single write (not cs)
        // ============================================================
        @(negedge clk);
        segwr_en   = 1'b1;
        segwr_idx  = 3'd3;
        segwr_data = 16'hABCD;
        @(negedge clk);
        segwr_en = 1'b0;

        segrd0_idx = 3'd3;
        #2;
        check16(segrd0_data_bh, segrd0_data, 16'hABCD, "single write non-cs read back");

        // make sure cs unchanged
        check16(cs_bh, cs, 16'h0000, "single write non-cs does not change cs");

        // ============================================================
        // Test 3: single write (cs)
        // ============================================================
        @(negedge clk);
        cs_wr_en   = 1'b1;
        cs_wr_data = 16'h1357;
        @(negedge clk);
        cs_wr_en = 1'b0;

        check16(cs_bh, cs, 16'h1357, "cs write updates cs output");

        // read idx=1 should return reg_cs, not registers[1]
        @(negedge clk);
        segrd0_idx = 3'd1;
        #2;
        check16(segrd0_data_bh, segrd0_data, 16'h1357, "read idx1 returns cs");

        // ============================================================
        // Test 4: same cycle write/read bypass (no cs)
        // ============================================================
        @(negedge clk);
        segwr_en   = 1'b1;
        segwr_idx  = 3'd4;
        segwr_data = 16'hDEAD;

        // same-cycle read same index -> should bypass segwr_data
        segrd0_idx = 3'd4;
        segrd1_idx = 3'd2;   // another port reading unrelated reg
        #2;

        check16(segrd0_data_bh, segrd0_data, 16'hDEAD, "same-cycle write/read bypass on rd0");
        check16(segrd1_data_bh, segrd1_data, 16'h0000, "other read port unaffected");

        @(negedge clk);
        segwr_en = 1'b0;

        segrd0_idx = 3'd4;
        #2;
        check16(segrd0_data_bh, segrd0_data, 16'hDEAD, "written value committed after clock");

        $display("======================================");
        $display("All requested tests passed.");
        $display("======================================");
        $finish;
    end

endmodule