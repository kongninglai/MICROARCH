module predictor(
    input wire clk, 
    input wire rst_bar,
    input wire br_t_nt_in, //from execute
    input wire [3:0] ext_pht_idx, //from execute: branch counter TO UPDATE
    input wire from_ex_br_valid, //from execute: is the branch in execute valid (for updating predictor)
    input wire [3:0] b_pht_idx, //from decode: branch counter TO READ
    input wire from_de_br_valid, //from decode: is the instruction in decode a branch
    output wire br_t_nt_out //to decode: predicted taken not taken signal
);      

    //Logic to Update PRedictor
    wire [15:0] we;
    wire [15:0] decoder_out;
    decoder4_16 PHT_WE_SEL(
        .SEL(ext_pht_idx),
        .Y(decoder_out), .YBAR()
    );

    genvar j;
    generate 
        for (j = 0; j < 16; j = j + 1) begin : PHT_WRITE_LOGIC
            and2$ we_and(
                .out(we[j]),
                .in0(decoder_out[j]),
                .in1(from_ex_br_valid)
            );
        end
    endgenerate

    //Predictor Array
    wire [15:0] NextState1, NextState0;
    wire [15:0] CurState1, CurState0;
    genvar i;
    generate 
        for (i = 0; i < 16; i = i + 1) begin : PHT_ARRAY
            sat_cntr PHT(
                .CurState1(CurState1[i]), .CurState0(CurState0[i]), .Incr_or_Decr(br_t_nt_in), 
                .NextState1(NextState1[i]), .NextState0(NextState0[i])
            );

            //default reset the counter value to 01 -> weakly not taken
            reg_n #(.WIDTH(1), .USE_EN_BAR(0), .RESET_TO_ONES(0)) PHT_CNTR1(
                .clk(clk), .rst(rst_bar), .en(we[i]), .d(NextState1[i]), .q(CurState1[i])
            );

            reg_n #(.WIDTH(1), .USE_EN_BAR(0), .RESET_TO_ONES(1)) PHT_CNTR0(
                .clk(clk), .rst(rst_bar), .en(we[i]), .d(NextState0[i]), .q(CurState0[i])
            );
        end
    endgenerate

    //Logic to Read Predictor 
    wire t_nt1, t_nt0;
    mux16 mux_t_nt1(
        .outb(t_nt1), 
        .in0(CurState1[0]),   .in1(CurState1[1]),   .in2(CurState1[2]),   .in3(CurState1[3]), 
        .in4(CurState1[4]),   .in5(CurState1[5]),   .in6(CurState1[6]),   .in7(CurState1[7]),
        .in8(CurState1[8]),   .in9(CurState1[9]),   .in10(CurState1[10]), .in11(CurState1[11]), 
        .in12(CurState1[12]), .in13(CurState1[13]), .in14(CurState1[14]), .in15(CurState1[15]),
        .s0(b_pht_idx[0]),    .s1(b_pht_idx[1]),  .s2(b_pht_idx[2]),  .s3(b_pht_idx[3])
    );
    mux16 mux_t_nt0(
        .outb(t_nt0), 
        .in0(CurState0[0]),   .in1(CurState0[1]),   .in2(CurState0[2]),   .in3(CurState0[3]), 
        .in4(CurState0[4]),   .in5(CurState0[5]),   .in6(CurState0[6]),   .in7(CurState0[7]),
        .in8(CurState0[8]),   .in9(CurState0[9]),   .in10(CurState0[10]), .in11(CurState0[11]), 
        .in12(CurState0[12]), .in13(CurState0[13]), .in14(CurState0[14]), .in15(CurState0[15]),
        .s0(b_pht_idx[0]),    .s1(b_pht_idx[1]),  .s2(b_pht_idx[2]),  .s3(b_pht_idx[3])
    );

    //only predict taken if the instruction in decosde is actually a branch, otherwise not taken
    wire br_t_nt_out_bar;
    nand2$ FINAL_PREDICTION(
        .out(br_t_nt_out_bar),
        .in0(from_de_br_valid), .in1(t_nt1)
    );
    bufferHInv16$ bufferHInv16$_br_t_nt_out(br_t_nt_out, br_t_nt_out_bar);
endmodule