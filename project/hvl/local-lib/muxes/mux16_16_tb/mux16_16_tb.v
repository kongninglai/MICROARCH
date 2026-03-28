`timescale 1ns / 1ps

module tb_mux16_16();

    // Inputs
    reg [15:0] IN0, IN1, IN2, IN3, IN4, IN5, IN6, IN7;
    reg [15:0] IN8, IN9, IN10, IN11, IN12, IN13, IN14, IN15;
    reg [3:0] S; // Vector to loop through S3..S0 easily

    // Output
    wire [15:0] Y;

    // Testbench Variables
    integer i;
    integer error_count = 0;
    reg [15:0] expected_val;
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // Instantiate the Unit Under Test (UUT)
    mux16_16 uut (
        .Y(Y),
        .IN0(IN0),   .IN1(IN1),   .IN2(IN2),   .IN3(IN3),
        .IN4(IN4),   .IN5(IN5),   .IN6(IN6),   .IN7(IN7),
        .IN8(IN8),   .IN9(IN9),   .IN10(IN10), .IN11(IN11),
        .IN12(IN12), .IN13(IN13), .IN14(IN14), .IN15(IN15),
        .S0(S[0]), .S1(S[1]), .S2(S[2]), .S3(S[3])
    );

    initial begin
        // Initialize Inputs with unique values to test byte-slicing
        // Upper bytes and lower bytes are deliberately different
        IN0  = 16'h00_A0;  IN1  = 16'h11_B1;  IN2  = 16'h22_C2;  IN3  = 16'h33_D3;
        IN4  = 16'h44_E4;  IN5  = 16'h55_F5;  IN6  = 16'h66_A6;  IN7  = 16'h77_B7;
        IN8  = 16'h88_C8;  IN9  = 16'h99_D9;  IN10 = 16'hAA_EA;  IN11 = 16'hBB_FB;
        IN12 = 16'hCC_AC;  IN13 = 16'hDD_BD;  IN14 = 16'hEE_CE;  IN15 = 16'hFF_DF;

        S = 4'b0000;

        $display("==========================================================");
        $display("Starting Self-Checking TB for mux16_16...");
        $display("==========================================================");
        $display("Sel | Expected Y | Actual Y   | Status");
        $display("----------------------------------------------------------");

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
                $display("%2d  |   %h   |   %h   | ❌ FAIL", S, expected_val, Y);
                error_count = error_count + 1;
                FAILURES = FAILURES + 1;
            end else begin
                $display("%2d  |   %h   |   %h   | ✅ PASS", S, expected_val, Y);
                SUCCESSES = SUCCESSES + 1;
            end
        end

        // Final Result Summary
        $display("==========================================================");
        if (error_count == 0) begin
            $display("🎉 ALL TESTS PASSED! (0 Errors)");
        end else begin
            $display("💥 TEST SUITE FAILED! (%0d Errors Found)", error_count);
        end
        $display("==========================================================");
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule