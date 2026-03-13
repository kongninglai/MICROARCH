`timescale 1ns / 1ps

module tb_mux16_48();

    // Inputs
    reg [47:0] IN0, IN1, IN2, IN3, IN4, IN5, IN6, IN7;
    reg [47:0] IN8, IN9, IN10, IN11, IN12, IN13, IN14, IN15;
    reg [3:0] S; // Vector to loop through S3..S0 easily

    // Output
    wire [47:0] Y;

    // Testbench Variables
    integer i;
    integer error_count = 0;
    reg [47:0] expected_val;
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // Instantiate the Unit Under Test (UUT)
    mux16_48 uut (
        .Y(Y),
        .IN0(IN0),   .IN1(IN1),   .IN2(IN2),   .IN3(IN3),
        .IN4(IN4),   .IN5(IN5),   .IN6(IN6),   .IN7(IN7),
        .IN8(IN8),   .IN9(IN9),   .IN10(IN10), .IN11(IN11),
        .IN12(IN12), .IN13(IN13), .IN14(IN14), .IN15(IN15),
        .S0(S[0]), .S1(S[1]), .S2(S[2]), .S3(S[3])
    );

    initial begin
        // Initialize Inputs with unique values to test 16-bit slice routing
        // Format: 48'h[HighSlice]_[MidSlice]_[LowSlice]
        IN0  = 48'h00AA_00BB_00CC;  IN1  = 48'h11AA_11BB_11CC;
        IN2  = 48'h22AA_22BB_22CC;  IN3  = 48'h33AA_33BB_33CC;
        IN4  = 48'h44AA_44BB_44CC;  IN5  = 48'h55AA_55BB_55CC;
        IN6  = 48'h66AA_66BB_66CC;  IN7  = 48'h77AA_77BB_77CC;
        IN8  = 48'h88AA_88BB_88CC;  IN9  = 48'h99AA_99BB_99CC;
        IN10 = 48'hAAAA_AABB_AACC;  IN11 = 48'hBBAA_BBBB_BBCC;
        IN12 = 48'hCCAA_CCBB_CCCC;  IN13 = 48'hDDAA_DDBB_DDCC;
        IN14 = 48'hEEAA_EEBB_EECC;  IN15 = 48'hFFAA_FFBB_FFCC;

        S = 4'b0000;

        $display("==================================================================================");
        $display("Starting Self-Checking TB for mux16_48...");
        $display("==================================================================================");
        $display("Sel | Expected Y   | Actual Y     | Status");
        $display("----------------------------------------------------------------------------------");

        // Wait for global reset
        #10; 

        // Loop through all 16 select states
        for (i = 0; i <= 15; i = i + 1) begin
            S = i[3:0]; // Apply the select bits

            // Determine behavioral expected value
            case (S)
                4'd0:  expected_val = IN0;   4'd1:  expected_val = IN1;
                4'd2:  expected_val = IN2;   4'd3:  expected_val = IN3;
                4'd4:  expected_val = IN4;   4'd5:  expected_val = IN5;
                4'd6:  expected_val = IN6;   4'd7:  expected_val = IN7;
                4'd8:  expected_val = IN8;   4'd9:  expected_val = IN9;
                4'd10: expected_val = IN10;  4'd11: expected_val = IN11;
                4'd12: expected_val = IN12;  4'd13: expected_val = IN13;
                4'd14: expected_val = IN14;  4'd15: expected_val = IN15;
            endcase

            // Wait 5ns for combinational logic delay (well past the 1.1ns worst case)
            #5; 

            // Verify Actual vs Expected
            if (Y !== expected_val) begin
                $display("%2d  | %h | %h | ❌ FAIL", S, expected_val, Y);
                error_count = error_count + 1;
                FAILURES = FAILURES + 1;
            end else begin
                $display("%2d  | %h | %h | ✅ PASS", S, expected_val, Y);
                SUCCESSES = SUCCESSES + 1;
            end
        end

        // Final Result Summary
        $display("==================================================================================");
        if (error_count == 0) begin
            $display("🎉 ALL TESTS PASSED! (0 Errors)");
        end else begin
            $display("💥 TEST SUITE FAILED! (%0d Errors Found)", error_count);
        end
        $display("==================================================================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule