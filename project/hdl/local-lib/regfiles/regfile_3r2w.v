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

module regfile_3r2w (
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
    input wr1_en
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
    
    genvar i;
    generate
        for (i = 0; i < 8; i=i+1) begin 
            big_eq #(.WIDTH(3)) wr0_eq_i(.in0(wr_reg0_idx), .in1(i[2:0]), .eq(we0[i]));
            big_eq #(.WIDTH(3)) wr1_eq_i(.in0(wr_reg1_idx), .in1(i[2:0]), .eq(we1[i]));
            check_en check_en_i(.we0_i(we0[i]), .wr0_en(wr0_en), .wr_reg0_data(wr_reg0_data), .we1_i(we1[i]), .wr1_en(wr1_en), .wr_reg1_data(wr_reg1_data), .en_i(en[i]), .din_i(din[i]));
            reg32e$ reg32e$_inst(clk, din[i], q[i], qb[i], rst_n, 1'b1, en[i]);
        end
    endgenerate

    // hitij means the i-th rd_idx matches the j-th wr_idx
    wire hit00, hit10, hit20, hit01, hit11, hit21;
    wire match00, match10, match20, match01, match11, match21;

    big_eq #(.WIDTH(3)) rd0_wr0_eq(.in0(rd_reg0_idx), .in1(wr_reg0_idx), .eq(match00));
    big_eq #(.WIDTH(3)) rd1_wr0_eq(.in0(rd_reg1_idx), .in1(wr_reg0_idx), .eq(match10));
    big_eq #(.WIDTH(3)) rd2_wr0_eq(.in0(rd_reg2_idx), .in1(wr_reg0_idx), .eq(match20));
    big_eq #(.WIDTH(3)) rd0_wr1_eq(.in0(rd_reg0_idx), .in1(wr_reg1_idx), .eq(match01));
    big_eq #(.WIDTH(3)) rd1_wr1_eq(.in0(rd_reg1_idx), .in1(wr_reg1_idx), .eq(match11));
    big_eq #(.WIDTH(3)) rd2_wr1_eq(.in0(rd_reg2_idx), .in1(wr_reg1_idx), .eq(match21));

    and2$ and_hit00(hit00, wr0_en, match00);
    and2$ and_hit10(hit10, wr0_en, match10);
    and2$ and_hit20(hit20, wr0_en, match20);
    and2$ and_hit01(hit01, wr1_en, match01);
    and2$ and_hit11(hit11, wr1_en, match11);
    and2$ and_hit21(hit21, wr1_en, match21);

    wire [31:0] rd_reg0_raw, rd_reg1_raw, rd_reg2_raw;
    mux8 mux_reg0_raw[31:0](rd_reg0_raw, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], rd_reg0_idx[0], rd_reg0_idx[1], rd_reg0_idx[2]);
    mux8 mux_reg1_raw[31:0](rd_reg1_raw, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], rd_reg1_idx[0], rd_reg1_idx[1], rd_reg1_idx[2]);
    mux8 mux_reg2_raw[31:0](rd_reg2_raw, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], rd_reg2_idx[0], rd_reg2_idx[1], rd_reg2_idx[2]);

    mux4$ mux_reg0[31:0](rd_reg0_data, rd_reg0_raw, wr_reg1_data, wr_reg0_data, wr_reg0_data, hit01, hit00);
    mux4$ mux_reg1[31:0](rd_reg1_data, rd_reg1_raw, wr_reg1_data, wr_reg0_data, wr_reg0_data, hit11, hit10);
    mux4$ mux_reg2[31:0](rd_reg2_data, rd_reg2_raw, wr_reg1_data, wr_reg0_data, wr_reg0_data, hit21, hit20);

endmodule