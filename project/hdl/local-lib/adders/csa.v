/*
This moduel is 5-bit Carry-Save Adder. Takes three 5-bit inputs and compresses them into two 5-bit 
outputs (a Sum vector and a Carry vector). Avoids ripple carry. 
The output carry_vec is already left-shifted by 1 position internally.

Delay: 1.2ns total
*/
module csa(
    input  [4:0] in0, in1, in2,
    output [4:0] sum_vec, carry_vec
);
    wire [4:0] raw_carry;

    genvar i;
    generate
        for (i = 0; i < 5; i = i + 1) begin : csa_logic //1.2ns
            csa_bitslice BITSLICE (
                .a(in0[i]),
                .b(in1[i]),
                .c(in2[i]),
                .sum(sum_vec[i]),
                .carry(raw_carry[i])
            );
        end
    endgenerate

    // Shift the carry vector left by 1 position
    assign carry_vec[0] = 1'b0;
    assign carry_vec[1] = raw_carry[0];
    assign carry_vec[2] = raw_carry[1];
    assign carry_vec[3] = raw_carry[2];
    assign carry_vec[4] = raw_carry[3];

endmodule