module shift_reg(
    input             clk,
    input             rst_n,
    input             shift,
    input             flush,            /* NEW: VR */
    input   [3:0]     instr_len,        /* NEW: VR */
    input   [247:0]   inbytes,
    input             global_wr_en,     /* NEW: VR */
    input   [4:0]     wr_cl_byte_cnt,   /* NEW: VR */
    input   [30:0]    wr_en,
    output  [127:0]   outbytes,
    output  [4:0]     tail_ptr,
    output            ready
); 
    /*** Tail pointer logic ***/

    /* Load enable tail pointer when shifting, flushing, or writing */
    wire  tail_ptr_load_enable_bar, tail_ptr_load_enable_buf16;
    nor3$   nor3$_tail_ptr_load_enable_bar(tail_ptr_load_enable_bar, shift, global_wr_en, flush);
    bufferHInv16$ bufferHInv16$_tail_ptr_load_enable_buf16(tail_ptr_load_enable_buf16, tail_ptr_load_enable_bar);

    /* Increment by 16 (set tail_ptr[4]) if wr_cl_byte_cnt[4] == 1;
        otherwise, just set tail_ptr = {1'b0, # bytes loaded [3:0]} since this only happens when tail_ptr starts at 0 (after a flush) */
    wire [2:0]  next_inc_tail_ptr_dummy;
    wire [4:0]  next_inc_tail_ptr;

    mux2_8$   mux2_8$_next_inc_tail_ptr (
      {next_inc_tail_ptr_dummy, next_inc_tail_ptr},
      {3'd0, 1'b0, wr_cl_byte_cnt[3:0]},
      {3'd0, 1'b1, tail_ptr[3:0]},
      wr_cl_byte_cnt[4]
    );

    /* Decrement by instruction length */
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

    wire [2:0]  next_dec_tail_ptr_dummy;
    wire [4:0]  next_dec_tail_ptr;

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
      .s0(instr_len[0]),
      .s1(instr_len[1]),
      .s2(instr_len[2]),
      .s3(instr_len[3]),
      .outb({next_dec_tail_ptr_dummy, next_dec_tail_ptr})
    );

    wire [2:0] next_tail_ptr_dummy;
    wire [4:0] next_tail_ptr;

    mux4_8$   mux4_8$_next_inc_tail_ptr (
      {next_tail_ptr_dummy, next_tail_ptr},
      {3'd0, tail_ptr},                       /* Don't change */
      {3'd0, next_inc_tail_ptr},              /* Only writing, no shifting. Pure increment */
      {3'd0, next_dec_tail_ptr},              /* No writing, only shifting. Pure decrement */
      {3'd0, 1'b1, next_dec_tail_ptr[3:0]},   /* Writing and shifting. Must be writing 16 bytes. */
      global_wr_en,
      shift
    );

    wire [2:0] next_tail_ptr_final_dummy;
    wire [4:0] next_tail_ptr_final;

    mux2_8$   mux2_8$_next_tail_ptr_final (
      {next_tail_ptr_final_dummy, next_tail_ptr_final},
      {3'd0, next_tail_ptr},                 
      8'd0,
      flush
    );

    reg_n #(
      .WIDTH(5),
      .USE_EN_BAR(0)
    ) reg_n_tail_ptr (
      .clk(clk), .rst(rst_n),
      .en({5{tail_ptr_load_enable_buf16}}), .d(next_tail_ptr_final),
      .q(tail_ptr)
    );

    /* Handle re-arrangement of input cache line */
    wire [7:0] inbytes_i[30:0];
    wire [7:0] q[30:0];

    wire [7:0] d[30:0];
    wire [30:0] en;

    generate 
        for (i = 0; i < 31; i=i+1) begin : in_bytes_gen
            assign inbytes_i[i] = inbytes[i*8+7:i*8];
        end
    endgenerate

    wire [7:0] updated_q[45:0];

    generate
      for (i = 31; i <= 45; i = i + 1) begin : dummy_updated_q_gen
        assign updated_q[i] = 8'd0;
      end
    endgenerate

    generate 
        for (i = 0; i < 31; i=i+1) begin : shift_input_mux_gen
            wire [3:0] update_idx;
            wire not_shift, not_shift_and_wr;
            mux2_8$ mux2_8_update(updated_q[i], q[i], inbytes_i[i], wr_en[i]);
    
            mux2$ mux_update_idx[3:0](update_idx, 4'd0, instr_len, shift);
            mux16_8b mux16_8b_shift(d[i], updated_q[i], updated_q[i+1], updated_q[i+2], updated_q[i+3], 
                                        updated_q[i+4], updated_q[i+5], updated_q[i+6], updated_q[i+7], 
                                        updated_q[i+8], updated_q[i+9], updated_q[i+10], updated_q[i+11], 
                                        updated_q[i+12], updated_q[i+13], updated_q[i+14], updated_q[i+15], 
                                        update_idx[0], update_idx[1], update_idx[2], update_idx[3]);
            inv1$ inv_shift(not_shift, shift);
            and2$ and_not_shift_and_wr(not_shift_and_wr, not_shift, wr_en[i]);

            or2$ or_en(en[i], shift, not_shift_and_wr);
            reg_n #(
                .WIDTH(8),
                .USE_EN_BAR(0)
            ) reg_n_output_byte (
                .clk(clk), .rst(rst_n),
                .en({8{en[i]}}), .d(d[i]),
                .q(q[i])
            );
        end
    endgenerate
    
    assign outbytes = {q[15], q[14], q[13], q[12], q[11], q[10], q[9], q[8], q[7], q[6], q[5], q[4], q[3], q[2], q[1], q[0]};
    inv1$   inv1$_ready(ready, tail_ptr[4]);
endmodule