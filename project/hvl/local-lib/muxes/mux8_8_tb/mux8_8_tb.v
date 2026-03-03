`timescale 1ns / 1ps

module tb_mux8_8();

    // Inputs
    reg [7:0] IN0, IN1, IN2, IN3, IN4, IN5, IN6, IN7;
    reg S0, S1, S2;

    // Outputs
    wire [7:0] Y;

    // Self-checking variables
    integer i;
    integer errors;
    reg [7:0] test_data [0:7]; // Array to store input values for easy comparison
    reg [7:0] expected_Y;

    // Instantiate the Unit Under Test (UUT)
    mux8_8 uut (
        .Y(Y), 
        .IN0(IN0), .IN1(IN1), .IN2(IN2), .IN3(IN3), 
        .IN4(IN4), .IN5(IN5), .IN6(IN6), .IN7(IN7), 
        .S0(S0), .S1(S1), .S2(S2)
    );

    initial begin
        // 1. Initialize Stimulus Data
        test_data[0] = 8'h11; test_data[1] = 8'h22; 
        test_data[2] = 8'h33; test_data[3] = 8'h44;
        test_data[4] = 8'h55; test_data[5] = 8'h66; 
        test_data[6] = 8'h77; test_data[7] = 8'h88;

        // Apply array values to the physical input wires
        IN0 = test_data[0]; IN1 = test_data[1]; IN2 = test_data[2]; IN3 = test_data[3];
        IN4 = test_data[4]; IN5 = test_data[5]; IN6 = test_data[6]; IN7 = test_data[7];
        
        errors = 0;
        {S2, S1, S0} = 3'b000;

        $display("--------------------------------------------------");
        $display("Starting MUX8_8 Self-Checking Test...");
        $display("--------------------------------------------------");

        // 2. Automated Loop
        for (i = 0; i < 8; i = i + 1) begin
            // Apply select bits
            {S2, S1, S0} = i;
            expected_Y = test_data[i];
            
            // 3. Wait for propagation delay (Structural MUX delay < 1ns)
            #5; 
            
            // 4. Automated Check
            if (Y !== expected_Y) begin
                $display("[ERROR] Select: %b | Expected: %h | Got: %h", {S2, S1, S0}, expected_Y, Y);
                errors = errors + 1;
            end else begin
                $display("[PASS]  Select: %b | Output: %h", {S2, S1, S0}, Y);
            end
        end

        // 5. Final Summary
        $display("--------------------------------------------------");
        if (errors == 0) begin
            $display("TEST RESULT: PASSED");
            $display("All 8 combinations matched correctly.");
        end else begin
            $display("TEST RESULT: FAILED");
            $display("Total Mismatches: %0d", errors);
        end
        $display("--------------------------------------------------");
        
        $finish;
    end
      
endmodule