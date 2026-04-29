/*
 * regfile_gp: general purpose register file
 * input:   gprd0_idx, gprd1_idx, gprd2_idx, gprd3_idx,
 *          gpwr0_idx, gpwr0_data, gpwr0_size, gpwr0_en,
 *          gpwr1_idx, gpwr1_data, gpwr1_size, gpwr1_en
 * output:  gprd0_data, gprd1_data, gprd2_data, gprd3_data
 *
 * For read port, it always read out 32-bits.
 * For write port, it would only write {size}-bit to the register
 * The high/low eight bits logic for datasize=8 is handled in the regfile itself
 * The module would assume the write data is always at the low {size}-bit
 * and will write into the high eight bits if needed
*/
module check_en (
    input we0_i,
    input wr0_en,
    input [31:0] wr_reg0_data,
    input we1_i,
    input wr1_en,
    input [31:0] wr_reg1_data,
    output en_i,
    output [31:0] din_i
); 
    wire andout_0, andout_1;
    and2$ and2$_0(andout_0, we0_i, wr0_en);
    and2$ and2$_1(andout_1, we1_i, wr1_en);
    or2$  or2$_0(en_i, andout_0, andout_1);

    mux2_32 mux2_32_din(din_i, wr_reg1_data, wr_reg0_data, andout_0);
endmodule

