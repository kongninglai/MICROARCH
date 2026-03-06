
/*
This module is a 3 bit adder. This module computes total_offset = prefix_num + has_modrm + has_sib

Delay: 
0.35 + 0.35 + 0.3 = 1 ns for modrm and sib calculation. Modrm signal is ready at 4.2ns + 1ns to execute is done at 5.2ns 
with temp_sum. Then has_sib has already arrived by then and can spend 1 ns executing 5.2 + 1ns = 6.2ns total delay for total_offset

*/

module prefix_modrm_sib_adder (
    input wire [2:0] prefix_num,
    input wire has_modrm, //ready at 4.2ns
    input wire has_sib, //ready at 4.55ns
    output wire [2:0] total_offset
);

    wire [2:0] temp_sum;
    wire c1_m, c2_m; 

    // Layer 1: 0.35ns
    xor2$ stg1_b0_xor(.out(temp_sum[0]), .in0(prefix_num[0]), .in1(has_modrm));
    and2$ stg1_b0_and(.out(c1_m),        .in0(prefix_num[0]), .in1(has_modrm));

    // Layer 2: 0.35ns
    xor2$ stg1_b1_xor(.out(temp_sum[1]), .in0(prefix_num[1]), .in1(c1_m));
    and2$ stg1_b1_and(.out(c2_m),        .in0(prefix_num[1]), .in1(c1_m));

    //Layer 3: 0.3ns
    xor2$ stg1_b2_xor(.out(temp_sum[2]), .in0(prefix_num[2]), .in1(c2_m)); //modrm addition done at 4.2ns + 1ns = 5.2ns

    //Layer 4: 
    wire c1_s, c2_s; 
    xor2$ stg2_b0_xor(.out(total_offset[0]), .in0(temp_sum[0]), .in1(has_sib)); //has_sib can start at 5.2 after modrm finishes
    and2$ stg2_b0_and(.out(c1_s),            .in0(temp_sum[0]), .in1(has_sib));

    // Bit 1
    xor2$ stg2_b1_xor(.out(total_offset[1]), .in0(temp_sum[1]), .in1(c1_s));
    and2$ stg2_b1_and(.out(c2_s),            .in0(temp_sum[1]), .in1(c1_s));

    // Bit 2 (No carry out needed, max value of Stage 2 is 5 + 1 = 6)
    xor2$ stg2_b2_xor(.out(total_offset[2]), .in0(temp_sum[2]), .in1(c2_s));

endmodule