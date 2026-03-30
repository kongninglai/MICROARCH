/*
Outputs the displacement size given a speculative modrm byte
Delay: 
0.35 + 0.35 + 0.35 = 1.05 is latency that happens in parallel with the rest of decode. 
Displacement logic cannot execute until prefix_num and is_modrm_true are ready, which happens at 3.38ns and 4.2ns. 
[wait 3.15ns for is_modrm_true and prefix_num to be ready]
1.05 + 3.15(wait) + 0.35 + 0.5 = 5.05ns for disp size in bytes to be ready
4.55ns for disp_size to be ready
*/
module logic_disp_size(
    input wire [7:0] modrm_byte,
    input wire is_modrm_true,
    input wire [2:0] prefix_num,
    output wire [2:0] disp_size_inbytes,
    output wire [1:0] disp_size
);

    wire [1:0] mod_bits;
    wire [2:0] rm_bits;
    assign mod_bits = modrm_byte[7:6];
    assign rm_bits = modrm_byte[2:0];

    //Layer 1: 0.35ns worst case     
    wire eq_rm_100, eq_rm_101;
    wire eq_mod_00, eq_mod_01, eq_mod_10, eq_mod_11;
    big_eq #(3) check_rm_101(.in0(rm_bits), .in1(3'b101), .eq(eq_rm_101));
    big_eq #(2) check_mod_00(.in0(mod_bits), .in1(2'b00), .eq(eq_mod_00)); // 0 byte displacement
    big_eq #(2) check_mod_01(.in0(mod_bits), .in1(2'b01), .eq(eq_mod_01)); // 1 byte displacement
    big_eq #(2) check_mod_10(.in0(mod_bits), .in1(2'b10), .eq(eq_mod_10)); // 4 byte displacement
    big_eq #(2) check_mod_11(.in0(mod_bits), .in1(2'b11), .eq(eq_mod_11)); // 0 byte displacement

    //Layer 2: 0.35ns
    wire size_4_bytes, size_1_byte;
    wire mod00_rm101; //4 byte displacement 
    and2$ mod00_and_rm101(.out(mod00_rm101), .in0(eq_mod_00), .in1(eq_rm_101));  
    assign size_1_byte = eq_mod_01;
    
    //Layer 3: 0.35ns
    or2$ size_4_bytes_or(.out(size_4_bytes), .in0(mod00_rm101), .in1(eq_mod_10));

    //Layer 4: 0.35ns
    and2$ mask_bit0(.out(disp_size[0]), .in0(size_1_byte), .in1(is_modrm_true));
    and2$ mask_bit1(.out(disp_size[1]), .in0(size_4_bytes), .in1(is_modrm_true)); 

    //Layer 5: 0.5ns
    wire [7:0] disp_size_inbytes_w;
    mux4_8$ disp_size_mux(.Y(disp_size_inbytes_w), .IN0({5'd0, 3'b000}), .IN1({5'd0, 3'b001}), .IN2({5'd0, 3'b100}), .IN3(8'd0), .S0(disp_size[0]), .S1(disp_size[1]));
    assign disp_size_inbytes = disp_size_inbytes_w[2:0];
endmodule