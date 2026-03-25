module fetch_buffer(
    input wire clk, 
    input wire rst_bar,
    input wire from_de_instr_len,
    input wire from_de_valid,
    input wire from_wb_flush,
    input wire from_ex_flush,
    input wire from_de_stall,
    input wire from_f_cl_pf, //the cache line loaded had a page fault
    input wire [127:0] from_f_cache_line,
    input wire [31:0] i_eip,
    input wire from_de_eip_redirection, //br taken in decode
    input wire shft_reg_we,
    output wire [4:0] tail_ptr,
    output [127:0] to_de_outbytes,
    output wire [15:0] to_de_pf_expn_bytes_out, 
    output ready
);  

    //Tail Pointer Logic
    wire from_de_cache_line_load_signal;
    wire [4:0] wr_cl_byte_cnt;
    wire flush, flush_bar;
    or3$ and_flush(flush, from_wb_flush, from_ex_flush, from_de_eip_redirection); //only flush when there is a valid cache line load signal to prevent flushing the buffer with invalid data
    inv1$ inv_flush_bar(flush_bar, flush);
    logic_tail_ptr LOGIC_TAIL_PTR(
        .clk(clk),
        .rst_bar(rst_bar),
        .incr_amt(from_de_instr_len),
        .de_valid(from_de_valid),
        .flush(flush),
        .stall(from_de_stall),
        .fb_req_cl(from_de_cache_line_load_signal), //fetch buffer request cache line signal (if there is space in the fetch buffer)
        .we_cl_byte_cnt(wr_cl_byte_cnt),
        .tail_ptr(tail_ptr)
    );

    mag_comp8$ CL_comp( //tail_ptr < 15
        .A({4'd0, 4'd15}), 
        .B({3'b000, B}), 
        .AGB(from_de_cache_line_load_signal), //a > b
        .BGA() 
    );

    //WE Logic
    wire [30:0] wr_en;
    wire [31:0] wr_en_w;
    assign wr_en = wr_en_w[30:0];
    mux16_32 we_mask_mux(
        .Y(wr_en_w),
        .IN0({16'd0, 15'd1}), .IN1({1'd1, 16'd0, 14'd1}), .IN2({2'd1, 16'd0,13'd1}), .IN3({3'd1, 16'd0,12'd1}), .IN4({4'd1, 13'd0,11'd1}), .IN5({5'd1, 16'd0,10'd1}), .IN6({6'd1, 16'd0,9'd1}), .IN7({7'd1, 16'd0,8'd1}), .IN8({8'd1, 16'd0,7'd1}), 
        .IN9({9'd1, 16'd0,6'd1}), .IN10({10'd1, 16'd0,5'd1}), .IN11({11'd1, 16'd0,4'd1}), .IN12({12'd1, 16'd0,3'd1}), .IN13({13'd1, 16'd0,2'd1}), .IN14({14'd1, 16'd0,1'd1}), .IN15({15'd1, 16'd0}), 
        .S0(tail_ptr[4]), .S1(tail_ptr[3]), .S2(tail_ptr[2]), .S3(tail_ptr[1]), .S4(tail_ptr[0])
    );

    //Shift Logic for Cache Line (before entering shift buffer)
    wire [127:0] cl_aligned;
    logic_cl_shifter LOGIC_CL_SHIFTER(
        .incr_amt(from_de_instr_len),
        .eip_redirection(flush),
        .cl(from_f_cache_line),
        .tail_ptr(tail_ptr),
        .cl_aligned(cl_aligned),
        .wr_cl_byte_cnt(wr_cl_byte_cnt),
    );

    //Shift Buffer
    wire shift_signal, shift_reg_we, shift_reg_en, cl_load_while_de_stall;
    and2$ and_cl_load_while_stall(cl_load_while_de_stall, from_de_cache_line_load_signal, from_de_stall);
    or4$ or_shift_signal(shift_signal, from_de_valid, cl_load_while_de_stall, from_wb_flush, from_ex_flush); //shift when there is a valid instruction or when there is a stall (to prevent overwriting the buffer with the same cache line)
    and2$ and_shft_reg_en(shift_reg_en, shift_signal, shft_reg_we);
    wire shft_reg_clr_bar;
    and2$ and_shft_reg_clr_bar(shft_reg_clr_bar, rst_bar, flush_bar); 
    shift_reg FETCH_BUFFER(.clk(clk), .rst_n(shft_reg_clr_bar), .shift(shift_reg_en), .instr_len(from_de_instr_len), .inbytes(cl_aligned), 
                .wr_en(wr_en), .outbytes(to_de_cache_line), .ready(ready));
    ); 

    //Page Fault Shifter
    wire [15:0] pf_expn_bytes_in;
    assign pf_expn_bytes_in = {16{from_f_cl_pf}}
    wire [247:0] pf_expn_bits_in;
    wire [127:0] pf_expn_bits_out;
    
    genvar i;
    generate //convert pf_expn_bytes_in to bits
        for (i = 0; i < 16; i=i+1) begin 
            assign pf_expn_bits_in[i*8] = pf_expn_bytes_in[i];
        end
    endgenerate

    shift_reg PAGE_FAULT_BYTES(.clk(clk), .rst_n(shft_reg_clr_bar), .shift(shift_reg_en), .instr_len(from_de_instr_len), .inbytes(pf_expn_bits_in), 
        .wr_en(wr_en), .outbytes(to_de_pf_expn_bits_out), .ready(ready));
    ); 

    genvar i;
    generate //convert pf_expn_bits_out to bytes
        for (i = 0; i < 16; i=i+1) begin 
            assign to_de_pf_expn_bytes_out[i] = pf_expn_bits_out[i*8];
        end
    endgenerate

endmodule