module logic_tail_ptr(
    input wire clk,
    input wire rst_bar,
    input wire [3:0] incr_amt, //gated instr length
    input wire [3:0] offset, //eip bottom bits
    input wire shft_reg_we,
    input wire flush,
    input wire stall,
    input wire fb_req_cl, //fetch buffer request cache line signal (if there is space in the fetch buffer)
    input wire unaligned_eip_redir, //br taken in decode, mispredict in execute, exception in wb
    output wire [4:0] tail_ptr
);

    wire tail_ptr_en;
    wire [7:0] tail_ptr_in_w, tail_ptr_decr_w, tail_ptr_cl_incr_w, tail_ptr_cl_incr_only_w, tail_ptr_w;
    wire [1:0] tail_ptr_cl_incr_2bit, tail_ptr_cl_incr_only_2bit;
    wire [4:0] tail_ptr_in;
    wire [3:0] we_cl_byte_cnt_w, we_cl_byte_cnt;

    //Choose Tail Pointer input (00 decr, 01 cl_incr, 10 same, 11 cl_incr_only)/* Decrement by instruction length */
    wire [2:0]  next_dec_tail_ptrs_dummy[0:16];
    wire [4:0]  next_dec_tail_ptrs[0:15];
    wire [7:0]  negated_i[0:15];

    assign negated_i[ 0] = -8'd0;
    assign negated_i[ 1] = -8'd1;
    assign negated_i[ 2] = -8'd2;
    assign negated_i[ 3] = -8'd3;
    assign negated_i[ 4] = -8'd4;
    assign negated_i[ 5] = -8'd5;
    assign negated_i[ 6] = -8'd6;
    assign negated_i[ 7] = -8'd7;
    assign negated_i[ 8] = -8'd8;
    assign negated_i[ 9] = -8'd9;
    assign negated_i[10] = -8'd10;
    assign negated_i[11] = -8'd11;
    assign negated_i[12] = -8'd12;
    assign negated_i[13] = -8'd13;
    assign negated_i[14] = -8'd14;
    assign negated_i[15] = -8'd15;

    /* Precompute difference */
    genvar i;
    generate
      for (i = 0; i < 16; i = i + 1) begin : dec_tail_ptr_gen
        PA_8b PA_8b_next_dec_tail_ptr (
          .in0({3'd0, tail_ptr}), .in1(negated_i[i]),
          .s({next_dec_tail_ptrs_dummy[i], next_dec_tail_ptrs[i]})
        );
      end
    endgenerate

    mux16_8b mux16_8b_next_dec_tail_ptr (
      .in0 ({3'd0, next_dec_tail_ptrs[0 ]}),
      .in1 ({3'd0, next_dec_tail_ptrs[1 ]}),
      .in2 ({3'd0, next_dec_tail_ptrs[2 ]}),
      .in3 ({3'd0, next_dec_tail_ptrs[3 ]}),
      .in4 ({3'd0, next_dec_tail_ptrs[4 ]}),
      .in5 ({3'd0, next_dec_tail_ptrs[5 ]}),
      .in6 ({3'd0, next_dec_tail_ptrs[6 ]}),
      .in7 ({3'd0, next_dec_tail_ptrs[7 ]}),
      .in8 ({3'd0, next_dec_tail_ptrs[8 ]}),
      .in9 ({3'd0, next_dec_tail_ptrs[9 ]}),
      .in10({3'd0, next_dec_tail_ptrs[10]}),
      .in11({3'd0, next_dec_tail_ptrs[11]}),
      .in12({3'd0, next_dec_tail_ptrs[12]}),
      .in13({3'd0, next_dec_tail_ptrs[13]}),
      .in14({3'd0, next_dec_tail_ptrs[14]}),
      .in15({3'd0, next_dec_tail_ptrs[15]}),
      .s0(incr_amt[0]),
      .s1(incr_amt[1]),
      .s2(incr_amt[2]),
      .s3(incr_amt[3]),
      .outb(tail_ptr_decr_w)
    );

    assign tail_ptr_cl_incr_w = {3'd0, 1'b1, tail_ptr_decr_w[3:0]};

    mux2_8$ mux2_8$_tail_ptr_cl_incr_only_w
    (
      tail_ptr_cl_incr_only_w,
      {3'd0, 1'b1, tail_ptr[3:0]},
      {3'd0, 1'b0, we_cl_byte_cnt[3:0]},
      unaligned_eip_redir
    );

    wire zero_inst_len;
    nor4$ nor4$_zero_inst_len(zero_inst_len,  incr_amt[0],
                                              incr_amt[1],
                                              incr_amt[2],
                                              incr_amt[3]);

    mux4_8$ mux_tail_ptr_in(
        .Y(tail_ptr_in_w), 
        .IN0(tail_ptr_decr_w), .IN1(tail_ptr_cl_incr_w), .IN2(tail_ptr_w), .IN3(tail_ptr_cl_incr_only_w),
        .S0(fb_req_cl), .S1(zero_inst_len)
    );
    assign tail_ptr_w = {3'd0, tail_ptr};
    assign tail_ptr_in = tail_ptr_in_w[4:0];

    //Tail pointer
    wire CLR, CLR_BAR, flush_bar;
    wire tail_ptr_en_bar;
    nor2$ or_tail_ptr_en_bar(tail_ptr_en_bar, shft_reg_we, flush);
    bufferHInv16$ bufferHInv16$_tail_ptr_en(tail_ptr_en, tail_ptr_en_bar);

    inv1$ inv_flush(flush_bar, flush);
    nand2$ nand_clear(CLR, rst_bar, flush_bar); //(if either rst of flush is a 0, we want to clear)
    bufferHInv16$ bufferHInv16$_CLR_BAR(CLR_BAR, CLR);

    wire [4:0] tail_ptr_prebuf;
    reg_n #(.WIDTH(5)) tail_ptr_reg (
        .clk(clk),
        .rst(CLR_BAR),
        .en({5{tail_ptr_en}}),
        .d(tail_ptr_in),
        .q(tail_ptr_prebuf)
    );

    bufferH64$    bufferH64$_tail_ptr[4:0](tail_ptr, tail_ptr_prebuf);

    //Number of Bytes to write from Cache Line Logic
    wire [3:0] offset_bar;
    inv1$ inv_offset_0 (offset_bar[0], offset[0]);
    inv1$ inv_offset_1 (offset_bar[1], offset[1]);
    inv1$ inv_offset_2 (offset_bar[2], offset[2]);
    inv1$ inv_offset_3 (offset_bar[3], offset[3]);

    big_increment #(.WIDTH(4)) two_complement_incrementer( //on flush (br, mispredict, exception), if writing a partial cache line 
        .a(offset_bar),
        .s(we_cl_byte_cnt_w) 
    );

    wire [7:0] we_cl_byte_cnt_temp;
    assign we_cl_byte_cnt = we_cl_byte_cnt_temp[3:0];
    mux2_8$ byte_cnt_mux(.Y(we_cl_byte_cnt_temp), .IN0({3'b0, 5'd16}), .IN1({4'b0, we_cl_byte_cnt_w}), .S0(unaligned_eip_redir));

endmodule