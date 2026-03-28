`timescale 1ns / 1ps

module tb_fetch_pointer();

    // 1. Signals
    reg clk;
    reg rst_bar;
    reg shft_reg_we;
    reg from_ex_ld_cs;
    reg [15:0] from_ex_cs_reg;
    reg from_de_take_branch;
    reg from_ex_flush;
    reg from_f_cl_ld;
    reg [31:0] bp_eip_target;
    reg [31:0] ex_eip_target;

    wire [31:0] ic_addr;

    // Error Tracking
    integer FAILURES = 0;
    integer SUCCESSES = 0;

    // 2. Instantiate UUT
    fetch_pointer uut (
        .clk(clk), .rst_bar(rst_bar),
        .shft_reg_we(shft_reg_we),
        .from_ex_ld_cs(from_ex_ld_cs), .from_ex_cs_reg(from_ex_cs_reg),
        .from_de_take_branch(from_de_take_branch), .from_ex_flush(from_ex_flush), 
        .from_f_cl_ld(from_f_cl_ld),
        .bp_eip_target(bp_eip_target), .ex_eip_target(ex_eip_target),
        .ic_addr(ic_addr)
    );

    // 3. Clock Generation (50MHz / 20ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // 4. Verification Task
    task check_addr;
        input [8*40:1] test_name;
        input [31:0] expected_ic_addr;
        begin
            @(negedge clk); // Wait for combinational settle
            #2; // Margin for structural delays
            if (ic_addr === expected_ic_addr) begin
                $display("  ✅ PASS | %0s | ic_addr: %h", test_name, ic_addr);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ FAIL | %0s", test_name);
                $display("     EXPECTED: %h | ACTUAL: %h", expected_ic_addr, ic_addr);
                // UPDATED DEBUG PRINT: Reconstructed CS Base since the internal reg is gone
                $display("      [DEBUG] CS_Base: %h | FEIP_Aligned: %h", {uut.from_ex_cs_reg, 16'h0000}, uut.feip_reg_out32);
                $display("      [DEBUG] eip_true (MUX out): %h | ld_feip: %b", uut.eip_true, uut.ld_feip);
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    // 5. Stimulus
    initial begin
        $dumpfile("fetch_pointer_tb.vcd");
        $dumpvars(0, tb_fetch_pointer);

        // --- Init State ---
        shft_reg_we = 0; from_ex_ld_cs = 0;
        from_ex_cs_reg = 16'h0000; from_de_take_branch = 0;
        from_ex_flush = 0; from_f_cl_ld = 0;
        bp_eip_target = 32'h0; ex_eip_target = 32'h0;

        // Reset
        rst_bar = 0;
        #25;
        rst_bar = 1;
        @(negedge clk);

        $display("=======================================");
        $display("       FETCH POINTER LOGIC TEST        ");
        $display("=======================================");

        // TEST 1: Load CS Register (Segment Base)
        from_ex_ld_cs = 1;
        from_ex_cs_reg = 16'h1000; // CS: 1000 -> Base: 1000_0000 (combinatorial now)
        @(posedge clk); #1; 
        from_ex_ld_cs = 0;
        // Expected ic_addr: CS_Base(1000_0000) + FEIP(0) = 1000_0000
        check_addr("Load CS Segment Base  ", 32'h1000_0000);

        // TEST 2: Single Increment to the next Cache Line
        $display("TEST 2: Incrementing FEIP by one cache line...");
        shft_reg_we = 1;
        @(posedge clk); 
        #1;
        shft_reg_we = 0;
        check_addr("Next Cache Line Jump   ", 32'h1000_0010);
        
        // TEST 3: Branch Target Load
        bp_eip_target = 32'h0000_00A5; // Binary ending in 0101
        from_de_take_branch = 1; // Select BP target
        @(posedge clk); #1; 
        from_de_take_branch = 0;
        // Target A5 (1010 0101) aligned to 16-byte boundary is A0 (1010 0000).
        // Expected: 1000_0000 + 0000_00A0 = 1000_00A0
        check_addr("Branch Target (Aligned)", 32'h1000_00A0);

        // TEST 4: Flush / Redirection
        ex_eip_target = 32'h0000_BEEF;
        from_ex_flush = 1;
        @(posedge clk); #1;
        from_ex_flush = 0;
        // BEEF (1110 1111) aligned to 16-byte boundary is BE E0.
        check_addr("Execute Flush Target  ", 32'h1000_BEE0);

        $display("=======================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule