/*
Add Prefix Amount (0,1,2,3,4), Opcode Amount (1), Modrm Amount (0, 1), SIB Amount (0,1),
Disp Bytes (0,1,2,4), Immediate Amount (0,1,2,4,6)

Rom Sum: Opcode Amount (1) + Modrm Amount + Imm Amount 

Delay: 3.1ns
5.05 + 3.1ns = Incr Amount Ready at 8.15ns
*/
module logic_incr_amt(
    input wire [2:0] rom_sum, //Ready at 4.2ns
    input wire [2:0] disp_plus_sib, //Ready at 5.05ns
    input wire [2:0] prefix_amount, //Ready at 3.38ns
    output wire [3:0] incr_amt
);
    wire [3:0] sum_1;
    PA_4b PA_4b_sum1 (
      .in0({1'b0,rom_sum}), .in1({1'b0,prefix_amount}),
      .s(sum_1)
    );
    PA_4b PA_4b_incr_amt (
      .in0(sum_1), .in1({1'b0,disp_plus_sib}),
      .s(incr_amt)
    );

endmodule

/*
100 disp
110 sum
100 prefix
001 for sib
----

when sum is 111, imm is 6, there is no displacement i think

*/