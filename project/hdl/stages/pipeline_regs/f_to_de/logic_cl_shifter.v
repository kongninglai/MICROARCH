module logic_cl_shifter(
    input wire [3:0] incr_amt,
    input wire eip_redirection, //br taken in decode, mispredict in execute, exception in wb
    input wire [127:0] cl,
    input wire [4:0] tail_ptr, 

    output wire [247:0] cl_aligned,
    output wire [4:0] wr_cl_byte_cnt //only account for number of bytes of cache line we are writing
);

    //Jump to Middle of Cache Line (Shift CL right - little endian)
    wire [127:0] rshft_cl_jmp;
    rshf_bytes_var_128b #(.WIDTH(128), .SHF_ZEROS(1)) rshf_cl(
        .in(cl),
        .shf_amt(incr_amt[3:0]),
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
        .out(final_cl_256), .in0(lshft_cl), .in1({128'd0, rshft_cl_jmp}), .s0(eip_redirection)
    );

    assign cl_aligned = final_cl_256[247:0];

endmodule