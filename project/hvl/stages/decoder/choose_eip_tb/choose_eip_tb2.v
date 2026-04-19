`timescale 1ns / 1ps

module tb_choose_eip_advanced();

    // 1. Inputs
    reg clk;             
    reg rst_bar;         
    
    reg [3:0] instr_length;
    reg ld_pr_rr;
    reg instr_valid;
    reg flush_ex;
    reg cur_instr_prediction;
    reg [31:0] bp_eip_target;
    reg [31:0] ex_eip_target;
    reg [1:0] branch_type;
    reg hit; 

    // 2. Outputs
    wire [31:0] i_eip;
    wire [31:0] o_eip;
    wire ld_eip;
    wire [31:0] eip_true;
    wire take_branch;

    // Error Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // 3. Instantiate UUT
    choose_eip uut (
        .clk(clk),
        .rst_bar(rst_bar),
        .instr_length(instr_length),
        .ld_pr_rr(ld_pr_rr),
        .instr_valid(instr_valid),
        .cur_instr_prediction(cur_instr_prediction),
        .flush_ex(flush_ex),  
        .bp_eip_target(bp_eip_target),
        .ex_eip_target(ex_eip_target),
        .branch_type(branch_type),
        .hit(hit), 
        .i_eip(i_eip),     
        .o_eip(o_eip), 
        .ld_eip(ld_eip),
        .eip_true(eip_true),
        .take_branch(take_branch) 
    );

    // --- CLOCK GENERATION ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // 4. Advanced Checking Task
    task check_advanced;
        input [8*35:1] test_name; 
        input exp_ld_eip;
        input [31:0] exp_eip_true;
        
        reg [31:0] expected_o_eip_next;
        reg i_eip_ok, eip_true_ok, ld_eip_ok, o_eip_ok;
        begin
            
            // 1. Wait for combinational logic to settle before clock edge
            #4; 
            
            // Combinational Checks
            i_eip_ok    = (i_eip === (o_eip + instr_length));
            eip_true_ok = (eip_true === exp_eip_true);
            ld_eip_ok   = (ld_eip === exp_ld_eip);

            if (!i_eip_ok || !eip_true_ok || !ld_eip_ok) begin
                $display("  ❌ FAIL (Comb) | %0s", test_name);
                $display("     EXPECTED: ld_eip=%b | eip_true=%h | i_eip=(o_eip + %0d)", exp_ld_eip, exp_eip_true, instr_length);
                $display("     ACTUAL  : ld_eip=%b | eip_true=%h | i_eip=%h (o_eip=%h)", ld_eip, eip_true, i_eip, o_eip);
                FAILURES = FAILURES + 1;
            end else begin
                // Figure out what o_eip SHOULD be after the clock edge
                if (exp_ld_eip) expected_o_eip_next = exp_eip_true;
                else expected_o_eip_next = o_eip; // Register holds value
                
                // 2. CLOCK IT!
                @(posedge clk); 
                #1; // Wait 1ns for FF to update
                
                // Sequential Check
                o_eip_ok = (o_eip === expected_o_eip_next);
                
                if (o_eip_ok) begin
                    $display("  ✅ PASS        | %0s | ld_eip: %b | o_eip updated to: %h", test_name, ld_eip, o_eip);
                    SUCCESSES = SUCCESSES + 1;
                end else begin
                    $display("  ❌ FAIL (Seq)  | %0s", test_name);
                    $display("     EXPECTED o_eip: %h | ACTUAL o_eip: %h", expected_o_eip_next, o_eip);
                    FAILURES = FAILURES + 1;
                end
            end
        end
    endtask

    // 5. Stimulus
    initial begin
        $dumpfile("choose_eip_advanced_tb.vpd");
        $dumpvars(0, tb_choose_eip_advanced);

        $display("=======================================");
        $display("   EIP MUX & REGISTER EDGE CASE TESTS  ");
        $display("=======================================");

        // --- Init State ---
        instr_length = 4'd2;           
        bp_eip_target = 32'h0000_1000; 
        ex_eip_target = 32'h0000_F000; 
        
        ld_pr_rr = 1;
        instr_valid = 1;
        flush_ex = 0;
        cur_instr_prediction = 0;
        branch_type = 2'b00;
        hit = 0;

        // Reset
        rst_bar = 0;
        repeat (2) @(negedge clk);
        rst_bar = 1;
        // Base Check: Let it load once normally so o_eip isn't X.
        // It will load 0 + 2 = 2.
        check_advanced("Init Base State        ", 1'b1, 32'd2);

        // --------------------------------------------------------
        // TEST 1: Flush Overrides a Total Pipeline Freeze
        // Even if valid=0 AND stall=1 (ld_pr_rr=0), flush must force ld_eip=1
        // --------------------------------------------------------
        instr_valid = 0;
        ld_pr_rr = 0;
        flush_ex = 1;
        // Expected: ld_eip = 1, eip_true = ex_eip_target
        check_advanced("Flush Overrides Freeze ", 1'b1, ex_eip_target);
        
        flush_ex = 0;
        ld_pr_rr = 1; // Restore normal operation

        // --------------------------------------------------------
        // TEST 2: Bubble forces ld_eip=0 
        // --------------------------------------------------------
        instr_valid = 0;
        ld_pr_rr = 1;
        
        // Use the actual current EIP (o_eip) + length for the expectation
        // o_eip is currently f000, so we expect f002.
        check_advanced("Bubble forces ld_eip=0 ", 1'b0, o_eip + instr_length);
        
        instr_valid = 1; // Restore

        // --------------------------------------------------------
        // TEST 3: MUX State 11 (Flush AND Branch Taken simultaneously)
        // take_branch = 1, flush_ex = 1. MUX should select IN3 (ex_target)
        // --------------------------------------------------------
        branch_type = 2'b01; // Unconditional
        hit = 1;             // BTB hit -> take_branch goes to 1
        flush_ex = 1;        // Flush goes to 1 simultaneously
        // Expected: eip_true = ex_eip_target (F000), ld_eip = 1
        check_advanced("MUX State 11 collision ", 1'b1, ex_eip_target);
        
        flush_ex = 0;
        branch_type = 2'b00;
        hit = 0;

        // --------------------------------------------------------
        // TEST 4: Unconditional Branch vs Bad Predictor
        // Unconditional branch hits BTB, but predictor says "Not Taken" (0).
        // It should ignore predictor and take the branch anyway.
        // --------------------------------------------------------
        branch_type = 2'b01; // Unconditional
        hit = 1;
        cur_instr_prediction = 0; // Predictor is wrong
        // Expected: eip_true = bp_eip_target (1000), ld_eip = 1
        check_advanced("Uncond ignores bad pred", 1'b1, bp_eip_target);
        
        branch_type = 2'b00;
        hit = 0;

        // --------------------------------------------------------
        // TEST 5: Dynamic i_eip Combinational Check
        // Change instruction length mid-cycle and ensure i_eip instantly updates
        // --------------------------------------------------------
        // Currently o_eip = 1000. 
        instr_length = 4'd15; // Max length
        // Expected: eip_true = 1000 + 15 = 100F. ld_eip = 1
        check_advanced("Dynamic i_eip update   ", 1'b1, o_eip + 4'd15);

        $display("=======================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule