/*
Module that adds the displacement num to the number of bytes before it (includes opcode, prefixes, modrm, and sib) 
to get the total offset to the displacement bytes.

Delay
Can start running at 6.2ns when the prefix_modrm_sib_adder is done. 
*/
module p_m_s_d_adder(
    input wire [2:0] p_m_s_in, //sum from prefix_modrm_sib_adder; ready at 6.2ns
    input wire [2:0] disp_size_inbytes, //ready at 
);

endmodule