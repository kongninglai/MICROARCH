/* Estimated delay = 1.66 ns. -VR, 3/27/26 */

module logic_cl_shifter(
    input wire [3:0] eip_lower_bits,
    input wire [127:0] cl,
    input wire [4:0] tail_ptr, 

    output wire [247:0] cl_aligned,
    output wire [4:0] wr_cl_byte_cnt //only account for number of bytes of cache line we are writing
);
    wire  unaligned_eip;
    or4$    or4$_unaligned_eip(unaligned_eip, eip_lower_bits[0], eip_lower_bits[1], eip_lower_bits[2], eip_lower_bits[3]);

    wire  tail_ptr_bottom_four_bits_zero, tail_ptr_zero_and_unaligned_eip, tail_ptr_zero_and_unaligned_eip_buf1024;
    nor4$   nor4$_tail_ptr_bottom_four_bits_zero( tail_ptr_bottom_four_bits_zero,
                                                  tail_ptr[0],
                                                  tail_ptr[1],
                                                  tail_ptr[2],
                                                  tail_ptr[3]);

    // If tail_ptr_bottom_four_bits_zero == 1 and tail_ptr[4] == 0, then tail_ptr_zero
    wire  tail_ptr_bit_4_bar;
    inv1$   inv1$_tail_ptr_bit_4_bar(tail_ptr_bit_4_bar, tail_ptr[4]);
    and3$   and3$_tail_ptr_zero_and_unaligned_eip(tail_ptr_zero_and_unaligned_eip, 
                                                  tail_ptr_bit_4_bar, 
                                                  tail_ptr_bottom_four_bits_zero,
                                                  unaligned_eip);

    bufferH1024$    bufferH1024$_tail_ptr_zero_and_unaligned_eip_buf1024( tail_ptr_zero_and_unaligned_eip_buf1024, 
                                                                          tail_ptr_zero_and_unaligned_eip);

    wire  [3:0]   eip_lower_bits_bar, eip_lower_bits_bar_plus_1;
    inv1$   inv1$_eip_lower_bits_bar[3:0](eip_lower_bits_bar, eip_lower_bits);

    big_increment #(
      .WIDTH(4)
    ) big_increment_eip_lower_bits_bar_plus_1 (
      .a(eip_lower_bits_bar),
      .s(eip_lower_bits_bar_plus_1)
    );

    wire [7:0] wr_cl_byte_cnt_temp;
    assign wr_cl_byte_cnt = wr_cl_byte_cnt_temp[4:0];
    mux2_8$ byte_cnt_mux(.Y(wr_cl_byte_cnt_temp), .IN0({3'b0, 5'd16}), .IN1({4'b0, eip_lower_bits_bar_plus_1}), .S0(tail_ptr_zero_and_unaligned_eip_buf1024));

    //Jump to Middle of Cache Line (Shift CL right - little endian)
    wire [127:0] rshft_cl_jmp;
    rshf_bytes_var_128b #(.WIDTH(128), .SHF_ZEROS(1)) rshf_cl(
        .in(cl),
        .shf_amt(eip_lower_bits),
        .out(rshft_cl_jmp)
    );

        //Regular Cache line (only align with tailpointer)
        wire [255:0] lshft_cl;
        lshf_bytes_var_256b #(.WIDTH(256), .SHF_ZEROS(1)) lshf_cl_aligned( //align with tail pointer
            .in({128'd0, cl}),
            .shf_amt(tail_ptr), //when doing this shifting logic, tail_ptr < 16 bc we req cl
            .out(lshft_cl)
        );

        wire [255:0] final_cl_256;
        mux2_256 final_cl(
            .out(final_cl_256), .in0(lshft_cl), .in1({128'd0, rshft_cl_jmp}), .s0(tail_ptr_zero_and_unaligned_eip_buf1024)
        );

        assign cl_aligned = final_cl_256[247:0];

    endmodule