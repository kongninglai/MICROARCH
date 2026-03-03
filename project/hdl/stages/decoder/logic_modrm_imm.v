/*

Critical Path: 
This module runs in parallel with the prefix module in order to determine where the opcode is. Those 
signals (ext and seg ov) are resolved after 2.19ns We then access a single mux to get the lookup info 
depending on what the opcode input was. After we retrieve the correct info byte, we have the modrm and 
imm information. This takes a total time of 2.69ns. 

Critical Path: 2.19ns + 0.5ns = 2.69ns
*/
module logic_modrm_imm(
    input wire [7:0] opcode,
    input wire ext,
    input wire op_size,
    output wire is_modrm,
    output wire [2:0] imm_size_inbytes,
    output wire [2:0] sum_modrm_imm,
    output wire is_far_br
);  

    wire [31:0] bus_std;
    wire [31:0] bus_oso;
    wire [31:0] bus_ext;
    wire [31:0] bus_ext_oso;
    wire opcode7_bar;
    wire opcode7_buf;

    //Layer 1: 0.24 (worst case buffer)
    bufferH16$ opcode7_buffer(.out(opcode7_buf), .in(opcode[7]));
    inv1$ opcode7_inv(.out(opcode7_bar), .in(opcode[7]));

    //Layer 2: 1 ns
    // BANK 0: Standard Opcodes (ext = 0, op_size = 0)
    rom32b32w$ ROM_STD_LO (.A(opcode[6:2]), .OE(opcode7_bar), .DOUT(bus_std));
    rom32b32w$ ROM_STD_HI (.A(opcode[6:2]), .OE(opcode7_buf), .DOUT(bus_std));

    // BANK 1: Operand Size Override (ext = 0, op_size = 1)
    rom32b32w$ ROM_OSO_LO (.A(opcode[6:2]), .OE(opcode7_bar), .DOUT(bus_oso));
    rom32b32w$ ROM_OSO_HI (.A(opcode[6:2]), .OE(opcode7_buf), .DOUT(bus_oso));

    // BANK 2: Extended 0F Opcodes (ext = 1, op_size = 0)
    rom32b32w$ ROM_EXT_LO (.A(opcode[6:2]), .OE(opcode7_bar), .DOUT(bus_ext));
    rom32b32w$ ROM_EXT_HI (.A(opcode[6:2]), .OE(opcode7_buf), .DOUT(bus_ext));

    // BANK 3: Extended 0F + Override (ext = 1, op_size = 1)
    rom32b32w$ ROM_EXT_OSO_LO (.A(opcode[6:2]), .OE(opcode7_bar), .DOUT(bus_ext_oso));
    rom32b32w$ ROM_EXT_OSO_HI (.A(opcode[6:2]), .OE(opcode7_buf), .DOUT(bus_ext_oso));

    //Layer 3: 0.22ns (worst case through select, but opcode[1:0] is ready so no wait)
    wire [7:0] info_byte_std, info_byte_oso, info_byte_ext, info_byte_ext_oso;
    mux4_8$ choose_byte_inromrow_std(.Y(info_byte_std), .IN0(bus_std[7:0]), .IN1(bus_std[15:8]), .IN2(bus_std[23:16]), .IN3(bus_std[31:24]), .S0(opcode[0]), .S1(opcode[1]));
    mux4_8$ choose_byte_inromrow_oso(.Y(info_byte_oso), .IN0(bus_oso[7:0]), .IN1(bus_oso[15:8]), .IN2(bus_oso[23:16]), .IN3(bus_oso[31:24]), .S0(opcode[0]), .S1(opcode[1]));
    mux4_8$ choose_byte_inromrow_ext(.Y(info_byte_ext), .IN0(bus_ext[7:0]), .IN1(bus_ext[15:8]), .IN2(bus_ext[23:16]), .IN3(bus_ext[31:24]), .S0(opcode[0]), .S1(opcode[1]));
    mux4_8$ choose_byte_inromrow_ext_oso(.Y(info_byte_ext_oso), .IN0(bus_ext_oso[7:0]), .IN1(bus_ext_oso[15:8]), .IN2(bus_ext_oso[23:16]), .IN3(bus_ext_oso[31:24]), .S0(opcode[0]), .S1(opcode[1]));

    /*Up until here the logic in this block takes 1.46ns. For the next mux to resolve, we need to wait 2.19 - 1.46ns = 0.73ns.
      Starting from the next mux, we add to the critical path. */

    //Layer 4: 0.5ns (worse case through select)
    wire [7:0] active_byte;
    mux4_8$ choose_bank(.Y(active_byte), .IN0(info_byte_std), .IN1(info_byte_oso), .IN2(info_byte_ext), .IN3(info_byte_ext_oso), .S0(op_size), .S1(ext));

    assign is_modrm = active_byte[7];
    assign imm_size_inbytes = active_byte[6:4];
    assign sum_modrm_imm = active_byte[3:1];
    assign is_far_br = active_byte[0];

    initial begin
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_std_lo.data", ROM_STD_LO.mem);
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_std_hi.data", ROM_STD_HI.mem);
        
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_oso_lo.data", ROM_OSO_LO.mem);
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_oso_hi.data", ROM_OSO_HI.mem);
        
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_ext_lo.data", ROM_EXT_LO.mem);
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_ext_hi.data", ROM_EXT_HI.mem);
        
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_ext_oso_lo.data", ROM_EXT_OSO_LO.mem);
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_ext_oso_hi.data", ROM_EXT_OSO_HI.mem);
    end

endmodule
