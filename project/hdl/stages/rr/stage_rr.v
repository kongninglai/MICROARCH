module stage_rr(
    input [4:0] from_de_prefix,
    input from_de_ext_opcode,
    input [7:0] from_de_opcode,
    input from_de_has_modrm,
    input [7:0] from_de_modrm,
    input [7:0] from_de_sib,
    input [31:0] from_de_disp,
    input [47:0] from_de_imm,
    input [1:0] from_de_imm_size,
    input from_de_imm_type,
    input [1:0] from_de_addr_mode,
    input [31:0] from_de_oeip,
    input [31:0] from_de_ieip,
    input from_de_valid,

    output [50:0] to_ag_cs,
    output [2:0] to_ag_dstidA,
    output [2:0] to_ag_dstidB,
    output [31:0] to_ag_srcregA,
    output [31:0] to_ag_srcregB,
    output [31:0] to_ag_srcregC,
    output [15:0] to_ag_srcSREG,
    output [63:0] to_ag_MMA,
    output [63:0] to_ag_MMB,
    output [31:0] to_ag_imm,
    output [15:0] to_ag_sreg1,
    output [31:0] to_ag_slim1,
    output [31:0] to_ag_base1,
    output [31:0] to_ag_index1,
    output [31:0] to_ag_disp,
    output [15:0] to_ag_sreg2,
    output [31:0] to_ag_slim2,
    output [31:0] base2,
    output to_ag_intex_vec,
    output [31:0] to_ag_oeip,
    output [31:0] to_ag_ieip,
    output to_ag_valid
); 
    wire [63:0] ucode_sig;
    ucode_controller uctlr (.ucode_sig(ucode_sig), 
                            .opcode(from_de_opcode), 
                            .ext_opcode(from_de_ext_opcode),
                            .modrm(from_de_modrm[7:6]),
                            .has_modrm(from_de_has_modrm)
                           );

    wire [1:0] ldAB;
    wire [2:0] dstidA_mux;
    wire [1:0] dstidB_mux;
    wire srcregA_mux;
    wire srcregB_mux;
    wire [2:0] gprd0_mux;
    wire [1:0] gprd2_mux;
    wire [2:0] ldREGS;
    wire [10:0] needREGS;
    wire ldEFLAGS;
    wire ldEIP;
    wire ldCS;
    wire alu_srcb_mux;
    wire [1:0] shf_srcb_mux;
    wire [2:0] eflags_mux;
    wire [2:0] eip_mux;
    wire [1:0] cs_mux;
    wire [3:0] gp_dsta_mux;
    wire [2:0] gp_dstb_mux;
    wire seg_dst_mux;
    wire [1:0] mm_dst_mux;
    wire [3:0] store_data_mux;
    wire [1:0] rw;
    
endmodule