/*
Module will return the displacement and the size of the displacement in bytes.  
Delay: 5.29ns through disp_bytes  
disp_size_in_bytes is ready at 4.55ns
total_offset is ready at 6.2ns

*/

module logic_disp_bytes(
    input wire [87:0] cache_bits, //bytes 2-12 of the instruction cache
    input wire [7:0] modrm_byte,
    input wire is_modrm_true,
    input wire has_sib,
    input wire [2:0] prefix_num,
    output wire [2:0] disp_size_inbytes,
    output wire [1:0] disp_size, 
    output wire [31:0] disp_bytes
);

    wire [7:0] cache_bytes [2:12];
    genvar i;
    
    // Layer 0: 0.24ns hidden by logic_disp_size latency
    generate
        for (i = 2; i <= 12; i = i + 1) begin : unpack_and_buffer_cache
            buffer8$ cache_buf (
                .out(cache_bytes[i]), 
                .in(cache_bits[((i-2)*8) + 7 : ((i-2)*8)])
            );
        end
    endgenerate

    //Layer 1: 4.55ns for disp_size to be ready
    logic_disp_size LOGIC_DISP_SIZE(
        .modrm_byte(modrm_byte),
        .is_modrm_true(is_modrm_true),
        .prefix_num(prefix_num),
        .disp_size_inbytes(disp_size_inbytes),
        .disp_size(disp_size) //ready after 4.55ns
    );

    //Is done within Layer 1 because starts running at 3.49 and takes 1 ns to complete (4.49ns total < 4.55ns)
    wire [2:0] total_offset; 
    prefix_modrm_sib_adder PREFIX_MODRM_SIB_ADDER ( // 1ns
        .prefix_num(prefix_num),
        .has_modrm(is_modrm_true), //ready at 4.2ns
        .has_sib(has_sib), //ready at 3.49 ns
        .total_offset(total_offset) //ready at 6.2ns 
    );

    //Layer 2: takes 0.8ns (starts running at 4.49 + 0.8ns = 5.29ns done)
    wire [31:0] disp_bytes8, disp_bytes32;
    mux8_32 disp8_byte_mux(.Y(disp_bytes8), .IN0({24'd0, cache_bytes[2]}), .IN1({24'd0, cache_bytes[3]}), 
    .IN2({24'd0, cache_bytes[4]}), .IN3({24'd0, cache_bytes[5]}), .IN4({24'd0, cache_bytes[6]}), 
    .IN5({24'd0, cache_bytes[7]}), .IN6({24'd0, cache_bytes[8]}), .IN7({24'd0, cache_bytes[9]}), 
    .S0(total_offset[0]), .S1(total_offset[1]), .S2(total_offset[2]));
    
    mux8_32 disp32_byte_mux(.Y(disp_bytes32), 
    .IN0({cache_bytes[5], cache_bytes[4], cache_bytes[3], cache_bytes[2]}), 
    .IN1({cache_bytes[6], cache_bytes[5], cache_bytes[4], cache_bytes[3]}), 
    .IN2({cache_bytes[7], cache_bytes[6], cache_bytes[5], cache_bytes[4]}), 
    .IN3({cache_bytes[8], cache_bytes[7], cache_bytes[6], cache_bytes[5]}), 
    .IN4({cache_bytes[9], cache_bytes[8], cache_bytes[7], cache_bytes[6]}), 
    .IN5({cache_bytes[10], cache_bytes[9], cache_bytes[8], cache_bytes[7]}), 
    .IN6({cache_bytes[11], cache_bytes[10], cache_bytes[9], cache_bytes[8]}), 
    .IN7({cache_bytes[12], cache_bytes[11], cache_bytes[10], cache_bytes[9]}), 
    .S0(total_offset[0]), .S1(total_offset[1]), .S2(total_offset[2]));

    //Layer 3: 0.3ns through select signal (ready at 4.55ns + 0.3ns = 4.85ns)
    mux4_32 disp_byte_mux(.Y(disp_bytes), .IN0(32'd0), .IN1(disp_bytes8), .IN2(disp_bytes32), .IN3(32'd0), .S0(disp_size[0]), .S1(disp_size[1]));
endmodule