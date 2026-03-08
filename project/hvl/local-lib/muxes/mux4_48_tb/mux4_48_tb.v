`timescale 1ns / 1ps

module tb_mux4_48();

    // Inputs
    reg [47:0] IN0, IN1, IN2, IN3;
    reg S0, S1;

    // Outputs
    wire [47:0] Y;

    // Error tracking
    integer error_count = 0;
    integer i;
    reg [47:0] expected_Y;

    // Instantiate UUT
    mux4_48 uut (
        .Y(Y),
        .IN0(IN0), .IN1(IN1), .IN2(IN2), .IN3(IN3),
        .S0(S0), .S1(S1)
    );

    initial begin
        // Initialize 48-bit inputs with distinct, recognizable patterns
        IN0 = 48'h0000_1111_2222;
        IN1 = 48'h3333_4444_5555;
        IN2 = 48'h6666_7777_8888;
        IN3 = 48'h9999_AAAA_BBBB;
        
        S0 = 0;
        S1 = 0;

        $display("===============================================================");
        $display("Starting Self-Checking TB for mux4_48...");
        $display("===============================================================");

        // Wait a bit for initial global resets
        #10;

        // Loop through all 4 possible Select combinations
        for (i = 0; i < 4; i = i + 1) begin
            // Assign loop variable to select pins
            {S1, S0} = i[1:0];
            
            // Determine expected behaviorally
            case(i[1:0])
                2'b00: expected_Y = IN0;
                2'b01: expected_Y = IN1;
                2'b10: expected_Y = IN2;
                2'b11: expected_Y = IN3;
            endcase

            // Wait for max select delay (0.5ns)
            #5; 

            // Verify Actual vs Expected
            if (Y !== expected_Y) begin
                $display("❌ FAIL | S1:S0 = %b%b | Expected: %h | Got: %h", S1, S0, expected_Y, Y);
                error_count = error_count + 1;
            end else begin
                $display("✅ PASS | S1:S0 = %b%b | Successfully selected %h", S1, S0, expected_Y);
            end
        end

        // Final Result Summary
        $display("===============================================================");
        if (error_count == 0) begin
            $display("🎉 ALL TESTS PASSED! (0 Errors) - 48-bit multiplexer is solid.");
        end else begin
            $display("💥 TEST SUITE FAILED! (%0d Errors Found)", error_count);
        end
        $display("===============================================================");
        
        $finish;
    end
endmodule