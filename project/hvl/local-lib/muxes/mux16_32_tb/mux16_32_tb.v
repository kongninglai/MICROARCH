`timescale 1ns / 1ps

module tb_mux16_32();

    // Inputs
    reg [31:0] IN0,  IN1,  IN2,  IN3,  IN4,  IN5,  IN6,  IN7;
    reg [31:0] IN8,  IN9,  IN10, IN11, IN12, IN13, IN14, IN15;
    reg [3:0]  S; // Vector to loop through selects easily (S[3]=S3, S[2]=S2...)

    // Output
    wire [31:0] Y;

    // Self-checking variables
    integer i;
    integer error_count = 0;
    reg [31:0] expected_val;
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // Instantiate the UUT
    mux16_32 uut (
        .Y(Y),
        .IN0(IN0),   .IN1(IN1),   .IN2(IN2),   .IN3(IN3),
        .IN4(IN4),   .IN5(IN5),   .IN6(IN6),   .IN7(IN7),
        .IN8(IN8),   .IN9(IN9),   .IN10(IN10), .IN11(IN11),
        .IN12(IN12), .IN13(IN13), .IN14(IN14), .IN15(IN15),
        .S0(S[0]), .S1(S[1]), .S2(S[2]), .S3(S[3])
    );

    initial begin
        // Assign unique magic numbers to each input to trace them easily
        IN0  = 32'h0000_0000; IN1  = 32'h1111_1111; IN2  = 32'h2222_2222; IN3  = 32'h3333_3333;
        IN4  = 32'h4444_4444; IN5  = 32'h5555_5555; IN6  = 32'h6666_6666; IN7  = 32'h7777_7777;
        IN8  = 32'h8888_8888; IN9  = 32'h9999_9999; IN10 = 32'hAAAA_AAAA; IN11 = 32'hBBBB_BBBB;
        IN12 = 32'hCCCC_CCCC; IN13 = 32'hDDDD_DDDD; IN14 = 32'hEEEE_EEEE; IN15 = 32'hFFFF_FFFF;

        S = 4'b0000;

        $display("==========================================================");
        $display("Starting Self-Checking TB for mux16_32...");
        $display("==========================================================");
        $display("Sel | Expected Y | Actual Y   | Status");
        $display("----------------------------------------------------------");

        #10; // Wait for global reset

        // Loop through all 16 select states
        for (i = 0; i <= 15; i = i + 1) begin
            S = i[3:0]; // Apply the select bits

            // Determine behavioral expected value
            case (S)
                4'd0:  expected_val = IN0;  4'd1:  expected_val = IN1;
                4'd2:  expected_val = IN2;  4'd3:  expected_val = IN3;
                4'd4:  expected_val = IN4;  4'd5:  expected_val = IN5;
                4'd6:  expected_val = IN6;  4'd7:  expected_val = IN7;
                4'd8:  expected_val = IN8;  4'd9:  expected_val = IN9;
                4'd10: expected_val = IN10; 4'd11: expected_val = IN11;
                4'd12: expected_val = IN12; 4'd13: expected_val = IN13;
                4'd14: expected_val = IN14; 4'd15: expected_val = IN15;
            endcase

            // Wait for combinational logic delay (0.8ns + 0.3ns = 1.1ns total)
            #5; 

            // Check actual vs expected
            if (Y !== expected_val) begin
                $display("%2d  | %h | %h | ❌ FAIL", S, expected_val, Y);
                error_count = error_count + 1;
                FAILURES = FAILURES + 1;
            end else begin
                $display("%2d  | %h | %h | ✅ PASS", S, expected_val, Y);
                SUCCESSES = SUCCESSES + 1;
            end
        end

        // Summary
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