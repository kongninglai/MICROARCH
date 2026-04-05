`timescale 1ns / 1ps

module stage_fetch_a_tb();

    // 1. Inputs (Registers for the stimulus)
    reg clk;
    reg rst_bar;
    reg from_de_take_branch;
    reg from_ex_flush;
    reg from_ex_ld_cs;
    reg [15:0] from_rr_cs_reg;
    reg from_f_cl_ld;
    reg [31:0] from_ex_eip_target;
    reg [31:0] from_de_eip_target;
    
    // --- INOUT PORT FIXES ---
    // We use a 'wire' for the connection to the UUT, driven by a 'reg' 
    // via a continuous 'assign' so we can update them in the initial block.
    reg          ICACHE_VALID_reg;
    wire         ICACHE_VALID;
    assign       ICACHE_VALID = ICACHE_VALID_reg;

    reg [127:0]  ICACHE_HIT_DATA_reg;
    wire [127:0] ICACHE_HIT_DATA;
    assign       ICACHE_HIT_DATA = ICACHE_HIT_DATA_reg;

    // 2. Outputs
    wire [31:0] ic_addr;
    
    // Dummy wires for ports we aren't actively testing
    wire [2:0]  dummy_pfn;
    wire        dummy_fault;
    wire [11:0] dummy_offset;

    // Internal stats
    integer FAILURES = 0;
    integer SUCCESSES = 0;

    // 3. Instantiate UUT (Unit Under Test)
    stage_fetch_a uut (
        .clk(clk), 
        .rst_bar(rst_bar),
        .from_de_take_branch(from_de_take_branch), // Mapped to from_de_eip_redirection in module logic
        .from_ex_flush(from_ex_flush),
        .from_ex_ld_cs(from_ex_ld_cs),
        .from_rr_cs(from_rr_cs_reg),
        .from_fetch_buffer_write_enable(from_f_cl_ld),
        .from_ex_eip_target(from_ex_eip_target),
        .from_de_bp_target(from_de_eip_target),
        .ICACHE_VALID(ICACHE_VALID),
        .ICACHE_HIT_DATA(ICACHE_HIT_DATA), 
        .ITLB_PFN_OUT(dummy_pfn),
        .ITLB_PAGE_FAULT_OUT(dummy_fault),
        .F_PAGE_OFFSET(dummy_offset),
        .ic_addr(ic_addr),
        .from_wb_flush(1'b0)
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
        $dumpvars(0, stage_fetch_a_tb); // Match the module name!

        // Initialize all registers
        from_de_take_branch = 0; from_ex_flush = 0; from_ex_ld_cs = 0;
        from_rr_cs_reg = 16'h0; from_f_cl_ld = 0;
        from_ex_eip_target = 32'h0; from_de_eip_target = 32'h0;
        
        ICACHE_VALID_reg = 0;       // Use the _reg version!
        ICACHE_HIT_DATA_reg = 128'h0;

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

        // TEST 2: Cache Interaction
        from_f_cl_ld = 1;
        ICACHE_VALID_reg = 0;      // Waiting...
        @(posedge clk); #1;
        check_fetch("Stall: Waiting on Cache", 32'h1000_0000);

        ICACHE_VALID_reg = 1;      // Hit!
        @(posedge clk); #1;
        from_f_cl_ld = 0;
        ICACHE_VALID_reg = 0;
        check_fetch("Valid Fetch (Inc 0x10)", 32'h1000_0010);

        // TEST 3: Branch Redirection
        from_de_eip_target = 32'h0000_00A5; 
        from_de_take_branch = 1;
        @(posedge clk); #1;
        from_de_take_branch = 0;
        check_fetch("Decode Branch (Aligned) ", 32'h1000_00A0);

        // TEST 4: Flush Redirection
        from_ex_eip_target = 32'h0000_BEEF; 
        from_ex_flush = 1;
        @(posedge clk); #1;
        from_ex_flush = 0;
        check_fetch("Execute Flush Target    ", 32'h1000_BEE0);

        $display("=======================================");
        $display("FAILURES = %d, SUCCESSES = %d", FAILURES, SUCCESSES);
        $display("=======================================");
        $finish;
    end

endmodule