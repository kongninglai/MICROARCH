`timescale 1ns / 1ps

module tb_stage_fetch();

    // 1. Inputs
    reg clk;
    reg rst_bar;
    reg from_de_take_branch;
    reg from_ex_flush;
    reg from_ex_ld_cs;
    reg [15:0] from_ex_cs_reg; // FIXED: Matched width to 16 bits
    reg from_f_cl_ld;
    reg [31:0] from_ex_eip_target;
    reg [31:0] from_de_eip_target;
    
    // Cache Inputs
    reg ICACHE_VALID;
    
    // --- INOUT PORT FIX ---
    // You must use a 'wire' for the inout connection, driven by a 'reg'
    reg [127:0] ICACHE_HIT_DATA_reg;
    wire [127:0] ICACHE_HIT_DATA;
    assign ICACHE_HIT_DATA = ICACHE_HIT_DATA_reg;

    // 2. Outputs
    wire [31:0] ic_addr;
    
    // Dummy wires to ignore the inout ports
    wire [2:0] dummy_pfn;
    wire dummy_fault;
    wire [11:0] dummy_offset;

    // Error Tracking
    integer FAILURES = 0;
    integer SUCCESSES = 0;

    // 3. Instantiate UUT
    stage_fetch uut (
        .clk(clk), 
        .rst_bar(rst_bar),
        .from_de_take_branch(from_de_take_branch),
        .from_ex_flush(from_ex_flush),
        .from_ex_ld_cs(from_ex_ld_cs),
        .from_ex_cs_reg(from_ex_cs_reg),
        .from_f_cl_ld(from_f_cl_ld),
        .from_ex_eip_target(from_ex_eip_target),
        .from_de_eip_target(from_de_eip_target),
        .ICACHE_VALID(ICACHE_VALID),
        .ICACHE_HIT_DATA(ICACHE_HIT_DATA), // Now correctly connected to a wire
        // Ignored inout ports
        .ITLB_PFN_OUT(dummy_pfn),
        .ITLB_PAGE_FAULT_OUT(dummy_fault),
        .F_PAGE_OFFSET(dummy_offset),
        // Valid Output
        .ic_addr(ic_addr)
    );

    // 4. Clock Generation (50MHz / 20ns period)
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
            #2; // Settle time for structural gates
            
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

    // 6. Stimulus
    initial begin
        $dumpfile("stage_fetch_tb.vcd");
        $dumpvars(0, tb_stage_fetch);

        // --- Initialize ---
        from_de_take_branch = 0; from_ex_flush = 0; from_ex_ld_cs = 0;
        from_ex_cs_reg = 16'h0; from_f_cl_ld = 0;
        from_ex_eip_target = 32'h0; from_de_eip_target = 32'h0;
        
        ICACHE_VALID = 0; 
        ICACHE_HIT_DATA_reg = 128'h0; // Update the backing register

        // Reset Sequence
        rst_bar = 0;
        #25;
        rst_bar = 1;
        @(negedge clk);

        $display("=======================================");
        $display("          STAGE FETCH TOP TEST         ");
        $display("=======================================");

        // --------------------------------------------------------
        // TEST 1: Load Segment Base
        // --------------------------------------------------------
        from_ex_ld_cs = 1;
        from_ex_cs_reg = 16'h1000; 
        @(posedge clk); #1; 
        from_ex_ld_cs = 0;
        check_fetch("Load CS Segment Base  ", 32'h1000_0000);

        // --------------------------------------------------------
        // TEST 2: AND Gate Verification (ICACHE_VALID & from_f_cl_ld)
        // --------------------------------------------------------
        // Part A: Request line, but cache isn't valid yet (Should NOT increment)
        from_f_cl_ld = 1;
        ICACHE_VALID = 0;
        @(posedge clk); #1;
        check_fetch("Stall: Waiting on Cache", 32'h1000_0000);

        // Part B: Cache becomes valid! (Should increment to next 16-byte line)
        ICACHE_VALID = 1; 
        // shft_reg_we should now be 1 inside the module
        @(posedge clk); #1;
        from_f_cl_ld = 0;
        ICACHE_VALID = 0;
        check_fetch("Valid Fetch (Inc to 0x10)", 32'h1000_0010);

        // --------------------------------------------------------
        // TEST 3: Decode Branch Taken
        // --------------------------------------------------------
        from_de_eip_target = 32'h0000_00A5; // Unaligned target
        from_de_take_branch = 1;
        @(posedge clk); #1;
        from_de_take_branch = 0;
        check_fetch("Decode Branch (Aligned) ", 32'h1000_00A0);

        // --------------------------------------------------------
        // TEST 4: Execute Flush
        // --------------------------------------------------------
        from_ex_eip_target = 32'h0000_BEEF; // Unaligned target
        from_ex_flush = 1;
        @(posedge clk); #1;
        from_ex_flush = 0;
        check_fetch("Execute Flush Target    ", 32'h1000_BEE0);

        $display("=======================================");
        $display("FAILURES = %d, SUCCESSES = %d", FAILURES, SUCCESSES);
        $finish;
    end

endmodule