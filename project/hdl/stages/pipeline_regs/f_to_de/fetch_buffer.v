/*
Cache Line is consumed as follows: 
[Byte 15] -> ... -> [Byte 0]
Byte 0 is the first byte of the instruction and Byte 15 is the last byte 
*/

module fetch_buffer(
    input wire clk, 
    input wire rst_bar,
    input wire [3:0] from_de_instr_len,
    input wire from_f_icache_valid,
    input wire from_de_valid,
    input wire from_wb_flush,
    input wire from_ex_flush,
    input wire from_de_stall,
    input wire from_f_cl_pf, //the cache line loaded had a page fault
    input wire [127:0] from_f_cache_line, //big endian
    input wire from_de_eip_redirection, //br taken in decode
    input wire shft_reg_we,
    output wire [4:0] tail_ptr,
    output [127:0] to_de_outbytes,
    output wire [15:0] to_de_pf_expn_bytes_out, 
    output ready
);  

    //Endianness Swap (big -> little)
    wire [127:0] le_cache_line;
    genvar b;
    generate
        for (b = 0; b < 16; b = b + 1) begin : BYTE_REVERSAL
            assign le_cache_line[(b*8) + 7 : b*8] = from_f_cache_line[((15-b)*8) + 7 : (15-b)*8];
        end
    endgenerate

    //Correct Instruction Length
    wire [3:0] gated_instr_len;
    and2$ gate_len0(gated_instr_len[0], from_de_instr_len[0], from_de_valid);
    and2$ gate_len1(gated_instr_len[1], from_de_instr_len[1], from_de_valid);
    and2$ gate_len2(gated_instr_len[2], from_de_instr_len[2], from_de_valid);
    and2$ gate_len3(gated_instr_len[3], from_de_instr_len[3], from_de_valid);

    //Tail Pointer Logic
    wire v_cl_ld, v_cl_ld_bar, from_de_cache_line_load_signal, from_de_eip_redirection_valid, fb_req_cl_stable;
    wire [4:0] wr_cl_byte_cnt;
    wire flush, flush_bar;
    and2$ and_eip_redir_valid(from_de_eip_redirection_valid, from_de_eip_redirection, from_de_valid);
    or3$ or_flush(flush, from_wb_flush, from_ex_flush, from_de_eip_redirection_valid); //only flush when there is a valid cache line load signal to prevent flushing the buffer with invalid data
    inv1$ inv_flush_bar(flush_bar, flush);
    and3$ and_v_cl_ld(v_cl_ld, fb_req_cl_stable, rst_bar, from_f_icache_valid); 
    inv1$ inv_load(v_cl_ld_bar, v_cl_ld);
    
    logic_tail_ptr LOGIC_TAIL_PTR(
        .clk(clk),
        .rst_bar(rst_bar),
        .incr_amt(gated_instr_len),
        .de_valid(from_de_valid),
        .flush(flush),
        .stall(from_de_stall),
        .fb_req_cl(v_cl_ld), //input, fetch buffer request cache line signal (if there is space in the fetch buffer)
        .we_cl_byte_cnt(wr_cl_byte_cnt),
        .tail_ptr(tail_ptr)
    );

    mag_comp8$ CL_comp( //tail_ptr < 16
        .A({8'd16}), 
        .B({3'b000, tail_ptr}), 
        .AGB(from_de_cache_line_load_signal), //a > b
        .BGA() 
    );

    wire gated_load_request;
    and2$ gate_req(gated_load_request, from_de_cache_line_load_signal, v_cl_ld_bar);
    dff$ CL_REQ_HOLD(
        .clk(clk), .r(rst_bar), .s(1'b1),
        .d(gated_load_request),
        .q(fb_req_cl_stable),
        .qbar()
    );

    //WE Logic
    wire [30:0] wr_en, wr_en_ungated;
    wire [31:0] wr_en_w;
    assign wr_en_ungated = wr_en_w[30:0];

    //Gate wr_en with cache line load signal to prevent spurious writes
    genvar g;
    generate
        for (g = 0; g < 31; g = g + 1) begin : WR_EN_GATE
            and2$ and_wr_en_gate(wr_en[g], wr_en_ungated[g], v_cl_ld);
        end
    endgenerate
    mux16_32 we_mask_mux(
        .Y(wr_en_w),
        .IN0({{16{1'b0}}, {16{1'b1}}}), 
        .IN1({{15{1'b0}}, {16{1'b1}}, {1{1'b0}}}), 
        .IN2 ({{14{1'b0}}, {16{1'b1}}, {2{1'b0}}}),   // bits [17:2]
        .IN3 ({{13{1'b0}}, {16{1'b1}}, {3{1'b0}}}),   // bits [18:3]
        .IN4 ({{12{1'b0}}, {16{1'b1}}, {4{1'b0}}}),   // bits [19:4]
        .IN5 ({{11{1'b0}}, {16{1'b1}}, {5{1'b0}}}),   // bits [20:5]
        .IN6 ({{10{1'b0}},  {16{1'b1}}, {6{1'b0}}}),   // bits [21:6]
        .IN7 ({{9{1'b0}},  {16{1'b1}}, {7{1'b0}}}),   // bits [22:7]
        .IN8 ({{8{1'b0}},  {16{1'b1}}, {8{1'b0}}}),   // bits [23:8]
        .IN9 ({{7{1'b0}},  {16{1'b1}}, {9{1'b0}}}),   // bits [24:9]
        .IN10({{6{1'b0}},  {16{1'b1}}, {10{1'b0}}}),  // bits [25:10]
        .IN11({{5{1'b0}},  {16{1'b1}}, {11{1'b0}}}),  // bits [26:11]
        .IN12({{4{1'b0}},  {16{1'b1}}, {12{1'b0}}}),  // bits [27:12]
        .IN13({{3{1'b0}},  {16{1'b1}}, {13{1'b0}}}),  // bits [28:13]
        .IN14({{2{1'b0}},  {16{1'b1}}, {14{1'b0}}}),  // bits [29:14]
        .IN15({1'b0, {16{1'b1}}, {15{1'b0}}}),               // bits [30:15]
        .S0(tail_ptr[0]), .S1(tail_ptr[1]), .S2(tail_ptr[2]), .S3(tail_ptr[3])
    );

    //Shift Logic for Cache Line (before entering shift buffer)
    wire [247:0] cl_aligned;
    logic_cl_shifter LOGIC_CL_SHIFTER(
        .incr_amt(gated_instr_len),
        .eip_redirection(flush),
        .cl(le_cache_line),
        .tail_ptr(tail_ptr),
        .cl_aligned(cl_aligned),
        .wr_cl_byte_cnt(wr_cl_byte_cnt)
    );

    //Shift Buffer
    wire shift_signal, shift_reg_we, shift_reg_en;
    or3$ or_shift_signal(shift_signal, from_de_valid, v_cl_ld, flush); 
    and2$ and_shft_reg_en(shift_reg_en, shift_signal, shft_reg_we);
    wire shft_reg_clr_bar, ready_fb;
    and2$ and_shft_reg_clr_bar(shft_reg_clr_bar, rst_bar, flush_bar); 
    shift_reg FETCH_BUFFER(
        .clk(clk), .rst_n(shft_reg_clr_bar), 
        .shift(shift_reg_en), .instr_len(gated_instr_len), 
        .inbytes(cl_aligned), .wr_en(wr_en), 
        .outbytes(to_de_outbytes[127:0]), .ready(ready_fb)
    ); 

    //Page Fault Shifter
    wire [247:0] pf_expn_bits_in;
    wire [127:0] pf_expn_bits_out;
    
    genvar i;
    generate //convert pf_expn_bytes_in to bits
        for (i = 0; i < 31; i=i+1) begin : PF_BYTE_GEN
            assign pf_expn_bits_in[i*8] = from_f_cl_pf;
            assign pf_expn_bits_in[(i*8)+7 : (i*8)+1] = 7'bx;        
        end
    endgenerate

    wire ready_pfb;
    shift_reg PAGE_FAULT_BYTES(.clk(clk), .rst_n(shft_reg_clr_bar), .shift(shift_reg_en), .instr_len(gated_instr_len), .inbytes(pf_expn_bits_in), 
        .wr_en(wr_en), .outbytes(pf_expn_bits_out), .ready(ready_pfb)
    ); 

    genvar j;
    generate //convert pf_expn_bits_out to bytes
        for (j = 0; j < 16; j=j+1) begin : PF_OUT_GEN
            assign to_de_pf_expn_bytes_out[j] = pf_expn_bits_out[j*8];
        end
    endgenerate

    //Ready Logic (might not need to do with an and of both ready signals, but just to be safe for now)
    and2$ and_ready(ready, ready_fb, ready_pfb);

endmodule