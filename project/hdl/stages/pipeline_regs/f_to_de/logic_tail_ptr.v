module logic_tail_ptr(
    input wire clk,
    input wire rst_bar,
    input wire [3:0] incr_amt, //gated in fetch buffer
    input wire shft_reg_we,
    input wire flush,
    input wire stall,
    input wire fb_req_cl, //fetch buffer request cache line signal (if there is space in the fetch buffer)
    input wire eip_redirection, //br taken in decode, mispredict in execute, exception in wb
    output wire [4:0] tail_ptr
);

    wire tail_ptr_en;
    wire [7:0] tail_ptr_in_w, tail_ptr_decr_w, tail_ptr_cl_incr_w, tail_ptr_cl_incr_only_w, tail_ptr_out_w;
    wire [1:0] tail_ptr_cl_incr_2bit, tail_ptr_cl_incr_only_2bit;
    wire [4:0] tail_ptr_in, tail_ptr_out, tail_ptr_decr;

    //Choose Tail Pointer input (00 decr, 01 cl_incr, 10 same, 11 cl_incr_only)
    mux4_8$ mux_tail_ptr_in(
        .Y(tail_ptr_in_w), 
        .IN0(tail_ptr_decr_w), .IN1(tail_ptr_cl_incr_w), .IN2(tail_ptr_out_w), .IN3(tail_ptr_cl_incr_only_w),
        .S0(fb_req_cl), .S1(stall)
    );
    assign tail_ptr_out_w = {3'd0, tail_ptr_out};
    assign tail_ptr_in = tail_ptr_in_w[4:0];

    //Tail pointer
    wire CLR_BAR, flush_bar;
    or2$ or_tail_ptr_en(tail_ptr_en, shft_reg_we, flush);
    inv1$ inv_flush(flush_bar, flush);
    and2$ and_clear(CLR_BAR, rst_bar, flush_bar); //(if either rst of flush is a 0, we want to clear)
    reg_n #(.WIDTH(5)) tail_ptr_reg (
        .clk(clk),
        .rst(CLR_BAR),
        .en({5{tail_ptr_en}}),
        .d(tail_ptr_in),
        .q(tail_ptr_out)
    );
    assign tail_ptr = tail_ptr_out;

    wire [3:0] incr_amt_bar;
    inv1$ inv_eip_0 (incr_amt_bar[0], incr_amt[0]);
    inv1$ inv_eip_1 (incr_amt_bar[1], incr_amt[1]);
    inv1$ inv_eip_2 (incr_amt_bar[2], incr_amt[2]);
    inv1$ inv_eip_3 (incr_amt_bar[3], incr_amt[3]);
    FA_8b subtractor(
        .in0({3'd0, tail_ptr_out}), .in1({4'b1111,incr_amt_bar}), .cin(1'd1),
        .s(tail_ptr_decr_w), .cout()
    );

        
    //Number of Bytes to write from Cache Line Logic


    wire [4:0] we_cl_byte_cnt_w;
    big_increment_cout #(.WIDTH(4)) two_complement_incrementer(
        .a(incr_amt_bar),
        .s(we_cl_byte_cnt_w[3:0]), .cout(we_cl_byte_cnt_w[4]) 
    );

    wire [7:0] we_cl_byte_cnt_temp;
    wire [4:0] we_cl_byte_cnt;
    assign we_cl_byte_cnt = we_cl_byte_cnt_temp[4:0];
    mux2_8$ byte_cnt_mux(.Y(we_cl_byte_cnt_temp), .IN0({3'b0, 5'd16}), .IN1({3'b0, we_cl_byte_cnt_w}), .S0(eip_redirection));

    //Increment decremented tail pointer    
    PA_8b INCR_DECR_TAIL_PTR(
        .in0(tail_ptr_decr_w), .in1({3'd0, we_cl_byte_cnt}),
        .s(tail_ptr_cl_incr_w)
    );

    //Increment regular tail pointer 
    PA_8b INCR_TAIL_PTR_ONLY(
        .in0({3'd0, tail_ptr_out}), .in1({3'd0, we_cl_byte_cnt}),
        .s(tail_ptr_cl_incr_only_w)
    );


endmodule