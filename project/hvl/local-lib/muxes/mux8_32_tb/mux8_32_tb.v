`timescale 1ns / 1ps

module tb_mux8_32();

    // 1. Signals
    reg [31:0] in [0:7];
    reg [2:0]  sel;
    wire [31:0] out;

    // 2. Instantiate UUT
    mux8_32 uut (
        .Y(out),
        .IN0(in[0]), .IN1(in[1]), .IN2(in[2]), .IN3(in[3]),
        .IN4(in[4]), .IN5(in[5]), .IN6(in[6]), .IN7(in[7]),
        .S0(sel[0]), .S1(sel[1]), .S2(sel[2])
    );

    // 3. Test Logic
    integer i;
    initial begin
        $display("---------------------------------------------------------");
        $display("STARTING 32-BIT MUX8 TEST");
        $display("---------------------------------------------------------");

        // Initialize inputs with unique "Signature" patterns
        in[0] = 32'hAAAA_AAAA;
        in[1] = 32'hBBBB_BBBB;
        in[2] = 32'hCCCC_CCCC;
        in[3] = 32'hDDDD_DDDD;
        in[4] = 32'hEEEE_EEEE;
        in[5] = 32'hFFFF_FFFF;
        in[6] = 32'h1234_5678;
        in[7] = 32'h8765_4321;

        // Loop through all 8 select combinations
        for (i = 0; i < 8; i = i + 1) begin
            sel = i[2:0];
            #1; // Wait for mux delay (0.8ns)

            if (out === in[i]) begin
                $display("[PASS] Sel: %0d | Out: %h", i, out);
            end else begin
                $display("[FAIL] Sel: %0d | Got: %h | Exp: %h", i, out, in[i]);
            end
        end

        // 4. Test "X" and "Z" Propagation (Optional but good for EE 382N)
        $display("Testing X propagation...");
        in[4] = 32'hXXXX_XXXX;
        sel = 3'd4;
        #1;
        if (out === 32'hXXXX_XXXX)
            $display("[PASS] X correctly propagated from IN4");

        $display("---------------------------------------------------------");
        $display("TEST COMPLETE");
        $display("---------------------------------------------------------");
        $finish;
    end

endmodule