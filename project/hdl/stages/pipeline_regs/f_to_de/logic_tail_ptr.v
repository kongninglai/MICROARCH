module logic_tail_ptr(
    input wire clk,
    input wire rst_bar,
    input wire [3:0] incr_amt,
    input wire de_valid,
    input wire flush,
    input wire stall,
    input wire fb_req_cl, //fetch buffer request cache line signal (if there is space in the fetch buffer)
    output wire [4:0] tail_ptr
);

    //Tail Pointer
    wire tail_ptr_en;
    wire [7:0] tail_ptr_in_w, tail_ptr_decr_w, tail_ptr_cl_incr_w, tail_ptr_cl_incr_only_w;
    wire [1:0] tail_ptr_cl_incr_2bit, tail_ptr_cl_incr_only_2bit;
    wire [4:0] tail_ptr_in, tail_ptr_out, tail_ptr_decr;

    
    //00 decr, 01 cl_incr, 10 same, 11 cl_incr_only 
    wire [7:0] in00, in01, in10, in11;
    mux2_8$ mux_00(.Y(in00), .IN0(tail_ptr_decr_w), .IN1(8'd0), .S0(flush));
    mux2_8$ mux_01(.Y(in01), .IN0(tail_ptr_cl_incr_w), .IN1(8'd0), .S0(flush));
    mux2_8$ mux_10(.Y(in10), .IN0({3'd0, tail_ptr_out}), .IN1(8'd0), .S0(flush));
    mux2_8$ mux_11(.Y(in11), .IN0(tail_ptr_cl_incr_only_w), .IN1(8'd0), .S0(flush));

    mux4_8$ mux_tail_ptr_in(
        .Y(tail_ptr_in_w), 
        .IN0(in00), .IN1(in01), .IN2(in10), .IN3(in11),
        .S0(fb_req_cl), .S1(stall)
    );
    assign tail_ptr_in = tail_ptr_in_w[4:0];

    or4$ or_tail_ptr_en(tail_ptr_en, de_valid, flush, stall, fb_req_cl);
    reg_n #(.WIDTH(5)) tail_ptr_reg (
        .clk(clk),
        .rst(rst_bar),
        .en({5{tail_ptr_en}}),
        .d(tail_ptr_in),
        .q(tail_ptr_out)
    );
    assign tail_ptr = tail_ptr_out;

    wire [3:0] tail_ptr_incr_amt_bar;
    inv1$ inv_tail_ptr_incr_amt[3:0](tail_ptr_incr_amt_bar, incr_amt);
    FA_8b subtractor(
        .in0({3'd0, tail_ptr_out}), .in1({4'b1111,tail_ptr_incr_amt_bar}), .cin(1'd1),
        .s(tail_ptr_decr_w), .cout()
    );

    //Increment decremented tail pointer
    wire tail_ptr_out_decr_inv;
    inv1$ inv_tail_ptr_out_decr(tail_ptr_out_decr_inv, tail_ptr_decr_w[4]);
    assign tail_ptr_cl_incr_w = {3'd0, tail_ptr_out_decr_inv, tail_ptr_decr_w[3:0]};

    //Increment regular tail pointer 
    wire tail_ptr_out_inv;
    inv1$ inv_tail_ptr_out(tail_ptr_out_inv, tail_ptr_out[4]);
    assign tail_ptr_cl_incr_only_w = {3'd0, tail_ptr_out_inv, tail_ptr_out[3:0]};


endmodule