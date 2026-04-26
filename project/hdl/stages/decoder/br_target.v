module br_target(
    input wire [31:0] i_eip,
    input wire [3:0] total_offset, 
    input wire [7:0] opcode,
    input wire [127:0] cache_bits, 
    input wire op_size_overload, //to determine if rel16 or rel32 for certain instructions
    input wire prefix_ext,
    output wire hit, //is this a branch that can be resolved in decode?
    output wire [31:0] bp_eip_target
);  

    //Compare against Opcode
    //75, 77, 0F85, 0F87, E8, E9, EB
    wire eq_jne_rel8, eq_jnbe_rel8, eq_jmp_rel8;
    wire eq_jne_base, eq_jnbe_base, eq_call_base, eq_jmp_base;
    wire eq_jne_rel16, eq_jne_rel32, eq_jnbe_rel16, eq_jnbe_rel32, eq_call_rel16, eq_call_rel32, eq_jmp_rel16, eq_jmp_rel32;
    big_eq #(.WIDTH(8)) cmp_jne_rel8( .in0(opcode), .in1(8'h75), .eq(eq_jne_rel8));
    big_eq #(.WIDTH(8)) cmp_jnbe_rel8( .in0(opcode), .in1(8'h77), .eq(eq_jnbe_rel8));
    big_eq #(.WIDTH(8)) cmp_jne_rel16_32( .in0(opcode), .in1(8'h85), .eq(eq_jne_base));
    big_eq #(.WIDTH(8)) cmp_jnbe_rel16_32( .in0(opcode), .in1(8'h87), .eq(eq_jnbe_base));
    big_eq #(.WIDTH(8)) cmp_call_rel16_32( .in0(opcode), .in1(8'hE8), .eq(eq_call_base));
    big_eq #(.WIDTH(8)) cmp_jmp_rel16_32( .in0(opcode), .in1(8'hE9), .eq(eq_jmp_base));
    big_eq #(.WIDTH(8)) cmp_jmp_rel8( .in0(opcode), .in1(8'hEB), .eq(eq_jmp_rel8));
    
    //Make sure eq is valid only when prefix_ext is not present (to avoid conflicts with xbegin)
    wire eq_jne_base_valid, eq_jnbe_base_valid;
    and2$ and_jne_base_valid( .out(eq_jne_base_valid), .in0(eq_jne_base), .in1(prefix_ext));
    and2$ and_jnbe_base_valid( .out(eq_jnbe_base_valid), .in0(eq_jnbe_base), .in1(prefix_ext));


    //Find rel16 and rel32 variants based on op size override
    wire op_size_overload_bar;
    inv1$ not_op_size_overload( .out(op_size_overload_bar), .in(op_size_overload));
    and2$ and_jne_rel16( .out(eq_jne_rel16), .in0(eq_jne_base_valid), .in1(op_size_overload));
    and2$ and_jnbe_rel16( .out(eq_jnbe_rel16), .in0(eq_jnbe_base_valid), .in1(op_size_overload));
    and2$ and_call_rel16( .out(eq_call_rel16), .in0(eq_call_base), .in1(op_size_overload));
    and2$ and_jmp_rel16( .out(eq_jmp_rel16), .in0(eq_jmp_base), .in1(op_size_overload));
    
    and2$ and_jne_rel32( .out(eq_jne_rel32), .in0(eq_jne_base_valid), .in1(op_size_overload_bar));
    and2$ and_jnbe_rel32( .out(eq_jnbe_rel32), .in0(eq_jnbe_base_valid), .in1(op_size_overload_bar));
    and2$ and_call_rel32( .out(eq_call_rel32), .in0(eq_call_base), .in1(op_size_overload_bar));
    and2$ and_jmp_rel32( .out(eq_jmp_rel32), .in0(eq_jmp_base), .in1(op_size_overload_bar));
    
    //Find if rel8, rel16, or rel32 instruction is hit
    wire is_rel8, is_rel16, is_rel32;
    or3$ or_rel8( .out(is_rel8), .in0(eq_jne_rel8), .in1(eq_jnbe_rel8), .in2(eq_jmp_rel8));
    or4$ or_rel16( .out(is_rel16), .in0(eq_jne_rel16), .in1(eq_jnbe_rel16), .in2(eq_call_rel16), .in3(eq_jmp_rel16));
    or4$ or_rel32( .out(is_rel32), .in0(eq_jne_rel32), .in1(eq_jnbe_rel32), .in2(eq_call_rel32), .in3(eq_jmp_rel32));
    or3$ or_hit( .out(hit), .in0(is_rel8), .in1(is_rel16), .in2(is_rel32));

    //{is_rel32, is_rel16, is_rel8} as one-hot select for mux
    wire [2:0] in_sel;
    assign in_sel = {is_rel32, is_rel16, is_rel8};

    //Derive Branch Target from EIP + offset
    wire [7:0] cache_bytes [1:14];
    genvar i;
    generate
        for (i = 1; i <= 14; i = i + 1) begin : unpack_cache
            assign cache_bytes[i] = cache_bits[(i*8)+7 : (i*8)];
        end
    endgenerate

    wire [31:0] ieip_offset_sum_rel32, ieip_offset_sum_rel16, ieip_offset_sum_rel8;
    wire [31:0] target_rel32_0, target_rel32_1, target_rel32_2, target_rel32_3, target_rel32_4, 
    target_rel32_5, target_rel32_6, target_rel32_7, target_rel32_8, target_rel32_9, target_rel32_10;
    PA_32b TARGET_rel32_adder0(.in0(i_eip), .in1({cache_bytes[4], cache_bytes[3], cache_bytes[2], cache_bytes[1]}), .s(target_rel32_0));
    PA_32b TARGET_rel32_adder1(.in0(i_eip), .in1({cache_bytes[5], cache_bytes[4], cache_bytes[3], cache_bytes[2]}), .s(target_rel32_1));
    PA_32b TARGET_rel32_adder2(.in0(i_eip), .in1({cache_bytes[6], cache_bytes[5], cache_bytes[4], cache_bytes[3]}), .s(target_rel32_2));
    PA_32b TARGET_rel32_adder3(.in0(i_eip), .in1({cache_bytes[7], cache_bytes[6], cache_bytes[5], cache_bytes[4]}), .s(target_rel32_3));
    PA_32b TARGET_rel32_adder4(.in0(i_eip), .in1({cache_bytes[8], cache_bytes[7], cache_bytes[6], cache_bytes[5]}), .s(target_rel32_4));
    PA_32b TARGET_rel32_adder5(.in0(i_eip), .in1({cache_bytes[9], cache_bytes[8], cache_bytes[7], cache_bytes[6]}), .s(target_rel32_5));
    PA_32b TARGET_rel32_adder6(.in0(i_eip), .in1({cache_bytes[10], cache_bytes[9], cache_bytes[8], cache_bytes[7]}), .s(target_rel32_6));
    PA_32b TARGET_rel32_adder7(.in0(i_eip), .in1({cache_bytes[11], cache_bytes[10], cache_bytes[9], cache_bytes[8]}), .s(target_rel32_7));
    PA_32b TARGET_rel32_adder8(.in0(i_eip), .in1({cache_bytes[12], cache_bytes[11], cache_bytes[10], cache_bytes[9]}), .s(target_rel32_8));
    PA_32b TARGET_rel32_adder9(.in0(i_eip), .in1({cache_bytes[13], cache_bytes[12], cache_bytes[11], cache_bytes[10]}), .s(target_rel32_9));
    PA_32b TARGET_rel32_adder10(.in0(i_eip), .in1({cache_bytes[14], cache_bytes[13], cache_bytes[12], cache_bytes[11]}), .s(target_rel32_10));

    mux16_32 imm_byte_mux32(
        .out(ieip_offset_sum_rel32), 
        .in0(target_rel32_0), 
        .in1(target_rel32_1), 
        .in2(target_rel32_2), 
        .in3(target_rel32_3), 
        .in4(target_rel32_4), 
        .in5(target_rel32_5),
        .in6(target_rel32_6),
        .in7(target_rel32_7), 
        .in8(target_rel32_8), 
        .in9(target_rel32_9), 
        .in10(target_rel32_10), 
        .in11(32'd0),
        .in12(32'd0),
        .in13(32'd0),
        .in14(32'd0),
        .in15(32'd0),
        .s0(total_offset[0]), .s1(total_offset[1]), .s2(total_offset[2]), .s3(total_offset[3])
    );
    
    wire [31:0] offset_rel16_ext0, offset_rel16_ext1, offset_rel16_ext2, offset_rel16_ext3, offset_rel16_ext4, 
    offset_rel16_ext5, offset_rel16_ext6, offset_rel16_ext7, offset_rel16_ext8, offset_rel16_ext9, offset_rel16_ext10;
    se #(.INP_WIDTH(16), .OUT_WIDTH(32)) se_rel16_0(.in({cache_bytes[2], cache_bytes[1]}), .out(offset_rel16_ext0));
    se #(.INP_WIDTH(16), .OUT_WIDTH(32)) se_rel16_1(.in({cache_bytes[3], cache_bytes[2]}), .out(offset_rel16_ext1));
    se #(.INP_WIDTH(16), .OUT_WIDTH(32)) se_rel16_2(.in({cache_bytes[4], cache_bytes[3]}), .out(offset_rel16_ext2));
    se #(.INP_WIDTH(16), .OUT_WIDTH(32)) se_rel16_3(.in({cache_bytes[5], cache_bytes[4]}), .out(offset_rel16_ext3));
    se #(.INP_WIDTH(16), .OUT_WIDTH(32)) se_rel16_4(.in({cache_bytes[6], cache_bytes[5]}), .out(offset_rel16_ext4));
    se #(.INP_WIDTH(16), .OUT_WIDTH(32)) se_rel16_5(.in({cache_bytes[7], cache_bytes[6]}), .out(offset_rel16_ext5));
    se #(.INP_WIDTH(16), .OUT_WIDTH(32)) se_rel16_6(.in({cache_bytes[8], cache_bytes[7]}), .out(offset_rel16_ext6));
    se #(.INP_WIDTH(16), .OUT_WIDTH(32)) se_rel16_7(.in({cache_bytes[9], cache_bytes[8]}), .out(offset_rel16_ext7));
    se #(.INP_WIDTH(16), .OUT_WIDTH(32)) se_rel16_8(.in({cache_bytes[10], cache_bytes[9]}), .out(offset_rel16_ext8));
    se #(.INP_WIDTH(16), .OUT_WIDTH(32)) se_rel16_9(.in({cache_bytes[11], cache_bytes[10]}), .out(offset_rel16_ext9));
    se #(.INP_WIDTH(16), .OUT_WIDTH(32)) se_rel16_10(.in({cache_bytes[12], cache_bytes[11]}), .out(offset_rel16_ext10));

    wire [31:0] target_rel16_0, target_rel16_1, target_rel16_2, target_rel16_3, target_rel16_4, 
    target_rel16_5, target_rel16_6, target_rel16_7, target_rel16_8, target_rel16_9, target_rel16_10;
    PA_32b TARGET_rel16_adder0(.in0(i_eip), .in1(offset_rel16_ext0), .s(target_rel16_0));
    PA_32b TARGET_rel16_adder1(.in0(i_eip), .in1(offset_rel16_ext1), .s(target_rel16_1));
    PA_32b TARGET_rel16_adder2(.in0(i_eip), .in1(offset_rel16_ext2), .s(target_rel16_2));
    PA_32b TARGET_rel16_adder3(.in0(i_eip), .in1(offset_rel16_ext3), .s(target_rel16_3));
    PA_32b TARGET_rel16_adder4(.in0(i_eip), .in1(offset_rel16_ext4), .s(target_rel16_4));
    PA_32b TARGET_rel16_adder5(.in0(i_eip), .in1(offset_rel16_ext5), .s(target_rel16_5));
    PA_32b TARGET_rel16_adder6(.in0(i_eip), .in1(offset_rel16_ext6), .s(target_rel16_6));
    PA_32b TARGET_rel16_adder7(.in0(i_eip), .in1(offset_rel16_ext7), .s(target_rel16_7));
    PA_32b TARGET_rel16_adder8(.in0(i_eip), .in1(offset_rel16_ext8), .s(target_rel16_8));
    PA_32b TARGET_rel16_adder9(.in0(i_eip), .in1(offset_rel16_ext9), .s(target_rel16_9));
    PA_32b TARGET_rel16_adder10(.in0(i_eip), .in1(offset_rel16_ext10), .s(target_rel16_10));

    mux16_32 imm_byte_mux16(
        .out(ieip_offset_sum_rel16), 
        .in0(target_rel16_0), 
        .in1(target_rel16_1), 
        .in2(target_rel16_2), 
        .in3(target_rel16_3), 
        .in4(target_rel16_4), 
        .in5(target_rel16_5),
        .in6(target_rel16_6),
        .in7(target_rel16_7), 
        .in8(target_rel16_8), 
        .in9(target_rel16_9), 
        .in10(target_rel16_10), 
        .in11(32'd0),
        .in12(32'd0),
        .in13(32'd0),
        .in14(32'd0),
        .in15(32'd0),
        .s0(total_offset[0]), .s1(total_offset[1]), .s2(total_offset[2]), .s3(total_offset[3])
    );

    wire [31:0] offset_rel8_ext0, offset_rel8_ext1, offset_rel8_ext2, offset_rel8_ext3, offset_rel8_ext4, 
    offset_rel8_ext5, offset_rel8_ext6, offset_rel8_ext7, offset_rel8_ext8, offset_rel8_ext9, offset_rel8_ext10;
    se #(.INP_WIDTH(8), .OUT_WIDTH(32)) se_rel8_0(.in(cache_bytes[1]), .out(offset_rel8_ext0));
    se #(.INP_WIDTH(8), .OUT_WIDTH(32)) se_rel8_1(.in(cache_bytes[2]), .out(offset_rel8_ext1));
    se #(.INP_WIDTH(8), .OUT_WIDTH(32)) se_rel8_2(.in(cache_bytes[3]), .out(offset_rel8_ext2));
    se #(.INP_WIDTH(8), .OUT_WIDTH(32)) se_rel8_3(.in(cache_bytes[4]), .out(offset_rel8_ext3));
    se #(.INP_WIDTH(8), .OUT_WIDTH(32)) se_rel8_4(.in(cache_bytes[5]), .out(offset_rel8_ext4));
    se #(.INP_WIDTH(8), .OUT_WIDTH(32)) se_rel8_5(.in(cache_bytes[6]), .out(offset_rel8_ext5));
    se #(.INP_WIDTH(8), .OUT_WIDTH(32)) se_rel8_6(.in(cache_bytes[7]), .out(offset_rel8_ext6));
    se #(.INP_WIDTH(8), .OUT_WIDTH(32)) se_rel8_7(.in(cache_bytes[8]), .out(offset_rel8_ext7));
    se #(.INP_WIDTH(8), .OUT_WIDTH(32)) se_rel8_8(.in(cache_bytes[9]), .out(offset_rel8_ext8));
    se #(.INP_WIDTH(8), .OUT_WIDTH(32)) se_rel8_9(.in(cache_bytes[10]), .out(offset_rel8_ext9));
    se #(.INP_WIDTH(8), .OUT_WIDTH(32)) se_rel8_10(.in(cache_bytes[11]), .out(offset_rel8_ext10));

    wire [31:0] target_rel8_0, target_rel8_1, target_rel8_2, target_rel8_3, target_rel8_4, 
    target_rel8_5, target_rel8_6, target_rel8_7, target_rel8_8, target_rel8_9, target_rel8_10;
    PA_32b TARGET_rel8_adder0(.in0(i_eip), .in1(offset_rel8_ext0), .s(target_rel8_0));
    PA_32b TARGET_rel8_adder1(.in0(i_eip), .in1(offset_rel8_ext1), .s(target_rel8_1));
    PA_32b TARGET_rel8_adder2(.in0(i_eip), .in1(offset_rel8_ext2), .s(target_rel8_2));
    PA_32b TARGET_rel8_adder3(.in0(i_eip), .in1(offset_rel8_ext3), .s(target_rel8_3));
    PA_32b TARGET_rel8_adder4(.in0(i_eip), .in1(offset_rel8_ext4), .s(target_rel8_4));
    PA_32b TARGET_rel8_adder5(.in0(i_eip), .in1(offset_rel8_ext5), .s(target_rel8_5));
    PA_32b TARGET_rel8_adder6(.in0(i_eip), .in1(offset_rel8_ext6), .s(target_rel8_6));
    PA_32b TARGET_rel8_adder7(.in0(i_eip), .in1(offset_rel8_ext7), .s(target_rel8_7));
    PA_32b TARGET_rel8_adder8(.in0(i_eip), .in1(offset_rel8_ext8), .s(target_rel8_8));
    PA_32b TARGET_rel8_adder9(.in0(i_eip), .in1(offset_rel8_ext9), .s(target_rel8_9));
    PA_32b TARGET_rel8_adder10(.in0(i_eip), .in1(offset_rel8_ext10), .s(target_rel8_10));

    mux16_32 imm_byte_mux8(
        .out(ieip_offset_sum_rel8), 
        .in0(target_rel8_0), 
        .in1(target_rel8_1), 
        .in2(target_rel8_2), 
        .in3(target_rel8_3), 
        .in4(target_rel8_4), 
        .in5(target_rel8_5),
        .in6(target_rel8_6),
        .in7(target_rel8_7), 
        .in8(target_rel8_8), 
        .in9(target_rel8_9), 
        .in10(target_rel8_10), 
        .in11(32'd0),
        .in12(32'd0),
        .in13(32'd0),
        .in14(32'd0),
        .in15(32'd0),
        .s0(total_offset[0]), .s1(total_offset[1]), .s2(total_offset[2]), .s3(total_offset[3])
    );

    //Select the Correct Branch Target 
    wire [2:0] buf_in_sel;
    wire [31:0] prebuf_bp_ep_target;
    bufferH256$ bufferH256$_in_sel[2:0](buf_in_sel, in_sel);
    mux3_onehot DUT(
        .in_sel(buf_in_sel),
        .in0(ieip_offset_sum_rel8), .in1(ieip_offset_sum_rel16), .in2(ieip_offset_sum_rel32),
        .out(bp_eip_target)
    );

endmodule