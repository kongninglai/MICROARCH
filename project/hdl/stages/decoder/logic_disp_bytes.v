/*
Module will return the displacement and the size of the displacement in bytes.  
Delay: 5.29ns through disp_bytes  
disp_size_in_bytes is ready at 4.55ns
total_offset is ready at 6.2ns
disp_offset is done at 7.60ns

*/

module logic_disp_bytes(
    input wire [87:0] cache_bits, //bytes 2-12 of the instruction cache
    input wire [7:0] modrm_byte,
    input wire is_modrm_true,
    input wire has_sib,
    input wire [2:0] prefix_num,
    output wire [2:0] disp_size_inbytes,
    output wire [1:0] disp_size, 
    output wire [31:0] disp_bytes,
    output wire [3:0] disp_offset //offset with displacement 
);

    wire [7:0] cache_bytes [2:12];
    genvar i;
    
    // Layer 0: 0.24ns hidden by logic_disp_size latency
    generate
        for (i = 2; i <= 12; i = i + 1) begin : unpack_and_buffer_cache
            assign cache_bytes[i] = cache_bits[((i-2)*8) + 7 : ((i-2)*8)];
        end
    endgenerate

    //Layer 1: 4.55ns for disp_size to be ready
    logic_disp_size LOGIC_DISP_SIZE(
        .modrm_byte(modrm_byte),
        .is_modrm_true(is_modrm_true),
        .prefix_num(prefix_num),
        .disp_size_inbytes(disp_size_inbytes), //ready at 5.05
        .disp_size(disp_size) //ready after 4.55ns
    );

    //Is done within Layer 1 because starts running at 3.49 and takes 1 ns to complete (4.49ns total < 4.55ns)
    wire [2:0] total_offset;  //sum of prefix_num, modrm, and sib bytes
    prefix_modrm_sib_adder PREFIX_MODRM_SIB_ADDER ( // 1ns
        .prefix_num(prefix_num),
        .has_modrm(is_modrm_true), //ready at 4.2ns
        .has_sib(has_sib), //ready at 3.49 ns
        .total_offset(total_offset) //ready at 6.2ns 
    );

    //Layer 2: takes 0.8ns (starts running at 4.49 + 0.8ns = 5.29ns done)
    wire [31:0] disp_bytes8, disp_bytes32;
    mux8_32 disp8_byte_mux(
        .out(disp_bytes8), 
        .in0(32'd0), .in1({24'd0, cache_bytes[2]}), .in2({24'd0, cache_bytes[3]}), 
        .in3({24'd0, cache_bytes[4]}), .in4({24'd0, cache_bytes[5]}), .in5({24'd0, cache_bytes[6]}), 
        .in6({24'd0, cache_bytes[7]}), .in7({24'd0, cache_bytes[8]}), 
        .s0(total_offset[0]), .s1(total_offset[1]), .s2(total_offset[2])
    );
    
    mux8_32 disp32_byte_mux(
        .out(disp_bytes32), 
        .in0(32'd0),
        .in1({cache_bytes[5], cache_bytes[4], cache_bytes[3], cache_bytes[2]}), 
        .in2({cache_bytes[6], cache_bytes[5], cache_bytes[4], cache_bytes[3]}), 
        .in3({cache_bytes[7], cache_bytes[6], cache_bytes[5], cache_bytes[4]}), 
        .in4({cache_bytes[8], cache_bytes[7], cache_bytes[6], cache_bytes[5]}), 
        .in5({cache_bytes[9], cache_bytes[8], cache_bytes[7], cache_bytes[6]}), 
        .in6({cache_bytes[10], cache_bytes[9], cache_bytes[8], cache_bytes[7]}), 
        .in7({cache_bytes[11], cache_bytes[10], cache_bytes[9], cache_bytes[8]}), 
        .s0(total_offset[0]), .s1(total_offset[1]), .s2(total_offset[2])
    );

    //Is done within layer 2: 6.2 + 1.40 = 7.60ns delay done
    p_m_s_d_adder PMSD_adder(
        .p_m_s_in(total_offset), //sum from prefix_modrm_sib_adder; ready at 6.2ns
        .disp_size_inbytes(disp_size_inbytes), //ready at 5.05ns
        .total_offset(disp_offset) 
    );

    // Is done within layer 2: 0.3ns through select signal (ready at 4.55ns + 0.3ns = 4.85ns)
    mux4_32 disp_byte_mux(.out(disp_bytes), .in0(32'd0), .in1(disp_bytes8), .in2(disp_bytes32), .in3(32'd0), .s0(disp_size[0]), .s1(disp_size[1]));
endmodule