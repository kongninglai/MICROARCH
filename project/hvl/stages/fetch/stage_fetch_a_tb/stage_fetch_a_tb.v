`timescale 1ns / 1ps

module stage_fetch_a_tb();

    // 1. Inputs (Registers for the stimulus)
    reg clk;
    reg rst_bar;
    reg shft_reg_we;               // Replaced from_f_cl_ld with direct shft_reg_we
    reg from_de_take_branch;
    reg from_ex_flush;
    reg from_ex_ld_cs;
    reg [15:0] from_rr_cs_reg;
    reg [31:0] from_ex_eip_target;
    reg [31:0] from_de_eip_target;
    
    // 2. Outputs
    wire [19:0] ITLB_VPN;
    wire [11:0] F_PAGE_OFFSET;
    wire [31:0] ic_addr;

    // Internal stats
    integer FAILURES = 0;
    integer SUCCESSES = 0;

    // 3. Instantiate UUT (Removed ghost cache/TLB ports)
    stage_fetch_a uut (
        .clk(clk), 
        .rst_bar(rst_bar),
        .ITLB_VPN(ITLB_VPN),
        .F_PAGE_OFFSET(F_PAGE_OFFSET),
        .shft_reg_we(shft_reg_we),                 // FIXED PORT MAPPING
        .from_de_bp_target(from_de_eip_target),
        .from_de_take_branch(from_de_take_branch), // FIXED TYPO
        .from_rr_cs(from_rr_cs_reg),
        .from_ex_eip_target(from_ex_eip_target),
        .from_ex_flush(from_ex_flush),
        .from_ex_ld_cs(from_ex_ld_cs),
        .ic_addr(ic_addr)
    );

    // 4. Clock Generation (50MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // 5. Verification Task
    task check_fetch;
        input [8*40:1] test_name;
        input [31:0] expected_ic_addr;
        begin
            @(negedge clk); 
            #2; 
            if (ic_addr === expected_ic_addr) begin
                $display("  ✅ PASS | %0s | ic_addr: %h", test_name, ic_addr);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ FAIL | %0s", test_name);
                $display("     EXPECTED: %h | ACTUAL: %h", expected_ic_addr, ic_addr);
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    // 6. Stimulus Block
    initial begin
        $dumpfile("stage_fetch_a_tb.vcd");
        $dumpvars(0, stage_fetch_a_tb); 

        // Initialize all registers
        from_de_take_branch = 0; from_ex_flush = 0; from_ex_ld_cs = 0;
        from_rr_cs_reg = 16'h0; shft_reg_we = 0;
        from_ex_eip_target = 32'h0; from_de_eip_target = 32'h0;

        // Reset Sequence
        rst_bar = 0;
        #25;
        rst_bar = 1;
        @(negedge clk);

        $display("=======================================");
        $display("          STAGE FETCH TOP TEST         ");
        $display("=======================================");

        // TEST 1: Load Segment Base
        from_ex_ld_cs = 1;
        from_rr_cs_reg = 16'h1000; 
        @(posedge clk); #1; 
        from_ex_ld_cs = 0;
        check_fetch("Load CS Segment Base  ", 32'h1000_0000);

        // TEST 2: Sequential Increment
        shft_reg_we = 1;
        @(posedge clk); #1;
        shft_reg_we = 0;
        check_fetch("Sequential Fetch (+0x10)", 32'h1000_0010);

        // TEST 3: Branch Redirection
        from_de_eip_target = 32'h0000_00A5; 
        from_de_take_branch = 1;
        shft_reg_we = 1;            // <-- REQUIRED: enable the register!
        @(posedge clk); #1;
        from_de_take_branch = 0;
        shft_reg_we = 0;            // <-- TURN OFF
        check_fetch("Decode Branch (Aligned) ", 32'h1000_00A0);

        // TEST 4: Flush Redirection
        from_ex_eip_target = 32'h0000_BEEF; 
        from_ex_flush = 1;
        shft_reg_we = 1;            // <-- REQUIRED: enable the register!
        @(posedge clk); #1;
        from_ex_flush = 0;
        shft_reg_we = 0;            // <-- TURN OFF
        check_fetch("Execute Flush Target    ", 32'h1000_BEE0);

        $display("=======================================");
        $display("FAILURES = %d, SUCCESSES = %d", FAILURES, SUCCESSES);
        $display("=======================================");
        $finish;
    end

endmodule