module regfile_gp (
    input clk,
    input rst_n,

    input [2:0] rd_reg0_idx,
    input [2:0] rd_reg1_idx,
    input [2:0] rd_reg2_idx,
    input [2:0] rd_reg3_idx,

    input [1:0] rd_reg0_ds,
    input [1:0] rd_reg1_ds,
    input [1:0] rd_reg2_ds,
    input [1:0] rd_reg3_ds,

    output [31:0] rd_reg0_data,
    output [31:0] rd_reg1_data,
    output [31:0] rd_reg2_data,
    output [31:0] rd_reg3_data,

    input [2:0] wr_reg0_idx,
    input [31:0] wr_reg0_data,
    input [1:0] wr_reg0_ds, // 00(8-bit), 01(16-bit), 10(32-bit), 11(64-bit/UNUSED)
    input wr0_en,

    input [2:0] wr_reg1_idx,
    input [31:0] wr_reg1_data,
    input [1:0] wr_reg1_ds,
    input wr1_en
); 
    
    // q0 to q7 hold the register values
    wire [31:0] q[7:0];
    wire [31:0] q_prebuf[7:0];
    wire [31:0] qb[7:0];

    // we0_i, and we1_i are the potential we signals for the i-th register corresponding to we0_en and we1_en
    wire we0[7:0];
    wire we1[7:0];

    // eni are the actual we signal used for the i-th register
    wire en[7:0];

    // dini are the input for the i-th register
    wire [31:0] din[7:0];


    wire wr_reg0_ds_is_8, wr_reg1_ds_is_8;

    nor2$ nor2_wr0_size8(wr_reg0_ds_is_8, wr_reg0_ds[1], wr_reg0_ds[0]);
    nor2$ nor2_wr1_size8(wr_reg1_ds_is_8, wr_reg1_ds[1], wr_reg1_ds[0]);
    
    wire [2:0] wr_reg0_idx_shifted, wr_reg1_idx_shifted;
    wire [2:0] wr0_pidx, wr0_pidx_prebuf, wr1_pidx, wr1_pidx_prebuf;

    assign wr_reg0_idx_shifted = {1'b0, wr_reg0_idx[1:0]};
    assign wr_reg1_idx_shifted = {1'b0, wr_reg1_idx[1:0]};

    mux2$ mux2_wr0_pidx[2:0](wr0_pidx_prebuf, wr_reg0_idx, wr_reg0_idx_shifted, wr_reg0_ds_is_8);
    mux2$ mux2_wr1_pidx[2:0](wr1_pidx_prebuf, wr_reg1_idx, wr_reg1_idx_shifted, wr_reg1_ds_is_8);
    bufferH64$  bufferH64$_wr0_pidx[2:0](wr0_pidx, wr0_pidx_prebuf);
    bufferH64$  bufferH64$_wr1_pidx[2:0](wr1_pidx, wr1_pidx_prebuf);

    wire [31:0] wr0_orig_full, wr0_orig_full_prebuf, wr1_orig_full, wr1_orig_full_prebuf;
    mux8_32 mux32_wr0_orig(wr0_orig_full_prebuf, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], wr0_pidx[0], wr0_pidx[1], wr0_pidx[2]);
    mux8_32 mux32_wr1_orig(wr1_orig_full_prebuf, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], wr1_pidx[0], wr1_pidx[1], wr1_pidx[2]);
    bufferH16$  bufferH16$_wr0_orig_full[31:0](wr0_orig_full, wr0_orig_full_prebuf);
    bufferH16$  bufferH16$_wr1_orig_full[31:0](wr1_orig_full, wr1_orig_full_prebuf);

    wire [31:0] wr0_wrdata_low8, wr0_wrdata_high8, wr0_wrdata_16;
    wire [31:0] wr1_wrdata_low8, wr1_wrdata_high8, wr1_wrdata_16;
    assign wr0_wrdata_low8  = {wr0_orig_full[31:8], wr_reg0_data[7:0]};
    assign wr0_wrdata_high8 = {wr0_orig_full[31:16], wr_reg0_data[7:0], wr0_orig_full[7:0]};
    assign wr0_wrdata_16 = {wr0_orig_full[31:16], wr_reg0_data[15:0]};

    assign wr1_wrdata_low8  = {wr1_orig_full[31:8], wr_reg1_data[7:0]};
    assign wr1_wrdata_high8 = {wr1_orig_full[31:16], wr_reg1_data[7:0], wr1_orig_full[7:0]};
    assign wr1_wrdata_16 = {wr1_orig_full[31:16], wr_reg1_data[15:0]};

    wire [31:0] wr0_wrdata_8, wr1_wrdata_8;
    mux2_32 mux2_wr0_in_8(wr0_wrdata_8, wr0_wrdata_low8, wr0_wrdata_high8, wr_reg0_idx[2]);
    mux2_32 mux2_wr1_in_8(wr1_wrdata_8, wr1_wrdata_low8, wr1_wrdata_high8, wr_reg1_idx[2]);

    wire [31:0] wr0_wrdata_prebuf, wr0_wrdata, wr1_wrdata_prebuf, wr1_wrdata;
    mux4_32 mux4_wr0_in(wr0_wrdata_prebuf, wr0_wrdata_8, wr0_wrdata_16, wr_reg0_data, wr_reg0_data, wr_reg0_ds[0], wr_reg0_ds[1]);
    mux4_32 mux4_wr1_in(wr1_wrdata_prebuf, wr1_wrdata_8, wr1_wrdata_16, wr_reg1_data, wr_reg1_data, wr_reg1_ds[0], wr_reg1_ds[1]);
    bufferH16$  bufferH16$_wr0_wrdata[31:0](wr0_wrdata, wr0_wrdata_prebuf);
    bufferH16$  bufferH16$_wr1_wrdata[31:0](wr1_wrdata, wr1_wrdata_prebuf);

    wire write_both_en, write_same_idx, write_low_high, both_write_8, write_same_low_high;
    and2$ and2_wr_both(write_both_en, wr0_en, wr1_en);
    xor2$ xor2_wr_idx(write_low_high, wr_reg0_idx[2], wr_reg1_idx[2]);
    big_eq #(.WIDTH(2)) eq2_wr_idx(.in0(wr_reg0_idx[1:0]), .in1(wr_reg1_idx[1:0]), .eq(write_same_idx));
    and2$ and2_both_write_8(both_write_8, wr_reg0_ds_is_8, wr_reg1_ds_is_8);
    and4$ and4_wr_idx(write_same_low_high, both_write_8, write_both_en, write_same_idx, write_low_high);

    wire [31:0] wr01_merged, wr0_wrdata_final_prebuf, wr0_wrdata_final;
    wire [31:0] wr01, wr10;
    assign wr01 = {wr0_orig_full[31:16], wr_reg0_data[7:0], wr_reg1_data[7:0]};
    assign wr10 = {wr0_orig_full[31:16], wr_reg1_data[7:0], wr_reg0_data[7:0]};

    mux2_32 mux2_wr01_merged(.out(wr01_merged), .in0(wr10), .in1(wr01), .s0(wr_reg0_idx[2]));
    // assign wr01_merged = {wr0_orig_full[31:16], wr_reg1_data[7:0], wr_reg0_data[7:0]};
    mux2_32 mux2_wr0_wrdata_final(wr0_wrdata_final_prebuf, wr0_wrdata, wr01_merged, write_same_low_high);
    bufferH16$  bufferH16$_wr0_wrdata_final[31:0](wr0_wrdata_final, wr0_wrdata_final_prebuf);

    genvar i;
    generate
        for (i = 0; i < 8; i=i+1) begin 
            big_eq #(.WIDTH(3)) wr0_eq_i(.in0(wr0_pidx), .in1(i[2:0]), .eq(we0[i]));
            big_eq #(.WIDTH(3)) wr1_eq_i(.in0(wr1_pidx), .in1(i[2:0]), .eq(we1[i]));
            check_en check_en_i(.we0_i(we0[i]), .wr0_en(wr0_en), .wr_reg0_data(wr0_wrdata_final), .we1_i(we1[i]), .wr1_en(wr1_en), .wr_reg1_data(wr1_wrdata), .en_i(en[i]), .din_i(din[i]));
            reg32e$ reg32e$_inst(clk, din[i], q_prebuf[i], qb[i], rst_n, 1'b1, en[i]);
            bufferH16$  bufferH16$_q[31:0](q[i], q_prebuf[i]);
        end
    endgenerate

    // read logic
    wire rd0_size_is_8, rd1_size_is_8, rd2_size_is_8, rd3_size_is_8;
    nor2$ nor2_rd0_size8(rd0_size_is_8, rd_reg0_ds[1], rd_reg0_ds[0]);
    nor2$ nor2_rd1_size8(rd1_size_is_8, rd_reg1_ds[1], rd_reg1_ds[0]);
    nor2$ nor2_rd2_size8(rd2_size_is_8, rd_reg2_ds[1], rd_reg2_ds[0]);
    nor2$ nor2_rd3_size8(rd3_size_is_8, rd_reg3_ds[1], rd_reg3_ds[0]);

    wire [2:0] rd_reg0_idx_shifted, rd_reg1_idx_shifted, rd_reg2_idx_shifted, rd_reg3_idx_shifted;
    wire [2:0] rd0_pidx, rd0_pidx_prebuf, rd1_pidx, rd1_pidx_prebuf, rd2_pidx, rd2_pidx_prebuf, rd3_pidx, rd3_pidx_prebuf;
    
    assign rd_reg0_idx_shifted = {1'b0, rd_reg0_idx[1:0]};
    assign rd_reg1_idx_shifted = {1'b0, rd_reg1_idx[1:0]};
    assign rd_reg2_idx_shifted = {1'b0, rd_reg2_idx[1:0]};
    assign rd_reg3_idx_shifted = {1'b0, rd_reg3_idx[1:0]};

    mux2$ mux2_rd0_pidx[2:0](rd0_pidx_prebuf, rd_reg0_idx, rd_reg0_idx_shifted, rd0_size_is_8);
    mux2$ mux2_rd1_pidx[2:0](rd1_pidx_prebuf, rd_reg1_idx, rd_reg1_idx_shifted, rd1_size_is_8);
    mux2$ mux2_rd2_pidx[2:0](rd2_pidx_prebuf, rd_reg2_idx, rd_reg2_idx_shifted, rd2_size_is_8);
    mux2$ mux2_rd3_pidx[2:0](rd3_pidx_prebuf, rd_reg3_idx, rd_reg3_idx_shifted, rd3_size_is_8);

    bufferH16$  bufferH16$_rd0_pidx[2:0](rd0_pidx, rd0_pidx_prebuf);
    bufferH16$  bufferH16$_rd1_pidx[2:0](rd1_pidx, rd1_pidx_prebuf);
    bufferH16$  bufferH16$_rd2_pidx[2:0](rd2_pidx, rd2_pidx_prebuf);
    bufferH16$  bufferH16$_rd3_pidx[2:0](rd3_pidx, rd3_pidx_prebuf);

    // hitij means the i-th rd_idx matches the j-th wr_idx
    wire hit00, hit10, hit20, hit30, hit01, hit11, hit21, hit31;
    wire match00, match10, match20, match30, match01, match11, match21, match31;

    big_eq #(.WIDTH(3)) rd0_wr0_eq(.in0(rd0_pidx), .in1(wr0_pidx), .eq(match00));
    big_eq #(.WIDTH(3)) rd1_wr0_eq(.in0(rd1_pidx), .in1(wr0_pidx), .eq(match10));
    big_eq #(.WIDTH(3)) rd2_wr0_eq(.in0(rd2_pidx), .in1(wr0_pidx), .eq(match20));
    big_eq #(.WIDTH(3)) rd3_wr0_eq(.in0(rd3_pidx), .in1(wr0_pidx), .eq(match30));
    big_eq #(.WIDTH(3)) rd0_wr1_eq(.in0(rd0_pidx), .in1(wr1_pidx), .eq(match01));
    big_eq #(.WIDTH(3)) rd1_wr1_eq(.in0(rd1_pidx), .in1(wr1_pidx), .eq(match11));
    big_eq #(.WIDTH(3)) rd2_wr1_eq(.in0(rd2_pidx), .in1(wr1_pidx), .eq(match21));
    big_eq #(.WIDTH(3)) rd3_wr1_eq(.in0(rd3_pidx), .in1(wr1_pidx), .eq(match31));


    and2$ and_hit00(hit00, wr0_en, match00);
    and2$ and_hit10(hit10, wr0_en, match10);
    and2$ and_hit20(hit20, wr0_en, match20);
    and2$ and_hit30(hit30, wr0_en, match30);
    and2$ and_hit01(hit01, wr1_en, match01);
    and2$ and_hit11(hit11, wr1_en, match11);
    and2$ and_hit21(hit21, wr1_en, match21);
    and2$ and_hit31(hit31, wr1_en, match31);

    wire [31:0] rd_reg0_raw, rd_reg1_raw, rd_reg2_raw, rd_reg3_raw;
    mux8_32 mux_reg0_raw(rd_reg0_raw, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], rd0_pidx[0], rd0_pidx[1], rd0_pidx[2]);
    mux8_32 mux_reg1_raw(rd_reg1_raw, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], rd1_pidx[0], rd1_pidx[1], rd1_pidx[2]);
    mux8_32 mux_reg2_raw(rd_reg2_raw, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], rd2_pidx[0], rd2_pidx[1], rd2_pidx[2]);
    mux8_32 mux_reg3_raw(rd_reg3_raw, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], rd3_pidx[0], rd3_pidx[1], rd3_pidx[2]);

    wire [31:0] rd0_data, rd1_data, rd2_data, rd3_data;
    mux4_32 mux_reg0(rd0_data, rd_reg0_raw, wr1_wrdata, wr0_wrdata, wr0_wrdata_final, hit01, hit00);
    mux4_32 mux_reg1(rd1_data, rd_reg1_raw, wr1_wrdata, wr0_wrdata, wr0_wrdata_final, hit11, hit10);
    mux4_32 mux_reg2(rd2_data, rd_reg2_raw, wr1_wrdata, wr0_wrdata, wr0_wrdata_final, hit21, hit20);
    mux4_32 mux_reg3(rd3_data, rd_reg3_raw, wr1_wrdata, wr0_wrdata, wr0_wrdata_final, hit31, hit30);

    // gpr_shifter extract_r0(rd_reg0_data, rd_reg0_ds, rd_reg0_idx, rd0_data);
    // gpr_shifter extract_r1(rd_reg1_data, rd_reg1_ds, rd_reg1_idx, rd1_data);
    // gpr_shifter extract_r2(rd_reg2_data, rd_reg2_ds, rd_reg2_idx, rd2_data);
    // gpr_shifter extract_r3(rd_reg3_data, rd_reg3_ds, rd_reg3_idx, rd3_data);
    assign rd_reg0_data = rd0_data;
    assign rd_reg1_data = rd1_data;
    assign rd_reg2_data = rd2_data;
    assign rd_reg3_data = rd3_data;

endmodule