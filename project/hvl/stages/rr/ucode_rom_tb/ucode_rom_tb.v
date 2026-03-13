module  ucode_rom_tb;

initial begin
  $vcdplusfile("ucode_rom_tb.dump.vpd");
  $vcdpluson(0, ucode_rom_tb); 
end
integer FAILURES  = 0;
integer SUCCESSES = 0;
reg [7:0] opcode;
reg ext_opcode;
reg [1:0] modrm;
reg has_modrm;

wire [63:0] ucode_sig;
ucode_controller dut(
    .ucode_sig(ucode_sig),
    .opcode(opcode),
    .ext_opcode(ext_opcode),
    .modrm(modrm),
    .has_modrm(has_modrm)
);

wire [1:0] ldAB, dstidB_mux, gprd2_mux, shf_srcb_mux, cs_mux, mm_dst_mux, rw, ds;
wire [2:0] dstidA_mux, gprd0_mux, ldREGS, eflags_mux, eip_mux, gp_dstb_mux;
wire srcregA_mux, srcregB_mux, ldEFLAGS, alu_srcb_mux, ldEIP, ldCS, seg_dst_mux, srcsreg_mux, segrd0_mux, segrd1_mux;
wire [10:0] needREGS;
wire [3:0] gp_dsta_mux, store_data_mux;

rr_sig rr_sig_dut(
.ucode_sig(ucode_sig), .ldAB(ldAB), .dstidA_mux(dstidA_mux), .dstidB_mux(dstidB_mux),
.srcregA_mux(srcregA_mux), .srcregB_mux(srcregB_mux), .gprd0_mux(gprd0_mux), .gprd2_mux(gprd2_mux), .srcsreg_mux(srcsreg_mux), .segrd0_mux(segrd0_mux), .segrd1_mux(segrd1_mux),
.ldREGS(ldREGS), .needREGS(needREGS), .ldEFLAGS(ldEFLAGS),
.alu_srcb_mux(alu_srcb_mux), .shf_srcb_mux(shf_srcb_mux),
.ldEIP(ldEIP), .ldCS(ldCS), .eflags_mux(eflags_mux), .eip_mux(eip_mux), .cs_mux(cs_mux),
.gp_dsta_mux(gp_dsta_mux), .gp_dstb_mux(gp_dstb_mux), .seg_dst_mux(seg_dst_mux), .mm_dst_mux(mm_dst_mux),
.store_data_mux(store_data_mux), .rw(rw), .ds(ds)
);

task apply_test; 
input [7:0] test_opcode;
input test_ext_opcode;
input [1:0] test_modrm;
input test_has_modrm;
begin 
    opcode = test_opcode;
    ext_opcode = test_ext_opcode;
    modrm = test_modrm;
    has_modrm = test_has_modrm;
    $display("opcode=%02h, ext_opcode=%d, modrm=%d, has_modrm=%d", test_opcode, test_ext_opcode, test_modrm, test_has_modrm);
    #2
    $display("ucode=%64b", ucode_sig);
    $display("ldAB=%02b, gprd0_mux=%03b, gprd2_mux=%02b, eflags_mux=%03b, gp_dsta_mux=%04b, store_data_mux=%04b, rw=%02b, ds=%02b\n", ldAB, gprd0_mux, gprd2_mux, eflags_mux, gp_dsta_mux, store_data_mux, rw, ds);
end
endtask

initial begin 
    apply_test(8'h0, 1'b0, 2'b11, 1'b1);
    apply_test(8'h0, 1'b0, 2'b00, 1'b1);
    apply_test(8'h7F, 1'b1, 2'b11, 1'b1);
    apply_test(8'h7F, 1'b1, 2'b00, 1'b1);
    apply_test(8'h85, 1'b1, 2'b00, 1'b0);

    $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
    $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

    $finish;
end
endmodule