module ucode_controller(
    output [63:0] ucode_sig,
    input [7:0] opcode,
    input ext_opcode,
    input [1:0] modrm,
    input has_modrm
);
    wire [63:0] sig_reg, sig_mem, sig_ext, sig_ext_mem;
    ucoderom #("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_reg.data") ucoderom_reg(.opcode(opcode), .sig(sig_reg));
    ucoderom #("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_mem.data") ucoderom_mem(.opcode(opcode), .sig(sig_mem));
    ucoderom #("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_ext.data") ucoderom_ext(.opcode(opcode), .sig(sig_ext));
    ucoderom #("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_ext_mem.data") ucoderom_ext_mem(.opcode(opcode), .sig(sig_ext_mem));

    // ext_opcode/has_modrm: 00 -> sig_reg; 01: modrm==11 ? sig_reg : sig_mem; 10->sig_ext; 11-> modrm==11 ? sig_ext : sig_ext_mem
    wire [63:0] sig_reg_rm, sig_ext_rm;
    wire addr_mode; // 1 for mem mode, 1 for reg mode
    nand2$ nand_addrmode(addr_mode, modrm[1], modrm[0]);
    mux2_64 mux2_reg_rm(.in0(sig_reg), .in1(sig_mem), .s0(addr_mode), .out(sig_reg_rm));
    mux2_64 mux2_ext_rm(.in0(sig_ext), .in1(sig_ext_mem), .s0(addr_mode), .out(sig_ext_rm));

    mux4_64 mux4_sig(.in0(sig_reg), .in1(sig_reg_rm), .in2(sig_ext), .in3(sig_ext_rm), .s0(has_modrm), .s1(ext_opcode), .out(ucode_sig));
endmodule