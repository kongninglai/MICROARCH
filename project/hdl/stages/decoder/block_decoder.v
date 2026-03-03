module block_decoder(
    input wire [127:0] cache_line,
    input wire [31:0] o_eip_in,
    output wire prefix_rep,
    output wire prefix_op_size, 
    output wire [2:0] prefix_seg_ov_id,
    output wire prefix_ext,
    output wire [7:0] opcode,
    output wire [7:0] modrm,
    output wire [7:0] sib, 
    output wire [1:0] disp_size_mux,
    output wire [31:0] disp, 
    output wire [1:0] imm_size_mux,
    output wire [31:0] imm,
    output wire [1:0] addressing_mode,
    output wire double_imm,
    output wire [31:0] o_eip_out,
    output wire [31:0] i_eip_out
);  

    //Convert Cache Line Bites to Bytes 
    wire [7:0] cache_bytes [0:15]; //Array of 16 individual 8-bit wires
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_byte_split
            assign cache_bytes[i] = cache_line[(i*8) + 7 : (i*8)];
        end
    endgenerate


    //Prefix logic
    wire is_rep, is_op_size, is_seg_ov, is_ext;
    wire [2:0] seg_id, prefix_num;
    logic_true_prefix TRUE_PREFIX(
        .candidate_prefix0(cache_bytes[0]),
        .candidate_prefix1(cache_bytes[1]),
        .candidate_prefix2(cache_bytes[2]),
        .candidate_prefix3(cache_bytes[3]),
        .is_rep_true(is_rep),
        .is_operand_size_override_true(is_op_size),
        .is_seg_ov(is_seg_ov),
        .seg_id(seg_id),
        .ext_op_true(is_ext),
        .prefix_num(prefix_num)
    );

    //Modrm logic
    

endmodule