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

    mux2$ mux2$_32[31:0] (din_i, wr_reg1_data, wr_reg0_data, andout_0);
endmodule

module extract_read_data (
    output [31:0] read_out,
    input [1:0] datasize,
    input [2:0] read_idx,
    input [31:0] read_data
); 
    wire [31:0] read_low8, read_high8, read8, read16;
    assign read_low8 = {24'b0, read_data[7:0]};
    assign read_high8 = {24'b0, read_data[15:8]};
    mux2$ mux2_read8[31:0](read8, read_low8, read_high8, read_idx[2]);
    assign read16 = {16'b0, read_data[15:0]};
    mux4$ mux4_readdata[31:0](read_out, read8, read_data, read16, read_data, datasize[0], datasize[1]);
endmodule

module regfile_gp (
    input clk,
    input rst_n,

    input [2:0] rd_reg0_idx,
    input [2:0] rd_reg1_idx,
    input [2:0] rd_reg2_idx,
    output [31:0] rd_reg0_data,
    output [31:0] rd_reg1_data,
    output [31:0] rd_reg2_data,

    input [2:0] wr_reg0_idx,
    input [31:0] wr_reg0_data,
    input wr0_en,

    input [2:0] wr_reg1_idx,
    input [31:0] wr_reg1_data,
    input wr1_en,
    
    input [1:0] datasize
); 
    
    // q0 to q7 hold the register values
    wire [31:0] q[7:0];
    wire [31:0] qb[7:0];

    // we0_i, and we1_i are the potential we signals for the i-th register corresponding to we0_en and we1_en
    wire we0[7:0];
    wire we1[7:0];

    // eni are the actual we signal used for the i-th register
    wire en[7:0];

    // dini are the input for the i-th register
    wire [31:0] din[7:0];

    wire we0_0, en_0;
    wire [31:0] din_0;
    assign we0_0 = we0[0];
    assign en_0 = en[0];
    assign din_0 = din[0];

    wire not_datasize1, not_datasize0, datasize_is_8;

    inv1$ inv1_datasize1(not_datasize1, datasize[1]);
    inv1$ inv1_datasize0(not_datasize0, datasize[0]);
    and2$ and2_datasize8(datasize_is_8, not_datasize1, not_datasize0);
    
    wire [2:0] wr_reg0_idx_shifted, wr_reg1_idx_shifted;
    wire [2:0] wr0_pidx, wr1_pidx;

    assign wr_reg0_idx_shifted = {1'b0, wr_reg0_idx[1:0]};
    assign wr_reg1_idx_shifted = {1'b0, wr_reg1_idx[1:0]};

    mux2$ mux2_wr0_pidx[2:0](wr0_pidx, wr_reg0_idx, wr_reg0_idx_shifted, datasize_is_8);
    mux2$ mux2_wr1_pidx[2:0](wr1_pidx, wr_reg1_idx, wr_reg1_idx_shifted, datasize_is_8);

    wire [2:0] rd_reg0_idx_shifted, rd_reg1_idx_shifted, rd_reg2_idx_shifted;
    wire [2:0] rd0_pidx, rd1_pidx, rd2_pidx;
    
    assign rd_reg0_idx_shifted = {1'b0, rd_reg0_idx[1:0]};
    assign rd_reg1_idx_shifted = {1'b0, rd_reg1_idx[1:0]};
    assign rd_reg2_idx_shifted = {1'b0, rd_reg2_idx[1:0]};

    mux2$ mux2_rd0_pidx[2:0](rd0_pidx, rd_reg0_idx, rd_reg0_idx_shifted, datasize_is_8);
    mux2$ mux2_rd1_pidx[2:0](rd1_pidx, rd_reg1_idx, rd_reg1_idx_shifted, datasize_is_8);
    mux2$ mux2_rd2_pidx[2:0](rd2_pidx, rd_reg2_idx, rd_reg2_idx_shifted, datasize_is_8);

    wire [31:0] wr0_orig_full, wr1_orig_full;
    mux8 mux_wr0_orig[31:0](wr0_orig_full, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], wr0_pidx[0], wr0_pidx[1], wr0_pidx[2]);
    mux8 mux_wr1_orig[31:0](wr1_orig_full, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], wr1_pidx[0], wr1_pidx[1], wr1_pidx[2]);

    wire [31:0] wr0_wrdata_low8, wr0_wrdata_high8, wr0_wrdata_16;
    wire [31:0] wr1_wrdata_low8, wr1_wrdata_high8, wr1_wrdata_16;
    assign wr0_wrdata_low8  = {wr0_orig_full[31:8], wr_reg0_data[7:0]};
    assign wr0_wrdata_high8 = {wr0_orig_full[31:16], wr_reg0_data[7:0], wr0_orig_full[7:0]};
    assign wr0_wrdata_16 = {wr0_orig_full[31:16], wr_reg0_data[15:0]};

    assign wr1_wrdata_low8  = {wr1_orig_full[31:8], wr_reg1_data[7:0]};
    assign wr1_wrdata_high8 = {wr1_orig_full[31:16], wr_reg1_data[7:0], wr1_orig_full[7:0]};
    assign wr1_wrdata_16 = {wr1_orig_full[31:16], wr_reg1_data[15:0]};

    wire [31:0] wr0_wrdata_8, wr1_wrdata_8;
    mux2$ mux2_wr0_in_8[31:0](wr0_wrdata_8, wr0_wrdata_low8, wr0_wrdata_high8, wr_reg0_idx[2]);
    mux2$ mux2_wr1_in_8[31:0](wr1_wrdata_8, wr1_wrdata_low8, wr1_wrdata_high8, wr_reg1_idx[2]);

    wire [31:0] wr0_wrdata, wr1_wrdata;
    mux4$ mux4_wr0_in[31:0](wr0_wrdata, wr0_wrdata_8, wr0_orig_full, wr0_wrdata_16, wr_reg0_data, datasize[0], datasize[1]);
    mux4$ mux4_wr1_in[31:0](wr1_wrdata, wr1_wrdata_8, wr1_orig_full, wr1_wrdata_16, wr_reg1_data, datasize[0], datasize[1]);

    wire write_both_en, write_same_idx, write_low_high, write_same_low_high;
    and2$ and2_wr_both(write_both_en, wr0_en, wr1_en);
    xor2$ xor2_wr_idx(write_low_high, wr_reg0_idx[2], wr_reg1_idx[2]);
    eq_2b eq2_wr_idx(.in0(wr_reg0_idx[1:0]), .in1(wr_reg1_idx[1:0]), .eq(write_same_idx));
    and4$ and4_wr_idx(write_same_low_high, datasize_is_8, write_both_en, write_same_idx, write_low_high);

    wire [31:0] wr01_merged, wr0_wrdata_final;
    assign wr01_merged = {wr0_orig_full[31:16], wr_reg1_data[7:0], wr_reg0_data[7:0]};
    mux2$ mux2_wr0_wrdata_final[31:0](wr0_wrdata_final, wr0_wrdata, wr01_merged, write_same_low_high);

    genvar i;
    generate
        for (i = 0; i < 8; i=i+1) begin 
            eq_3b wr0_eq_i(.in0(wr0_pidx), .in1(i[2:0]), .eq(we0[i]));
            eq_3b wr1_eq_i(.in0(wr1_pidx), .in1(i[2:0]), .eq(we1[i]));
            check_en check_en_i(.we0_i(we0[i]), .wr0_en(wr0_en), .wr_reg0_data(wr0_wrdata_final), .we1_i(we1[i]), .wr1_en(wr1_en), .wr_reg1_data(wr1_wrdata), .en_i(en[i]), .din_i(din[i]));
            reg32e$ reg32e$_inst(clk, din[i], q[i], qb[i], rst_n, 1'b1, en[i]);
        end
    endgenerate

    // hitij means the i-th rd_idx matches the j-th wr_idx
    wire hit00, hit10, hit20, hit01, hit11, hit21;
    wire match00, match10, match20, match01, match11, match21;

    eq_3b rd0_wr0_eq(.in0(rd_reg0_idx), .in1(wr_reg0_idx), .eq(match00));
    eq_3b rd1_wr0_eq(.in0(rd_reg1_idx), .in1(wr_reg0_idx), .eq(match10));
    eq_3b rd2_wr0_eq(.in0(rd_reg2_idx), .in1(wr_reg0_idx), .eq(match20));
    eq_3b rd0_wr1_eq(.in0(rd_reg0_idx), .in1(wr_reg1_idx), .eq(match01));
    eq_3b rd1_wr1_eq(.in0(rd_reg1_idx), .in1(wr_reg1_idx), .eq(match11));
    eq_3b rd2_wr1_eq(.in0(rd_reg2_idx), .in1(wr_reg1_idx), .eq(match21));

    and2$ and_hit00(hit00, wr0_en, match00);
    and2$ and_hit10(hit10, wr0_en, match10);
    and2$ and_hit20(hit20, wr0_en, match20);
    and2$ and_hit01(hit01, wr1_en, match01);
    and2$ and_hit11(hit11, wr1_en, match11);
    and2$ and_hit21(hit21, wr1_en, match21);

    wire [31:0] rd_reg0_raw, rd_reg1_raw, rd_reg2_raw;
    mux8 mux_reg0_raw[31:0](rd_reg0_raw, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], rd_reg0_idx[0], rd_reg0_idx[1], rd0_pidx[2]);
    mux8 mux_reg1_raw[31:0](rd_reg1_raw, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], rd_reg1_idx[0], rd_reg1_idx[1], rd1_pidx[2]);
    mux8 mux_reg2_raw[31:0](rd_reg2_raw, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], rd_reg2_idx[0], rd_reg2_idx[1], rd2_pidx[2]);

    wire [31:0] rd0_data, rd1_data, rd2_data;
    mux4$ mux_reg0[31:0](rd0_data, rd_reg0_raw, wr1_wrdata, wr0_wrdata, wr0_wrdata, hit01, hit00);
    mux4$ mux_reg1[31:0](rd1_data, rd_reg1_raw, wr1_wrdata, wr0_wrdata, wr0_wrdata, hit11, hit10);
    mux4$ mux_reg2[31:0](rd2_data, rd_reg2_raw, wr1_wrdata, wr0_wrdata, wr0_wrdata, hit21, hit20);

    extract_read_data extract_r0(rd_reg0_data, datasize, rd_reg0_idx, rd0_data);
    extract_read_data extract_r1(rd_reg1_data, datasize, rd_reg1_idx, rd1_data);
    extract_read_data extract_r2(rd_reg2_data, datasize, rd_reg2_idx, rd2_data);

endmodule