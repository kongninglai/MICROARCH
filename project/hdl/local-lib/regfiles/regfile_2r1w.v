module regfile_2r1w #(
    parameter WIDTH=32
)(  
    input clk,
    input rst_n,

    input [2:0] rd_reg0_idx,
    input [2:0] rd_reg1_idx,
    output [WIDTH-1:0] rd_reg0_data,
    output [WIDTH-1:0] rd_reg1_data,

    input [2:0] wr_reg0_idx,
    input [WIDTH-1:0] wr_reg0_data,
    input wr0_en
); 

    // q0 to q7 hold the register values
    wire [WIDTH-1:0] q[7:0];
    wire [WIDTH-1:0] qb[7:0];

    // we0_i, and we1_i are the potential we signals for the i-th register corresponding to we0_en and we1_en
    wire we0[7:0];
    wire we1[7:0];

    // eni are the actual we signal used for the i-th register
    wire en[7:0];
    
    genvar i;
    generate
        for (i = 0; i < 8; i=i+1) begin 
            big_eq #(.WIDTH(3)) wr0_eq_i(.in0(wr_reg0_idx), .in1(i[2:0]), .eq(we0[i]));
            and2$ and_en_i(en[i], we0[i], wr0_en);
            if (WIDTH==16)
                reg16e reg16e_inst(clk, wr_reg0_data, q[i], qb[i], rst_n, 1'b1, en[i]);
            else if (WIDTH==32)
                reg32e$ reg32e$_inst(clk, wr_reg0_data, q[i], qb[i], rst_n, 1'b1, en[i]);
            else if (WIDTH==64)
                reg64e$ reg64e$_inst(clk, wr_reg0_data, q[i], qb[i], rst_n, 1'b1, en[i]);
        end
    endgenerate

    // hitij means the i-th rd_idx matches the j-th wr_idx
    wire hit00, hit10;
    wire match00, match10;

    big_eq #(.WIDTH(3)) rd0_wr0_eq(.in0(rd_reg0_idx), .in1(wr_reg0_idx), .eq(match00));
    big_eq #(.WIDTH(3)) rd1_wr0_eq(.in0(rd_reg1_idx), .in1(wr_reg0_idx), .eq(match10));

    and2$ and_hit00(hit00, wr0_en, match00);
    and2$ and_hit10(hit10, wr0_en, match10);

    wire [WIDTH-1:0] rd_reg0_raw, rd_reg1_raw;
    mux8 mux_reg0_raw[WIDTH-1:0](rd_reg0_raw, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], rd_reg0_idx[0], rd_reg0_idx[1], rd_reg0_idx[2]);
    mux8 mux_reg1_raw[WIDTH-1:0](rd_reg1_raw, q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], rd_reg1_idx[0], rd_reg1_idx[1], rd_reg1_idx[2]);

    mux2$ mux_reg0[WIDTH-1:0](rd_reg0_data, rd_reg0_raw, wr_reg0_data, hit00);
    mux2$ mux_reg1[WIDTH-1:0](rd_reg1_data, rd_reg1_raw, wr_reg0_data, hit10);

endmodule