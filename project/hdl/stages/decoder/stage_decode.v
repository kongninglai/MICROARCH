module stage_decode(
    input wire [127:0] cache_line,
    input wire [31:0] o_eip, 
    output wire [31:0] i_eip

);

block_decoder DECODER(
    input wire [127:0] cache_line,
    output wire prefix_rep,
    output wire prefix_op_size, 
    output wire [2:0] prefix_seg_ov_id,
    output wire prefix_ext,
    output wire [7:0] opcode,
    output wire [7:0] modrm,
    output wire [7:0] sib, 
    output wire [1:0] disp_size_mux,
    output wire [31:0] disp, 
    output wire [1:0] imm_size,
    output wire [47:0] imm,
    output wire [1:0] addressing_mode,
    output wire [3:0] instr_length
);     

eip_incr EIP_INCR_LOGIC(
    .incr_amt(instr_length),
    .eip(o_eip),
    .incr_eip(i_eip)
);

endmodule