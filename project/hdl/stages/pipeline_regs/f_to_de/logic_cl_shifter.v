/*
Notes: 
- Use tail ptr rather than eip redirection signal because tail ptr is a latched value and it is
slightly messy to rely on eip redirection signal to arrive on a correct time.
- Also use offset to jump to the middle of a cache line. 
*/

module logic_cl_shifter(
    input wire [3:0] offset, //from eip[3:0], how much to shift by for jump to middle of cache line
    input wire [127:0] cl,
    input wire [4:0] tail_ptr, 

    output wire unaligned_eip_redir, 
    output wire [247:0] cl_aligned
);

    //Jump Middle of Cache Line Signal Logic (If tail_ptr zero - there was a flush, and eip is unaligned, then middle of cache line jump)
    //Use tail pointer instead of eip redirection signal bc tail pointer is latched and eip redir is combinational
    wire tail_ptr_zero_4bit, tail_ptr_zero_bar, tail_ptr_zero_1bit, eip_unaligned_bar;
    inv1$ inv_tail_ptr_zero(.in(tail_ptr[4]), .out(tail_ptr_zero_1bit));
    nor4$ nor_tail_ptr_zero( //if offset bits are all 0, then flush has occured or startup
        .in0(tail_ptr[3]), .in1(tail_ptr[2]), .in2(tail_ptr[1]), .in3(tail_ptr[0]),
        .out(tail_ptr_zero_4bit)
    );
    nand2$ nand_tail_ptr_zero(.in0(tail_ptr_zero_4bit), .in1(tail_ptr_zero_1bit), .out(tail_ptr_zero_bar));

    nor4$ nor_eip_unaligned_bar(
        .in0(offset[0]), .in1(offset[1]), .in2(offset[2]), .in3(offset[3]),
        .out(eip_unaligned_bar)
    );

    nor2$ and_middle_jmp(.in0(eip_unaligned_bar), .in1(tail_ptr_zero_bar), .out(unaligned_eip_redir));


    //Jump to Middle of Cache Line Shift (Shift CL right - little endian)
    wire [127:0] rshft_cl_jmp;
    rshf_bytes_var_128b #(.WIDTH(128), .SHF_ZEROS(1)) rshf_cl(
        .in(cl),
        .shf_amt(offset),
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
        .out(final_cl_256), .in0(lshft_cl), .in1({128'd0, rshft_cl_jmp}), .s0(unaligned_eip_redir)
    );

    assign cl_aligned = final_cl_256[247:0];

endmodule
