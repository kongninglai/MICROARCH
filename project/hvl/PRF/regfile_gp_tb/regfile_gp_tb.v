module regfile_gp_tb;

    initial begin
    $vcdplusfile("regfile_gp_tb.dump.vpd");
    $vcdpluson(0, regfile_gp_tb); 
    end

    reg clk;
    reg rst_n;

    reg [2:0] rd_reg0_idx, rd_reg1_idx, rd_reg2_idx, rd_reg3_idx;
    reg [1:0] rd_reg0_ds,  rd_reg1_ds,  rd_reg2_ds,  rd_reg3_ds;
    wire [31:0] rd_reg0_data, rd_reg1_data, rd_reg2_data, rd_reg3_data;
    wire [31:0] rd_reg0_data_bh, rd_reg1_data_bh, rd_reg2_data_bh, rd_reg3_data_bh;
    reg [2:0] wr_reg0_idx, wr_reg1_idx;
    reg [31:0] wr_reg0_data, wr_reg1_data;
    reg [1:0] wr_reg0_ds, wr_reg1_ds;
    reg wr0_en, wr1_en;

    regfile_gp_bh dut_bh (
        .clk(clk),
        .rst_n(rst_n),

        .rd_reg0_idx(rd_reg0_idx),
        .rd_reg1_idx(rd_reg1_idx),
        .rd_reg2_idx(rd_reg2_idx),
        .rd_reg3_idx(rd_reg3_idx),

        .rd_reg0_ds(rd_reg0_ds),
        .rd_reg1_ds(rd_reg1_ds),
        .rd_reg2_ds(rd_reg2_ds),
        .rd_reg3_ds(rd_reg3_ds),

        .rd_reg0_data(rd_reg0_data_bh),
        .rd_reg1_data(rd_reg1_data_bh),
        .rd_reg2_data(rd_reg2_data_bh),
        .rd_reg3_data(rd_reg3_data_bh),

        .wr_reg0_idx(wr_reg0_idx),
        .wr_reg0_data(wr_reg0_data),
        .wr_reg0_ds(wr_reg0_ds),
        .wr0_en(wr0_en),

        .wr_reg1_idx(wr_reg1_idx),
        .wr_reg1_data(wr_reg1_data),
        .wr_reg1_ds(wr_reg1_ds),
        .wr1_en(wr1_en)
    );

    regfile_gp dut (
        .clk(clk),
        .rst_n(rst_n),

        .rd_reg0_idx(rd_reg0_idx),
        .rd_reg1_idx(rd_reg1_idx),
        .rd_reg2_idx(rd_reg2_idx),
        .rd_reg3_idx(rd_reg3_idx),

        .rd_reg0_ds(rd_reg0_ds),
        .rd_reg1_ds(rd_reg1_ds),
        .rd_reg2_ds(rd_reg2_ds),
        .rd_reg3_ds(rd_reg3_ds),

        .rd_reg0_data(rd_reg0_data),
        .rd_reg1_data(rd_reg1_data),
        .rd_reg2_data(rd_reg2_data),
        .rd_reg3_data(rd_reg3_data),

        .wr_reg0_idx(wr_reg0_idx),
        .wr_reg0_data(wr_reg0_data),
        .wr_reg0_ds(wr_reg0_ds),
        .wr0_en(wr0_en),

        .wr_reg1_idx(wr_reg1_idx),
        .wr_reg1_data(wr_reg1_data),
        .wr_reg1_ds(wr_reg1_ds),
        .wr1_en(wr1_en)
    );


    always #5 clk = ~clk;

    task clear_inputs;
    begin
        rd_reg0_idx = 0; rd_reg1_idx = 0; rd_reg2_idx = 0; rd_reg3_idx = 0;
        rd_reg0_ds  = 2'b10; rd_reg1_ds  = 2'b10; rd_reg2_ds  = 2'b10; rd_reg3_ds  = 2'b10;
        wr_reg0_idx = 0; wr_reg1_idx = 0;
        wr_reg0_data = 0; wr_reg1_data = 0;
        wr_reg0_ds = 2'b10; wr_reg1_ds = 2'b10;
        wr0_en = 0; wr1_en = 0;
    end
    endtask

    task check;
        input [31:0] got_bh;
        input [31:0] got_st;
        input [31:0] exp;
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

    initial begin
        clk = 0;
        rst_n = 0;
        clear_inputs();

        // reset
        @(posedge clk);
        @(posedge clk);
        rst_n = 1;

        // ------------------------------------------------------------
        // Test 1: reset cleared
        @(negedge clk);
        rd_reg0_idx = 3'd0; rd_reg0_ds = 2'b10;
        @(negedge clk);
        check(rd_reg0_data_bh,rd_reg0_data, 32'h00000000, "reset clears reg0");

        // ------------------------------------------------------------
        // Test 2: 32-bit write/read
        @(negedge clk);
        wr_reg0_idx = 3'd3;
        wr_reg0_ds  = 2'b10;
        wr_reg0_data = 32'h12345678;
        wr0_en = 1;

        rd_reg0_idx = 3'd3;
        rd_reg0_ds  = 2'b10;
        @(negedge clk);
        check(rd_reg0_data_bh, rd_reg0_data, 32'h12345678, "bypass on 32-bit write");

        @(negedge clk);
        wr0_en = 0;
        @(negedge clk);
        check(dut_bh.registers[3], dut.q[3], 32'h12345678, "32-bit write committed");

        // ------------------------------------------------------------
        // Test 3: 16-bit write preserves upper 16 bits
        @(negedge clk);
        wr0_en = 1;
        wr_reg0_idx = 3'd3;
        wr_reg0_ds  = 2'b01;
        wr_reg0_data = 32'h0000ABCD;
        @(negedge clk);
        wr0_en = 0;
        @(negedge clk);
        check(dut_bh.registers[3], dut.q[3], 32'h1234ABCD, "16-bit write preserves upper 16");

        // ------------------------------------------------------------
        // Test 4: low 8-bit write (AL style)
        // reg0 initially write 0x11223344
        @(negedge clk);
        wr0_en = 1;
        wr_reg0_idx = 3'd0;
        wr_reg0_ds  = 2'b10;
        wr_reg0_data = 32'h11223344;
        @(negedge clk);
        wr0_en = 0;
        @(negedge clk);
        check(dut_bh.registers[0], dut.q[0], 32'h11223344, "init reg0");

        @(negedge clk);
        wr0_en = 1;
        wr_reg0_idx = 3'b000;   // low 8-bit of reg0
        wr_reg0_ds  = 2'b00;
        wr_reg0_data = 32'h000000AA;
        @(negedge clk);
        wr0_en = 0;
        @(negedge clk);
        check(dut_bh.registers[0], dut.q[0], 32'h112233AA, "low 8-bit write");

        // ------------------------------------------------------------
        // Test 5: high 8-bit write (AH style)
        @(negedge clk);
        wr0_en = 1;
        wr_reg0_idx = 3'b100;   // high 8-bit of reg0
        wr_reg0_ds  = 2'b00;
        wr_reg0_data = 32'h000000BB;
        @(negedge clk);
        wr0_en = 0;
        @(negedge clk);
        check(dut_bh.registers[0], dut.q[0], 32'h1122BBAA, "high 8-bit write");

        // read back low/high bytes
        @(negedge clk);
        rd_reg0_idx = 3'b000; rd_reg0_ds = 2'b00; #1;
        @(negedge clk);
        check(rd_reg0_data_bh, rd_reg0_data, 32'h000000AA, "read low 8-bit");

        rd_reg0_idx = 3'b100; rd_reg0_ds = 2'b00; #1;
        @(negedge clk);
        check(rd_reg0_data_bh, rd_reg0_data, 32'h000000BB, "read high 8-bit");

        // ------------------------------------------------------------
        // Test 6: same register low/high 8-bit dual write merge
        // wr0=AL=0x11, wr1=AH=0x22 => reg0 = ...2211
        @(negedge clk);
        wr0_en = 1;
        wr1_en = 1;
        wr_reg0_idx = 3'b000;
        wr_reg0_ds  = 2'b00;
        wr_reg0_data = 32'h00000011;

        wr_reg1_idx = 3'b100;
        wr_reg1_ds  = 2'b00;
        wr_reg1_data = 32'h00000022;

        rd_reg0_idx = 3'd0; rd_reg0_ds = 2'b10; #1;
        @(negedge clk);
        check(rd_reg0_data_bh, rd_reg0_data, 32'h11222211, "bypass merged low/high 8-bit write");

        @(negedge clk);
        wr0_en = 0;
        wr1_en = 0;
        @(negedge clk);
        check(dut_bh.registers[0], dut.q[0], 32'h11222211, "commit merged low/high 8-bit write");

        // ------------------------------------------------------------
        // Test 7: same pidx conflict, wr0 priority
        // both write reg2, full 32-bit, should keep wr0
        @(negedge clk);
        wr0_en = 1;
        wr1_en = 1;
        wr_reg0_idx = 3'd2;
        wr_reg0_ds  = 2'b10;
        wr_reg0_data = 32'hAAAAAAAA;

        wr_reg1_idx = 3'd2;
        wr_reg1_ds  = 2'b10;
        wr_reg1_data = 32'h55555555;

        rd_reg0_idx = 3'd2; rd_reg0_ds = 2'b10; #1;
        @(negedge clk);
        check(rd_reg0_data_bh, rd_reg0_data, 32'hAAAAAAAA, "bypass wr0 priority on same register");

        @(negedge clk);
        wr0_en = 0;
        wr1_en = 0;
        @(negedge clk);
        check(dut_bh.registers[2], dut.q[2], 32'hAAAAAAAA, "wr0 priority committed");

        // ------------------------------------------------------------
        // Test 8: wr1-only bypass
        @(negedge clk);
        wr1_en = 1;
        wr_reg1_idx = 3'd5;
        wr_reg1_ds  = 2'b10;
        wr_reg1_data = 32'hCAFEBABE;

        rd_reg0_idx = 3'd5;
        rd_reg0_ds  = 2'b10;
        @(negedge clk);
        check(rd_reg0_data_bh, rd_reg0_data, 32'hCAFEBABE, "wr1 bypass");

        @(negedge clk);
        wr1_en = 0;
        @(negedge clk);
        check(dut_bh.registers[5], dut.q[5], 32'hCAFEBABE, "wr1 committed");

        // ------------------------------------------------------------
        // Test 9: 4 read ports simultaneously
        // initialize 4 different registers first
        @(negedge clk);
        wr0_en = 1;
        wr1_en = 1;
        wr_reg0_idx  = 3'd0;
        wr_reg0_ds   = 2'b10;
        wr_reg0_data = 32'h11111111;
        wr_reg1_idx  = 3'd1;
        wr_reg1_ds   = 2'b10;
        wr_reg1_data = 32'h22222222;
        @(negedge clk);
        wr0_en = 0;
        wr1_en = 0;

        wr0_en = 1;
        wr1_en = 1;
        wr_reg0_idx  = 3'd2;
        wr_reg0_ds   = 2'b10;
        wr_reg0_data = 32'h33333333;
        wr_reg1_idx  = 3'd3;
        wr_reg1_ds   = 2'b10;
        wr_reg1_data = 32'h44444444;
        @(negedge clk);
        wr0_en = 0;
        wr1_en = 0;

        // now read 4 ports at the same time
        rd_reg0_idx = 3'd0; rd_reg0_ds = 2'b10;
        rd_reg1_idx = 3'd1; rd_reg1_ds = 2'b10;
        rd_reg2_idx = 3'd2; rd_reg2_ds = 2'b10;
        rd_reg3_idx = 3'd3; rd_reg3_ds = 2'b10;
        @(negedge clk);

        check(rd_reg0_data_bh, rd_reg0_data, 32'h11111111, "4-read-port rd0");
        check(rd_reg1_data_bh, rd_reg1_data, 32'h22222222, "4-read-port rd1");
        check(rd_reg2_data_bh, rd_reg2_data, 32'h33333333, "4-read-port rd2");
        check(rd_reg3_data_bh, rd_reg3_data, 32'h44444444, "4-read-port rd3");

        $display("========================================");
        $display("All tests passed.");
        $display("========================================");
        $finish;
    end

endmodule