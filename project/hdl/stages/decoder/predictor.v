module predictor(
    input wire clk, 
    input wire rst_bar,
    input wire br_t_nt_in, //from execute
    input wire ext_pht_idx, //from execute: branch counter TO UPDATE

    input wire b_pht_idx, //from decode: branch counter TO READ
    input wire b_valid, //from decode: is current instruction a branch?

    output wire br_t_nt_out //to decode: predicted taken not taken signal
);      

    //Not Taken Predictor Placeholder
    mux2$ MUX_PRED(
        .outb(br_t_nt_out),
        .in0(1'bX), //can be X since we won't use this value when b_valid is 0
        .in1(1'b0), //predict not taken
        .s0(b_valid) //only predict if it's a branch, otherwise default to not taken
    );
endmodule