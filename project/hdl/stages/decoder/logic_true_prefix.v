/*
Determines the direct output to prefix registers with the correct signal 
that shows whether or not a certain prefix is present. 

Critical Path: Through the Prefix Adder module
Delay: 2.74
1.74 + 1
*/

module logic_true_prefix(
    input wire [7:0] candidate_prefix0,
    input wire [7:0] candidate_prefix1,
    input wire [7:0] candidate_prefix2,
    input wire [7:0] candidate_prefix3,
    output wire is_rep_true,
    output wire is_operand_size_override_true,
    output wire is_seg_ov,
    output wire [2:0] seg_id,
    output wire ext_op_true,
    output wire [2:0] prefix_num
);

    //Stage 1 - 1.74ns
    wire is_rep0, is_rep1, is_rep2, is_rep3;
    wire is_operand_size_override0, is_operand_size_override1, is_operand_size_override2, is_operand_size_override3;
    wire is_ext_opcode0, is_ext_opcode1, is_ext_opcode2, is_ext_opcode3;
    wire is_es0, is_es1, is_es2, is_es3;
    wire is_cs0, is_cs1, is_cs2, is_cs3;
    wire is_ss0, is_ss1, is_ss2, is_ss3;
    wire is_ds0, is_ds1, is_ds2, is_ds3;
    wire is_fs0, is_fs1, is_fs2, is_fs3;
    wire is_gs0, is_gs1, is_gs2, is_gs3;
    wire is_any0, is_any1, is_any2, is_any3;
    
    logic_is_prefix LOGIC_IS_PREFIX0(
        .candidate_prefix(candidate_prefix0),
        .is_rep(is_rep0),
        .is_operand_size_override(is_operand_size_override0),
        .is_ext_opcode(is_ext_opcode0),
        .is_es(is_es0),
        .is_cs(is_cs0),
        .is_ss(is_ss0),
        .is_ds(is_ds0),
        .is_fs(is_fs0),
        .is_gs(is_gs0),
        .is_any_prefix(is_any0)
    );

    logic_is_prefix LOGIC_IS_PREFIX1(
        .candidate_prefix(candidate_prefix1),
        .is_rep(is_rep1),
        .is_operand_size_override(is_operand_size_override1),
        .is_ext_opcode(is_ext_opcode1),
        .is_es(is_es1),
        .is_cs(is_cs1),
        .is_ss(is_ss1),
        .is_ds(is_ds1),
        .is_fs(is_fs1),
        .is_gs(is_gs1),
        .is_any_prefix(is_any1)
    );

    logic_is_prefix LOGIC_IS_PREFIX2(
        .candidate_prefix(candidate_prefix2),
        .is_rep(is_rep2),
        .is_operand_size_override(is_operand_size_override2),
        .is_ext_opcode(is_ext_opcode2),
        .is_es(is_es2),
        .is_cs(is_cs2),
        .is_ss(is_ss2),
        .is_ds(is_ds2),
        .is_fs(is_fs2),
        .is_gs(is_gs2),
        .is_any_prefix(is_any2)
    );

    logic_is_prefix LOGIC_IS_PREFIX3(
        .candidate_prefix(candidate_prefix3),
        .is_rep(is_rep3),
        .is_operand_size_override(is_operand_size_override3),
        .is_ext_opcode(is_ext_opcode3),
        .is_es(is_es3),
        .is_cs(is_cs3),
        .is_ss(is_ss3),
        .is_ds(is_ds3),
        .is_fs(is_fs3),
        .is_gs(is_gs3),
        .is_any_prefix(is_any3)
    );

    //Layer 2 - 2.04ns (longest through segment)
    wire is_any0_actual, is_any1_actual, is_any2_actual, is_any3_actual;
    assign is_any0_actual = is_any0;
    and2$ isany1actual(is_any1_actual, is_any0, is_any1);
    and2$ isany2actual(is_any2_actual, is_any1_actual, is_any2);
    and2$ isany3actual(is_any3_actual, is_any2_actual, is_any3);
    
    logic_prefix_combadder PREFIX_ADDER( //Critical Path 1ns
        .P0(is_any0_actual),
        .P1(is_any1_actual),
        .P2(is_any2_actual),
        .P3(is_any3_actual),
        .OUT2(prefix_num[2]),
        .OUT1(prefix_num[1]),
        .OUT0(prefix_num[0])
    );

    wire is_seg_ov;
    logic_seg_ov SEGMENT_OVERRIDE_REG_ID_LOGIC (
        .is_es0(is_es0), .is_es1(is_es1), .is_es2(is_es2), .is_es3(is_es3),
        .is_cs0(is_cs0), .is_cs1(is_cs1), .is_cs2(is_cs2), .is_cs3(is_cs3),
        .is_ss0(is_ss0), .is_ss1(is_ss1), .is_ss2(is_ss2), .is_ss3(is_ss3),
        .is_ds0(is_ds0), .is_ds1(is_ds1), .is_ds2(is_ds2), .is_ds3(is_ds3),
        .is_fs0(is_fs0), .is_fs1(is_fs1), .is_fs2(is_fs2), .is_fs3(is_fs3),
        .is_gs0(is_gs0), .is_gs1(is_gs1), .is_gs2(is_gs2), .is_gs3(is_gs3),
        .is_any_prefix0(is_any0_actual), .is_any_prefix1(is_any1_actual), 
        .is_any_prefix2(is_any2_actual), .is_any_prefix3(is_any3_actual),
        .is_seg_ov(is_seg_ov),           //out
        .segment_override_reg_id(seg_id) //out
    );

    wire rep_nand0_w, rep_nand1_w, rep_nand2_w, rep_nand3_w; //0.45ns total in parallel with segment ov logic
    nand2$ rep_nand0(rep_nand0_w, is_rep0, is_rep0);
    nand2$ rep_nand1(rep_nand1_w, is_rep1, is_any0);
    nand2$ rep_nand2(rep_nand2_w, is_rep2, is_any1);
    nand2$ rep_nand3(rep_nand3_w, is_rep3, is_any2);
    nand4$ rep_nand4(is_rep_true, rep_nand0_w, rep_nand1_w, rep_nand2_w, rep_nand3_w);

    wire opov_nand0_w, opov_nand1_w, opov_nand2_w, opov_nand3_w; //0.45ns total in parallel with segment ov logic
    nand2$ opov_nand0(opov_nand0_w, is_operand_size_override0, is_operand_size_override0);
    nand2$ opov_nand1(opov_nand1_w, is_operand_size_override1, is_any0);
    nand2$ opov_nand2(opov_nand2_w, is_operand_size_override2, is_any1);
    nand2$ opov_nand3(opov_nand3_w, is_operand_size_override3, is_any2);
    nand4$ opov_nand4(is_operand_size_override_true, opov_nand0_w, opov_nand1_w, opov_nand2_w, opov_nand3_w);

    wire ext_nand0_w, ext_nand1_w, ext_nand2_w, ext_nand3_w; //0.45ns total in parallel with segment ov logic
    nand2$ ext_nand0(ext_nand0_w, is_ext_opcode0, is_ext_opcode0);
    nand2$ ext_nand1(ext_nand1_w, is_ext_opcode1, is_any0);
    nand2$ ext_nand2(ext_nand2_w, is_ext_opcode2, is_any1);
    nand2$ ext_nand3(ext_nand3_w, is_ext_opcode3, is_any2);
    nand4$ ext_nand4(ext_op_true, ext_nand0_w, ext_nand1_w, ext_nand2_w, ext_nand3_w);


endmodule