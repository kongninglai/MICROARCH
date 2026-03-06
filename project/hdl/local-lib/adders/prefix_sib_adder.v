
/*
This module computes the sum of the prefix bits and the sib if there is an sib.
Delay: 0.35 + 0.3 = 0.65ns
*/
module prefix_sib_adder (
    input wire [2:0] prefix_num,
    input wire has_sib,
    output wire [2:0] total_offset
);

    //Layer 1: 0.35ns
    wire c1, c2; 
    xor2$ bit0_xor(.out(total_offset[0]), .in0(prefix_num[0]), .in1(has_sib));
    and2$ bit0_and(.out(c1),              .in0(prefix_num[0]), .in1(has_sib));
    xor2$ bit1_xor(.out(total_offset[1]), .in0(prefix_num[1]), .in1(c1));
    and2$ bit1_and(.out(c2),              .in0(prefix_num[1]), .in1(c1));

    // Layer 2: 0.3ns
    xor2$ bit2_xor(.out(total_offset[2]), .in0(prefix_num[2]), .in1(c2));

endmodule