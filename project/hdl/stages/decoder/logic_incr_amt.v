/*
Add Prefix Amount (0,1,2,3,4), Opcode Amount (1), Modrm Amount (0, 1), SIB Amount (0,1),
Disp Bytes (0,1,2,4), Immediate Amount (0,1,2,4,6)

Rom Sum: Opcode Amount (1) + Modrm Amount + Imm Amount 

Delay: 3.1ns
5.05 + 3.1ns = Incr Amount Ready at 8.15ns
*/
module logic_incr_amt(
    input wire [7:0] opcode,
    input wire [2:0] rom_sum, //Ready at 4.2ns
    input wire [2:0] disp_plus_sib, //Ready at 5.05ns
    input wire [2:0] prefix_amount, //Ready at 3.38ns
    output wire [3:0] incr_amt
);
    wire eq_halt, eq_ret_near, eq_ret_far, eq_ret_near16, eq_ret_far16, eq_iret;
    big_eq #(.WIDTH(8)) halt_cmp(
      .in0(opcode), .in1(8'hF4), .eq(eq_halt)
    );
    big_eq #(.WIDTH(8)) ret_near_cmp(
      .in0(opcode), .in1(8'hC3), .eq(eq_ret_near)
    );
    big_eq #(.WIDTH(8)) ret_far_cmp(
      .in0(opcode), .in1(8'hCB), .eq(eq_ret_far)
    );
    big_eq #(.WIDTH(8)) ret_near16_cmp(
      .in0(opcode), .in1(8'hC2), .eq(eq_ret_near16)
    );
    big_eq #(.WIDTH(8)) ret_far16_cmp(
      .in0(opcode), .in1(8'hCA), .eq(eq_ret_far16)
    );
    big_eq #(.WIDTH(8)) iret_cmp(
      .in0(opcode), .in1(8'hCF), .eq(eq_iret)
    );

    //OR together
    wire nor_out_a, nor_out_b, end_program_sel, end_program_sel_inv;
    nor3$ g0 (nor_out_a, eq_halt, eq_ret_near, eq_ret_far); 
    nor3$ g1 (nor_out_b, eq_ret_near16, eq_ret_far16, eq_iret);
    nand2$ g2 (end_program_sel, nor_out_a, nor_out_b);
    inv1$ inv_end_program_sel (.in(end_program_sel), .out(end_program_sel_inv));

    wire [3:0] sum_1;
    wire [3:0] incr_amt_candidate;
    PA_4b PA_4b_sum1 (
      .in0({1'b0,rom_sum}), .in1({1'b0,prefix_amount}),
      .s(sum_1)
    );
    PA_4b PA_4b_incr_amt (
      .in0(sum_1), .in1({1'b0,disp_plus_sib}),
      .s(incr_amt_candidate)
    );

    //Set increment amount to 0 if end program instruction, else use candidate
    and2$ end_program_and [3:0] (
      .out(incr_amt), .in0(end_program_sel_inv), .in1(incr_amt_candidate)
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