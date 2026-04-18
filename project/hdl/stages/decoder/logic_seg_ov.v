/*
This module computes the segment register id based on the segment prefixes that are present.

Critical Path of Module: through segment_override_reg_id signal
Delay: 2.04ns
Add all stages together
*/
module logic_seg_ov(
    input wire is_es0, is_es1, is_es2,
    input wire is_cs0, is_cs1, is_cs2,
    input wire is_ss0, is_ss1, is_ss2,
    input wire is_ds0, is_ds1, is_ds2,
    input wire is_fs0, is_fs1, is_fs2,
    input wire is_gs0, is_gs1, is_gs2,
    input wire is_any_prefix0, is_any_prefix1,
    output wire is_seg_ov,
    output wire [2:0] segment_override_reg_id
);  
    //Stage 1 - 0.24ns
    wire is_any_prefix0_buf16, is_any_prefix1_buf16;
    bufferH16$ any_prefix0_wire_buf16(is_any_prefix0_buf16, is_any_prefix0);
    bufferH16$ any_prefix1_wire_buf16(is_any_prefix1_buf16, is_any_prefix1);

    //Stage 2 - 0.2ns
    wire grp0_0, grp0_1, grp0_2;
    wire grp1_0, grp1_1, grp1_2;
    wire grp2_0, grp2_1, grp2_2;
    wire grp3_0, grp3_1, grp3_2;
    wire grp4_0, grp4_1, grp4_2;
    wire grp5_0, grp5_1, grp5_2;

    nand2$ es0_nand(grp0_0, is_es0, is_es0);
    nand2$ p0_es1_nand(grp0_1, is_any_prefix0_buf16, is_es1);
    nand2$ p1_es2_nand(grp0_2, is_any_prefix1_buf16, is_es2);

    nand2$ cs0_nand(grp1_0, is_cs0, is_cs0);
    nand2$ p0_cs1_nand(grp1_1, is_any_prefix0_buf16, is_cs1);
    nand2$ p1_cs2_nand(grp1_2, is_any_prefix1_buf16, is_cs2);

    nand2$ ss0_nand(grp2_0, is_ss0, is_ss0);
    nand2$ p0_ss1_nand(grp2_1, is_any_prefix0_buf16, is_ss1);
    nand2$ p1_ss2_nand(grp2_2, is_any_prefix1_buf16, is_ss2);

    nand2$ ds0_nand(grp3_0, is_ds0, is_ds0);
    nand2$ p0_ds1_nand(grp3_1, is_any_prefix0_buf16, is_ds1);
    nand2$ p1_ds2_nand(grp3_2, is_any_prefix1_buf16, is_ds2);

    nand2$ fs0_nand(grp4_0, is_fs0, is_fs0);
    nand2$ p0_fs1_nand(grp4_1, is_any_prefix0_buf16, is_fs1);
    nand2$ p1_fs2_nand(grp4_2, is_any_prefix1_buf16, is_fs2);

    nand2$ gs0_nand(grp5_0, is_gs0, is_gs0);
    nand2$ p0_gs1_nand(grp5_1, is_any_prefix0_buf16, is_gs1);
    nand2$ p1_gs2_nand(grp5_2, is_any_prefix1_buf16, is_gs2);

    //Stage 3 - 0.25ns
    wire is_es, is_cs, is_ss, is_ds, is_fs, is_gs;

    nand3$ es_nand(is_es, grp0_0, grp0_1, grp0_2);
    nand3$ cs_nand(is_cs, grp1_0, grp1_1, grp1_2);
    nand3$ ss_nand(is_ss, grp2_0, grp2_1, grp2_2);
    nand3$ ds_nand(is_ds, grp3_0, grp3_1, grp3_2);
    nand3$ fs_nand(is_fs, grp4_0, grp4_1, grp4_2);
    nand3$ gs_nand(is_gs, grp5_0, grp5_1, grp5_2);

    //Stage 4 - 0.35ns
    wire or_nand_0_1_w, or_nand_2_3_w, or_nand_4_5_w;
    or2$ or_nand_0_1(or_nand_0_1_w, is_es, is_cs);
    or2$ or_nand_2_3(or_nand_2_3_w, is_ss, is_ds);
    or2$ or_nand_4_5(or_nand_4_5_w, is_fs, is_gs);

    //Stage 5 - 0.24ns
    or3$ or_all(is_seg_ov, or_nand_0_1_w, or_nand_2_3_w, or_nand_4_5_w);

    //Stage 6 - 0.76ns
    wire [2:0] segment_override_reg_id_w;
    pencoder8_3v$ seg_reg_id_encoder(
        .enbar(1'b0),               // Always enable  encoder
        .X({
            2'b00,                  // Bits 7 and 6 unused 
            is_gs,                  // GS = index 5 -> output 101
            is_fs,                  // FS = index 4 -> output 100
            is_ds,                  // DS = index 3 -> output 011
            is_ss,                  // SS = index 2 -> output 010
            is_cs,                  // CS = index 1 -> output 001
            is_es                   // ES = index 0 -> output 000
        }),
        .Y(segment_override_reg_id_w),     //out[2:0]
        .valid()                    //TODO         
    );

    wire [7:0] segment_override_reg_id_w_temp;
    mux2_8$ mux_default (.Y(segment_override_reg_id_w_temp), .IN0({5'd0, 3'd3}), .IN1({5'd0, segment_override_reg_id_w}), .S0(is_seg_ov));
    assign segment_override_reg_id = segment_override_reg_id_w_temp[2:0];
endmodule