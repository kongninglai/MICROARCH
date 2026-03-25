module logic_cl_shifter(
    input wire [3:0] incr_amt,
    input wire eip_redirection, //br taken in decode, mispredict in execute, exception in wb
    input wire [127:0] cl,
    input wire [4:0] tail_ptr, 

    output wire [127:0] cl_aligned,
    output wire [4:0] wr_cl_byte_cnt //only account for number of bytes of cache line we are writing
);

    //Number of Bytes to write from Cache Line Logic
    wire [3:0] incr_amt_bar;
    inv1$ inv_eip_0 (incr_amt_bar[0], incr_amt[0]);
    inv1$ inv_eip_1 (incr_amt_bar[1], incr_amt[1]);
    inv1$ inv_eip_2 (incr_amt_bar[2], incr_amt[2]);
    inv1$ inv_eip_3 (incr_amt_bar[3], incr_amt[3]);

    wire [4:0] wr_cl_byte_cnt_w;
    big_increment_cout #(.WIDTH(4)) two_complement_incrementer(
        .a(incr_amt_bar),
        .s(wr_cl_byte_cnt_w[3:0]), .cout(wr_cl_byte_cnt_w[4]) 
    );

    wire [7:0] wr_cl_byte_cnt_temp;
    assign wr_cl_byte_cnt = wr_cl_byte_cnt_temp[4:0];
    mux2_8$ byte_cnt_mux(.Y(wr_cl_byte_cnt_temp), .IN0({3'b0, 5'd16}), .IN1({3'b0, wr_cl_byte_cnt_w}), .S0(eip_redirection));

    //Jump to Middle of Cache Line (Shift CL right - little endian)
    wire [127:0] rshft_cl_jmp;
    rshf_bytes_var_128b #(.WIDTH(128), .SHF_ZEROS(1)) rshf_cl(
        .in(cl),
        .shf_amt(incr_amt[3:0]),
        .out(rshft_cl_jmp)
    );

    //Regular Cache line (only align with tailpointer)
    wire [127:0] lshft_cl;
    lshf_bytes_var_128b #(.WIDTH(128), .SHF_ZEROS(1)) lshf_cl_aligned( //align with tail pointer
        .in(cl),
        .shf_amt(tail_ptr[3:0]), //when doing this shifting logic, tail_ptr < 16 bc we req cl
        .out(lshft_cl)
    );

    mux2_128 final_cl(
        .out(cl_aligned), .in0(lshft_cl), .in1(rshft_cl_jmp), .s0(eip_redirection)
    );

endmodule