`timescale 1ns / 1ps

module tb_ghr();

    // 1. Inputs (Must be 'reg' in testbench so we can drive them)
    reg clk;
    reg rst_bar;
    reg [7:0] ghr_in;

    // 2. Outputs (Must be 'wire' to read from the module)
    wire [7:0] ghr_out;

    // Error Checking 
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // 3. Instantiate the UUT (Unit Under Test)
    ghr uut (
        .clk(clk),
        .rst_bar(rst_bar),
        .ghr_in(ghr_in),
        .ghr_out(ghr_out)
    );

    // 4. Clock Generation (10ns period -> 100MHz)
    always #5 clk = ~clk;

    // 5. Checking Task
    task check_result;
        input [8*25:1] test_name; 
        input [7:0] expected_val;
        begin
            if (ghr_out === expected_val) begin
                $display("  ✅ PASS | %0s | ghr_out: %b", test_name, ghr_out);
                SUCCESSES = SUCCESSES + 1;
            end else begin
                $display("  ❌ FAIL | %0s", test_name);
                $display("     EXPECTED: %b", expected_val);
                $display("     ACTUAL  : %b", ghr_out);
                FAILURES = FAILURES + 1;
            end
        end
    endtask

    // 6. Stimulus Sequence
    initial begin
        // Setup waveform dumping (optional, but great for GTKWave/ModelSim)
        $dumpfile("ghr_tb.vpd");
        $dumpvars(0, tb_ghr);

        $display("=======================================");
        $display("         PURE GHR REGISTER TEST        ");
        $display("=======================================");

        // --------------------------------------------------------
        // CRITICAL STEP: Initialize ALL inputs at Time = 0
        // --------------------------------------------------------
        clk = 0;
        rst_bar = 0;      // Assert Active-Low Reset
        ghr_in = 8'h00;   // Initialize input so it isn't floating 'X'
        
        // Wait 15ns to ensure the asynchronous reset clears the flip-flops
        #15;
        rst_bar = 1;      // Release Reset
        #1; // Wait 1ns for output to stabilize before checking
        check_result("Reset state        ", 8'b00000000);

        // --------------------------------------------------------
        // TEST 1: Load an arbitrary pattern
        // --------------------------------------------------------
        #9; // Align with clock edge
        ghr_in = 8'b10101010; // Put data on the wire
        #10; // Wait for the rising edge to capture it
        #1;  // Small delay for output propagation
        check_result("Loaded Pattern     ", 8'b10101010);

        // --------------------------------------------------------
        // TEST 2: Simulate shifting a '1' (What your outside MUX will do)
        // --------------------------------------------------------
        #9;
        ghr_in = {ghr_out[6:0], 1'b1}; // Shift left, insert 1
        #10; 
        #1;
        check_result("Shifted in '1'     ", 8'b01010101);

        // --------------------------------------------------------
        // TEST 3: Simulate shifting a '0'
        // --------------------------------------------------------
        #9;
        ghr_in = {ghr_out[6:0], 1'b0}; // Shift left, insert 0
        #10; 
        #1;
        check_result("Shifted in '0'     ", 8'b10101010);

        // --------------------------------------------------------
        // TEST 4: Simulate Holding (Enable = 0 scenario)
        // --------------------------------------------------------
        #9;
        ghr_in = ghr_out; // Feed output directly back into input
        #10;
        #1;
        check_result("Hold State         ", 8'b10101010);

        $display("=======================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule