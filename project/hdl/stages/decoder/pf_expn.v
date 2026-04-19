/*
This module takes 16 input page fault exception vector (each bit corresponds to one of the 16 top bytes in cache line 
since this is the only place an instruction can be read), and outputs whether there is a page fault in the current
intstruction. 

Delay: 7.23ns total
0.35ns * 15 = 5.25ns 
(instruction length is ready at 6.23 -> so the mux select will take 1ns at worst.
6.23 + 1ns = 7.23ns
*/

module pf_expn(
    input wire [15:0] pf_expn_bytes,
    input wire [3:0] instr_len,  
    output wire [1:0] exception_flags // [1] = Prot (unused here), [0] = Page Fault
);

    wire [15:0] or_chain;
    assign or_chain[0] = pf_expn_bytes[0];
    
    or2$ g1 (or_chain[1],  or_chain[0], pf_expn_bytes[1]);
    or2$ g2 (or_chain[2],  or_chain[1], pf_expn_bytes[2]);
    or2$ g3 (or_chain[3],  or_chain[2], pf_expn_bytes[3]);
    or2$ g4 (or_chain[4],  or_chain[3], pf_expn_bytes[4]);
    or2$ g5 (or_chain[5],  or_chain[4], pf_expn_bytes[5]);
    or2$ g6 (or_chain[6],  or_chain[5], pf_expn_bytes[6]);
    or2$ g7 (or_chain[7],  or_chain[6], pf_expn_bytes[7]);
    or2$ g8 (or_chain[8],  or_chain[7], pf_expn_bytes[8]);
    or2$ g9 (or_chain[9],  or_chain[8], pf_expn_bytes[9]);
    or2$ g10(or_chain[10], or_chain[9], pf_expn_bytes[10]);
    or2$ g11(or_chain[11], or_chain[10], pf_expn_bytes[11]);
    or2$ g12(or_chain[12], or_chain[11], pf_expn_bytes[12]);
    or2$ g13(or_chain[13], or_chain[12], pf_expn_bytes[13]);
    or2$ g14(or_chain[14], or_chain[13], pf_expn_bytes[14]);
    or2$ g15(or_chain[15], or_chain[14], pf_expn_bytes[15]);
    
    wire pf_final;
    mux16 select_pf(
        .outb(pf_final),
        .s0(instr_len[0]), .s1(instr_len[1]), .s2(instr_len[2]), .s3(instr_len[3]),
        .in0(1'b0),         // Length 0 (invalid)
        .in1(or_chain[0]), 
        .in2(or_chain[1]),  
        .in3(or_chain[2]),  
        .in4(or_chain[3]),  
        .in5(or_chain[4]),
        .in6(or_chain[5]),
        .in7(or_chain[6]),
        .in8(or_chain[7]),
        .in9(or_chain[8]),
        .in10(or_chain[9]),
        .in11(or_chain[10]),
        .in12(or_chain[11]),
        .in13(or_chain[12]),
        .in14(or_chain[13]),
        .in15(or_chain[14]) 
    );

    assign exception_flags = {1'b0, pf_final};

endmodule