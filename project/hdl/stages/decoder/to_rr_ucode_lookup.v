module to_rr_ucode_lookup(
    input [7:0] opcode,
    input has_modrm,
    input ext_opcode,
    input [1:0] modrm_mode,

    output [95:0] to_rr_ucode_sigs
); 
    
    wire [95:0] sig_reg, sig_mem, sig_ext, sig_ext_mem;
    ucoderom #(.MEMFILE64("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_reg64.data"), .MEMFILE32("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_reg32.data")) ucoderom_reg(.opcode(opcode), .sig(sig_reg));
    ucoderom #(.MEMFILE64("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_mem64.data"), .MEMFILE32("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_mem32.data")) ucoderom_mem(.opcode(opcode), .sig(sig_mem));
    ucoderom #(.MEMFILE64("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_ext64.data"), .MEMFILE32("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_ext32.data")) ucoderom_ext(.opcode(opcode), .sig(sig_ext));
    ucoderom #(.MEMFILE64("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_ext_mem64.data"), .MEMFILE32("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_ext_mem32.data")) ucoderom_ext_mem(.opcode(opcode), .sig(sig_ext_mem));

    // ext_opcode/has_modrm: 00 -> sig_reg; 01: modrm==11 ? sig_reg : sig_mem; 10->sig_ext; 11-> modrm==11 ? sig_ext : sig_ext_mem
    wire [95:0] sig_reg_rm, sig_ext_rm;
    wire addr_mode_prebuf;
    wire addr_mode; // 1 for mem mode, 1 for reg mode
    bufferH16$ buffer_addr_mode(addr_mode, addr_mode_prebuf);
    nand2$ nand_addrmode(addr_mode_prebuf, modrm_mode[1], modrm_mode[0]);
    mux2_64 mux2_reg_rm64(.in0(sig_reg[95:32]), .in1(sig_mem[95:32]), .s0(addr_mode), .out(sig_reg_rm[95:32]));
    mux2_32 mux2_reg_rm32(.in0(sig_reg[31:0]), .in1(sig_mem[31:0]), .s0(addr_mode), .out(sig_reg_rm[31:0]));
    mux2_64 mux2_ext_rm64(.in0(sig_ext[95:32]), .in1(sig_ext_mem[95:32]), .s0(addr_mode), .out(sig_ext_rm[95:32]));
    mux2_32 mux2_ext_rm32(.in0(sig_ext[31:0]), .in1(sig_ext_mem[31:0]), .s0(addr_mode), .out(sig_ext_rm[31:0]));

    mux4_64 mux4_sig64(.in0(sig_reg[95:32]), .in1(sig_reg_rm[95:32]), .in2(sig_ext[95:32]), .in3(sig_ext_rm[95:32]), .s0(has_modrm), .s1(ext_opcode), .out(to_rr_ucode_sigs[95:32]));
    mux4_32 mux4_sig32(.in0(sig_reg[31:0]), .in1(sig_reg_rm[31:0]), .in2(sig_ext[31:0]), .in3(sig_ext_rm[31:0]), .s0(has_modrm), .s1(ext_opcode), .out(to_rr_ucode_sigs[31:0]));
endmodule