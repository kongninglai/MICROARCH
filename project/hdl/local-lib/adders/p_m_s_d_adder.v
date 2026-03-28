/*
Module that adds the displacement num to the number of bytes before it (includes opcode, prefixes, modrm, and sib) 
to get the total offset to the displacement bytes.

Delay
Can start running at 6.2ns when the prefix_modrm_sib_adder is done. 
Delay: 1.40ns
6.2 + 1.40 = 7.60ns total delay
*/
module p_m_s_d_adder(
    input wire [2:0] p_m_s_in, //sum from prefix_modrm_sib_adder; ready at 6.2ns
    input wire [2:0] disp_size_inbytes, //ready at 5.05ns
    output wire [3:0] total_offset 
);

    // Layer 1: 0.35ns
    wire p0, p1, p2; // Propagate signals
    wire g0, g1, g2; // Generate signals
    
    xor2$ x_p0(.out(p0), .in0(p_m_s_in[0]), .in1(disp_size_inbytes[0]));
    and2$ a_g0(.out(g0), .in0(p_m_s_in[0]), .in1(disp_size_inbytes[0]));
    
    xor2$ x_p1(.out(p1), .in0(p_m_s_in[1]), .in1(disp_size_inbytes[1]));
    and2$ a_g1(.out(g1), .in0(p_m_s_in[1]), .in1(disp_size_inbytes[1]));
    
    xor2$ x_p2(.out(p2), .in0(p_m_s_in[2]), .in1(disp_size_inbytes[2]));
    and2$ a_g2(.out(g2), .in0(p_m_s_in[2]), .in1(disp_size_inbytes[2]));

    // Laer 2 & 3 : Parallel Carry Gen
    // C0 = g0 (Ready at 0.35ns)
    wire c0;
    assign c0 = g0; 

    // C1 = g1 | (p1 & g0) 
    // Ready at 1.05ns
    wire p1_g0, c1;
    and2$ a_p1g0(.out(p1_g0), .in0(p1), .in1(g0)); 
    or2$  o_c1(.out(c1), .in0(g1), .in1(p1_g0));   

    // C2 = g2 | (p2 & g1) | (p2 & p1 & g0)
    // Fully flattened to 2-input gates. Ready at 1.40ns
    wire p2_g1, p2_p1_g0, g2_or_p2g1, c2;
    and2$ a_p2g1(.out(p2_g1), .in0(p2), .in1(g1));              // 0.70ns
    and2$ a_p2p1g0(.out(p2_p1_g0), .in0(p2), .in1(p1_g0));      // 1.05ns
    or2$  o_g2_p2g1(.out(g2_or_p2g1), .in0(g2), .in1(p2_g1));   // 1.05ns
    or2$  o_c2(.out(c2), .in0(g2_or_p2g1), .in1(p2_p1_g0));     // 1.40ns

    //Layer 4: sum
    // S0 = p0 (Ready at 0.35ns)
    assign total_offset[0] = p0;

    // S1 = p1 ^ C0 (Ready at 0.70ns)
    xor2$ x_s1(.out(total_offset[1]), .in0(p1), .in1(c0)); 

    // S2 = p2 ^ C1 (Ready at 1.40ns)
    xor2$ x_s2(.out(total_offset[2]), .in0(p2), .in1(c1)); 

    // S3 (Carry Out) = C2 (Ready at 1.40ns)
    assign total_offset[3] = c2; 

endmodule