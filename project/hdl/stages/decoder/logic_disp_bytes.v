module logic_disp_bytes(
    input wire [7:0] cache_bytes [2:10],
    input wire [7:0] modrm_byte,
    input wire is_modrm_true,
    input wire has_sib,
    input wire [2:0] prefix_num,
    output wire [2:0] disp_size_inbytes,
    output wire [1:0] disp_size, 
    output wire [31:0] disp_bytes
);

    //Layer 1: 4.55ns for disp_size to be ready
    wire [1:0] disp_size;
    logic_disp_size LOGIC_DISP_SIZE(
        .modrm_byte(modrm_byte),
        .is_modrm_true(is_modrm_true),
        .prefix_num(prefix_num),
        .disp_size_inbytes(disp_size_inbytes),
        .disp_size(disp_size) //ready after 4.55ns
    );

    wire [2:0] total_offset;
    prefix_sib_adder PREFIX_SIB_ADDER (
        .prefix_num(prefix_num),
        .has_sib(has_sib),
        .total_offset(total_offset)
    );

    wire [31:0] disp_bytes8, disp_bytes32;
    mux8_8$ disp8_byte_mux(.Y(disp_bytes8), .IN0({24'd0, cache_bytes[2]}), .IN1({24'd0, cache_bytes[3]}), 
    .IN2({24'd0, cache_bytes[4]}), .IN3({24'd0, cache_bytes[5]}), .IN4({24'd0, cache_bytes[6]}), 
    .IN5({24'd0, cache_bytes[7]}), .IN6({24'd0, cache_bytes[8]}), .IN7({24'd0, cache_bytes[9]}), 
    .S0(total_offset[0]), .S1(total_offset[1]), .S2(total_offset[2]));
    
    mux8_8$ disp32_byte_mux(.Y(disp_bytes32), 
    .IN0({cache_bytes[5], cache_bytes[4], cache_bytes[3], cache_bytes[2]}), 
    .IN1({cache_bytes[6], cache_bytes[5], cache_bytes[4], cache_bytes[3]}), 
    .IN2({cache_bytes[7], cache_bytes[6], cache_bytes[5], cache_bytes[4]}), 
    .IN3({cache_bytes[8], cache_bytes[7], cache_bytes[6], cache_bytes[5]}), 
    .IN4({cache_bytes[9], cache_bytes[8], cache_bytes[7], cache_bytes[6]}), 
    .IN5({cache_bytes[10], cache_bytes[9], cache_bytes[8], cache_bytes[7]}), 
    .IN6({cache_bytes[11], cache_bytes[10], cache_bytes[9], cache_bytes[8]}), 
    .IN7({cache_bytes[12], cache_bytes[11], cache_bytes[10], cache_bytes[9]}), 
    .S0(total_offset[0]), .S1(total_offset[1]), .S2(total_offset[2]));

    //TODO mux2_32 to choose between the two muxes with select signal being disp_size 

endmodule