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

    //Layer 1:
    //buffer$ opcode7_buffer(.out(opcode7_buf), .in(opcode[7]))
    inv1$ opcode7_inv(.out(opcode7_bar), .in(opcode7_buf))

    //Layer 2: 1 ns
    // BANK 0: Standard Opcodes (ext = 0, op_size = 0)
    rom32b32w$ ROM_STD_LO (.A(opcode[6:2]), .OE(opcode7_bar), .DOUT(bus_std));
    rom32b32w$ ROM_STD_HI (.A(opcode[6:2]), .OE(opcode[7]), .DOUT(bus_std));

    // BANK 1: Operand Size Override (ext = 0, op_size = 1)
    rom32b32w$ ROM_OSO_LO (.A(opcode[6:2]), .OE(opcode7_bar), .DOUT(bus_oso));
    rom32b32w$ ROM_OSO_HI (.A(opcode[6:2]), .OE(opcode[7]), .DOUT(bus_oso));

    // BANK 2: Extended 0F Opcodes (ext = 1, op_size = 0)
    rom32b32w$ ROM_EXT_LO (.A(opcode[6:2]), .OE(opcode7_bar), .DOUT(bus_ext));
    rom32b32w$ ROM_EXT_HI (.A(opcode[6:2]), .OE(opcode[7]), .DOUT(bus_ext));

    // BANK 3: Extended 0F + Override (ext = 1, op_size = 1)
    rom32b32w$ ROM_EXT_OSO_LO (.A(opcode[6:2]), .OE(opcode7_bar), .DOUT(bus_ext_oso));
    rom32b32w$ ROM_EXT_OSO_HI (.A(opcode[6:2]), .OE(opcode[7]), .DOUT(bus_ext_oso));

    //Layer 3: 0.5ns (worse case through select)
    wire [31:0] active_row;
    mux4_32 choose_bank(.Y(active_row), .IN0(bus_std), .IN1(bus_oso), .IN2(bus_ext), .IN3(bus_ext_oso), .S0(op_size), .S1(ext))

    //Layer 4: 0.22ns (worst case through select, but opcode[1:0] is ready so no wait)
    wire [7:0] info_byte;
    mux4_8$ choose_byte_inromrow(.Y(info_byte), .IN0(bus_std), .IN1(bus_oso), .IN2(bus_ext), .IN3(bus_ext_oso), .S0(opcode[1:0]), .S1(opcode[1:0]))

    assign is_modrm = info_byte[7];
    assign imm_size_inbytes = info_byte[6:4];
    assign sum_modrm_imm = info_byte[3:1];
    assign is_far_br = info_byte[0]

    initial begin
            //initial readmemh("rom/rom_modrm_imm.data", ROM12.mem);
    end

endmodule
