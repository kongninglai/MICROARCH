module block_decoder(
    input wire [127:0] cache_line,
    output wire prefix_rep,
    output wire prefix_op_size, 
    output wire [2:0] prefix_seg_ov_id,
    output wire prefix_seg,
    output wire prefix_ext,
    output wire [7:0] opcode,
    output wire [7:0] modrm,
    output wire modrm_v,
    output wire [7:0] sib, 
    output wire [1:0] disp_size_mux,
    output wire [31:0] disp, 
    output wire [2:0] imm_size, //in bytes
    output wire [47:0] imm,
    output wire [1:0] addressing_mode,
    output wire [3:0] instr_length,
    output wire [95:0] ucode_sigs
);      


    // Buffers all 128 bits of the cache line at once
    wire [127:0] cache_line_buf;
    genvar k;
    generate
        for (k = 0; k < 128; k = k + 1) begin : gen_cache_buffers
            bufferH64$ bit_driver (
                .out(cache_line_buf[k]), 
                .in(cache_line[k])
            );
        end
    endgenerate

    //Convert Cache Line Bites to Bytes 
    wire [7:0] cache_bytes [0:15]; //Array of 16 individual 8-bit wires
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_byte_split
            assign cache_bytes[i] = cache_line_buf[(i*8) + 7 : (i*8)];
        end
    endgenerate

    //Prefix logic
    wire is_rep, is_op_size, is_seg_ov, is_ext;
    wire [2:0] seg_id;
    
    wire [1:0] prefix_num, prefix_num_prebuf;
    logic_true_prefix TRUE_PREFIX(
        .candidate_prefix0(cache_bytes[0]),
        .candidate_prefix1(cache_bytes[1]),
        .candidate_prefix2(cache_bytes[2]),
        .is_rep_true(is_rep),
        .is_operand_size_override_true(is_op_size),
        .is_seg_ov(is_seg_ov),
        .seg_id(seg_id),
        .ext_op_true(is_ext),
        .prefix_num(prefix_num_prebuf) //signal ready at 3.38ns
    );

    bufferH64$    bufferH64$_prefix_num[1:0](prefix_num, prefix_num_prebuf);
    assign prefix_rep = is_rep;
    bufferH16$  bufferH16$_prefix_op_size(prefix_op_size, is_op_size);
    assign prefix_seg_ov_id = seg_id;
    bufferH16$  bufferH16$_prefix_seg(prefix_seg, is_seg_ov);
    bufferH16$  bufferH16$_prefix_ext(prefix_ext, is_ext);

    //Opcode Logic
    wire [7:0] opcode_byte_true;
    mux4_8$ opcode_mux (
        .Y(opcode_byte_true),
        .IN0(cache_bytes[0]),
        .IN1(cache_bytes[1]),
        .IN2(cache_bytes[2]),
        .IN3(cache_bytes[3]),
        .S0(prefix_num[0]),
        .S1(prefix_num[1])
    );
    bufferH256$  bufferH256$_opcode[7:0](opcode, opcode_byte_true);

    //Modrm logic
    wire [7:0] modrm_byte_true;
    wire is_modrm_true, is_far_br_true;
    wire [2:0] imm_size_inbytes_true, sum_modrm_imm_true, sib_idx;
    wire [1:0] imm_size_true;
    logic_true_modrm LOGIC_TRUE_MODRM(
        .candidate_opcode0(cache_bytes[0]),
        .candidate_opcode1(cache_bytes[1]),
        .candidate_opcode2(cache_bytes[2]),
        .candidate_opcode3(cache_bytes[3]),
        .candidate_opcode4(cache_bytes[4]),
        .candidate_opcode5(cache_bytes[5]),
        .ext(is_ext),
        .op_size(is_op_size),
        .prefix_num(prefix_num),
        .modrm_byte_true(modrm_byte_true),
        .is_modrm_true(is_modrm_true), //signal ready at 4.2ns
        .imm_size_inbytes_true(imm_size_inbytes_true),
        .imm_size_true(imm_size_true), 
        .sum_modrm_imm_true(sum_modrm_imm_true),
        .is_far_br_true(is_far_br_true)
    );
    bufferH16$  bufferH16$_modrm[7:0](modrm, modrm_byte_true);
    bufferH16$  bufferH16$_modrm_v(modrm_v, is_modrm_true);

    //Sib logic
    wire is_sib_true;
    wire [7:0]sib_byte_true;
    logic_sib_byte LOGIC_SIB_BYTE(
        .candidate_modrm1(cache_bytes[1]),
        .candidate_modrm2(cache_bytes[2]),
        .candidate_modrm3(cache_bytes[3]),
        .candidate_modrm4(cache_bytes[4]),
        .candidate_modrm5(cache_bytes[5]),
        .candidate_modrm6(cache_bytes[6]),
        .is_modrm_true(modrm_v),
        .prefix_num(prefix_num),
        .sib_byte_true(sib_byte_true)
    );  
    assign sib = sib_byte_true;
    assign addressing_mode[0] = modrm_v;
    assign addressing_mode[1] = is_sib_true;

    wire [3:0] disp_offset, disp_offset_prebuf; 
    wire [2:0] disp_size_inbytes;
    wire [1:0] disp_size;
    wire [31:0] disp_bytes;
    logic_disp_bytes LOGIC_DISP_BYTES(
        .cache_bits(cache_line_buf[103:16]), //bytes 2-12 of the instruction cache
        .modrm_byte(modrm),
        .is_modrm_true(modrm_v),
        .has_sib(is_sib_true),
        .prefix_num(prefix_num),
        .disp_size_inbytes(disp_size_inbytes),
        .disp_size(disp_size),
        .disp_bytes(disp_bytes),
        .disp_offset(disp_offset_prebuf)
    );
    bufferH16$  bufferH16$_disp_size_mux[1:0](disp_size_mux, disp_size);
    assign disp = disp_bytes;

    bufferH256$   bufferH256$_disp_offset[3:0](disp_offset, disp_offset_prebuf);

    wire [47:0] imm_bytes;
    logic_imm LOGIC_IMM(
        .cache_bits(cache_line_buf[127:8]), 
        .total_offset(disp_offset),
        .imm_size(imm_size_true),
        .imm_bytes(imm_bytes)
    );  
    assign imm_size = imm_size_inbytes_true;
    assign imm = imm_bytes;

    wire [2:0] disp_plus_sib, disp_plus_sib_final;
    wire [1:0] disp_size_prelim;
    wire [2:0] disp_size_inbytes_prelim;
    wire is_sib_true_prelim;
    logic_sib_disp LOGIC_SIB_DISP(
        .modrm_byte(modrm),
        .disp_plus_sib(disp_plus_sib),
        .disp_size(disp_size_prelim),
        .disp_size_inbytes(disp_size_inbytes_prelim),
        .is_sib_true(is_sib_true_prelim)
    );  
    wire [6:0] dummy_mux_output;
    mux2_16$   mux2_16$_disp_plus_sib_final({dummy_mux_output, is_sib_true, disp_size, disp_size_inbytes, disp_plus_sib_final}, 
                                          {16'd0}, 
                                          {7'd0, is_sib_true_prelim, disp_size_prelim, disp_size_inbytes_prelim, disp_plus_sib}, 
                                          is_modrm_true);


    wire [3:0] instr_length_prebuf;


    wire [3:0] instr_length_prebuf;

    logic_incr_amt EIP_INCR_AMT(
        .rom_sum(sum_modrm_imm_true), //Ready at 4.2ns
        .disp_plus_sib(disp_plus_sib_final), //Ready at 5.05ns
        .prefix_amount(prefix_num), //Ready at 3.38ns
        .incr_amt(instr_length_prebuf)
    );
    
    bufferH64$    bufferH64$_instr_length[3:0](instr_length, instr_length_prebuf);

    to_rr_ucode_lookup UCODE_LOOKUP(
        .opcode(opcode),
        .has_modrm(modrm_v),
        .ext_opcode(prefix_ext),
        .modrm_mode(modrm_byte_true[7:6]),
        .to_rr_ucode_sigs(ucode_sigs)
    );
endmodule

