/*
Cache Line is consumed as follows: 
[Byte 15] -> ... -> [Byte 0]
Byte 0 is the first byte of the instruction and Byte 15 is the last byte 
*/

module fetch_buffer(
    input wire clk, 
    input wire rst_bar,
    input wire [3:0] from_de_instr_len,
    input wire from_de_valid,
    input wire from_wb_flush,
    input wire from_ex_flush,
    input wire from_de_stall,
    input wire from_f_cl_pf, //the cache line loaded had a page fault
    input wire [127:0] from_f_cache_line, //big endian
    input wire from_de_eip_redirection, //br taken in decode
    input wire ICACHE_VALID, 
    input wire [3:0] offset, //lower eip bits

    output wire shft_reg_we, //from_de_valid, v_cl_ld, flush
    output wire [4:0] tail_ptr,
    output [127:0] to_de_outbytes,
    output wire [15:0] to_de_pf_expn_bytes_out, 
    output ready
);  

    //Endianness Swap (big -> little)
    // wire [127:0] le_cache_line;
    // genvar b;
    // generate
    //     for (b = 0; b < 16; b = b + 1) begin : BYTE_REVERSAL
    //         assign le_cache_line[(b*8) + 7 : b*8] = from_f_cache_line[((15-b)*8) + 7 : (15-b)*8];
    //     end
    // endgenerate

    //Flush Signal Generation 
    wire v_cl_ld, v_cl_ld_bar, from_de_cache_line_load_signal, from_de_eip_redirection_valid, fb_req_cl_stable;
    wire [4:0] wr_cl_byte_cnt;
    wire flush, flush_bar;
    and2$ and_eip_redir_valid(from_de_eip_redirection_valid, from_de_eip_redirection, from_de_valid);
    or2$ or_flush(flush, from_ex_flush, from_de_eip_redirection_valid); //only flush when there is a valid cache line load signal to prevent flushing the buffer with invalid data
    inv1$ inv_flush_bar(flush_bar, flush);
    
    //Shift Enable Register Logic (WE = ~IF_FULL && ICACHE_VALID)
    wire cl_write_shft_we, shft_reg_we_internal;
    and2$ shft_reg_we_gate(.in0(ICACHE_VALID), .in1(v_cl_ld), .out(cl_write_shft_we));
    or3$ or_shft_reg_we_internal(shft_reg_we_internal, cl_write_shft_we, from_de_valid, flush); //also shift when consuming instructions (branch taken or flush in execute)

    //Generate fetch buffer enable signal
    or2$ or_shft_reg_we(shft_reg_we, cl_write_shft_we, flush); //do not enable any time there is a valid instruction in decodeto prevent shifting by a cache line each time

    //True Consume Logic
    wire [3:0] gated_instr_len;
    wire true_consume, stall_bar; 
    inv1$ inv_stall_bar(stall_bar, from_de_stall);
    and2$ and_true_consume(true_consume, from_de_valid, stall_bar); //only consume instruction (decr tail ptr) if de is valid and not stalled
    
    //Correct Instruction Length
    and2$ gate_len0(gated_instr_len[0], from_de_instr_len[0], true_consume);
    and2$ gate_len1(gated_instr_len[1], from_de_instr_len[1], true_consume);
    and2$ gate_len2(gated_instr_len[2], from_de_instr_len[2], true_consume);
    and2$ gate_len3(gated_instr_len[3], from_de_instr_len[3], true_consume);

    //Cache Line Load Sign Generation
    and3$ and_v_cl_ld(v_cl_ld, fb_req_cl_stable, rst_bar, ICACHE_VALID); 
    inv1$ inv_load(v_cl_ld_bar, v_cl_ld);
    
    //Tail Pointer Logic
    wire unaligned_eip_redir; //assigned by cl shifter logic
    logic_tail_ptr LOGIC_TAIL_PTR(
        .clk(clk),
        .rst_bar(rst_bar),
        .incr_amt(gated_instr_len),
        .offset(offset),
        .shft_reg_we(shft_reg_we_internal),
        .flush(flush),
        .stall(from_de_stall),
        .fb_req_cl(v_cl_ld), //input, fetch buffer request cache line signal (if there is space in the fetch buffer)
        .unaligned_eip_redir(unaligned_eip_redir),
        .tail_ptr(tail_ptr)
    );

    mag_comp8$ CL_comp( //tail_ptr < 16
        .A({8'd16}), 
        .B({3'b000, tail_ptr}), 
        .AGB(from_de_cache_line_load_signal), //a > b
        .BGA() 
    );

    wire gated_load_request, gated_load_request_w;
    and2$ gate_req(gated_load_request_w, from_de_cache_line_load_signal, v_cl_ld_bar);
    or2$ or_req(gated_load_request, gated_load_request_w, flush); //also consider flush as a load request to prevent accepting new instructions during a flush
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
        .out(wr_en_w),
        .in0({{16{1'b0}}, {16{1'b1}}}), 
        .in1({{15{1'b0}}, {16{1'b1}}, {1{1'b0}}}), 
        .in2 ({{14{1'b0}}, {16{1'b1}}, {2{1'b0}}}),   // bits [17:2]
        .in3 ({{13{1'b0}}, {16{1'b1}}, {3{1'b0}}}),   // bits [18:3]
        .in4 ({{12{1'b0}}, {16{1'b1}}, {4{1'b0}}}),   // bits [19:4]
        .in5 ({{11{1'b0}}, {16{1'b1}}, {5{1'b0}}}),   // bits [20:5]
        .in6 ({{10{1'b0}},  {16{1'b1}}, {6{1'b0}}}),   // bits [21:6]
        .in7 ({{9{1'b0}},  {16{1'b1}}, {7{1'b0}}}),   // bits [22:7]
        .in8 ({{8{1'b0}},  {16{1'b1}}, {8{1'b0}}}),   // bits [23:8]
        .in9 ({{7{1'b0}},  {16{1'b1}}, {9{1'b0}}}),   // bits [24:9]
        .in10({{6{1'b0}},  {16{1'b1}}, {10{1'b0}}}),  // bits [25:10]
        .in11({{5{1'b0}},  {16{1'b1}}, {11{1'b0}}}),  // bits [26:11]
        .in12({{4{1'b0}},  {16{1'b1}}, {12{1'b0}}}),  // bits [27:12]
        .in13({{3{1'b0}},  {16{1'b1}}, {13{1'b0}}}),  // bits [28:13]
        .in14({{2{1'b0}},  {16{1'b1}}, {14{1'b0}}}),  // bits [29:14]
        .in15({1'b0, {16{1'b1}}, {15{1'b0}}}),               // bits [30:15]
        .s0(tail_ptr[0]), .s1(tail_ptr[1]), .s2(tail_ptr[2]), .s3(tail_ptr[3])
    );

    //Shift Logic for Cache Line (before entering shift buffer)
    wire [247:0] cl_aligned;
    logic_cl_shifter LOGIC_CL_SHIFTER(
        .offset(offset),
        .cl(from_f_cache_line), //le_cache_line
        .tail_ptr(tail_ptr),

        .unaligned_eip_redir(unaligned_eip_redir),
        .cl_aligned(cl_aligned)
    );

    //Fetch Buffer
    wire shft_reg_clr_bar, ready_fb;
    and2$ and_shft_reg_clr_bar(shft_reg_clr_bar, rst_bar, flush_bar); 
    shift_reg FETCH_BUFFER(
        .clk(clk), .rst_n(shft_reg_clr_bar), 
        .shift(shft_reg_we_internal), .instr_len(gated_instr_len), 
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
    shift_reg PAGE_FAULT_BYTES(.clk(clk), .rst_n(shft_reg_clr_bar), .shift(shft_reg_we_internal), .instr_len(gated_instr_len), .inbytes(pf_expn_bits_in), 
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