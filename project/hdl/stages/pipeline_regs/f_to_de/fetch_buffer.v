/*
Cache Line is consumed as follows: 
[Byte 15] -> ... -> [Byte 0]
Byte 0 is the first byte of the instruction and Byte 15 is the last byte 
*/

module fetch_buffer(
    input wire clk, 
    input wire rst_bar,
    input wire [3:0] from_de_instr_len,
    input wire [3:0] from_de_eip_lower_bits,
    input wire from_f_icache_valid,
    input wire from_de_valid_and_load_rr,
    input wire from_wb_flush,
    input wire from_ex_flush,
    input wire from_f_cl_pf, //the cache line loaded had a page fault
    input wire [127:0] from_f_cache_line,
    input wire from_de_eip_redirection, //br taken in decode
    output [127:0] to_de_outbytes,
    output wire to_de_pf_expn,
    output wire [4:0] tail_ptr,
    output wire global_wr_en
);  

    wire from_de_valid_and_load_rr_buf1024;
    bufferH1024$ bufferH1024$_from_de_valid_and_load_rr_buf1024(from_de_valid_and_load_rr_buf1024,
                                                                from_de_valid_and_load_rr);

    //Correct Instruction Length
    wire [3:0] gated_instr_len;
    and2$ gate_len[3:0](gated_instr_len, from_de_instr_len, from_de_valid_and_load_rr_buf1024);

    //Tail Pointer Logic
    wire from_de_eip_redirection_valid;
    wire [4:0] wr_cl_byte_cnt;
    wire flush;
    and2$ and_eip_redir_valid(from_de_eip_redirection_valid, from_de_eip_redirection, from_de_valid_and_load_rr_buf1024);
    or3$ or_flush(flush, from_wb_flush, from_ex_flush, from_de_eip_redirection_valid); 


    //WE Logic
    wire [30:0] wr_en, wr_en_ungated;
    wire [31:0] wr_en_w;
    assign wr_en_ungated = wr_en_w[30:0];

    wire global_wr_en, global_wr_en_buf64;
    and2$   and2$_global_wr_en(global_wr_en, from_f_icache_valid, ready);
    bufferH64$    bufferH64$_global_wr_en_buf64(global_wr_en_buf64, global_wr_en);

    //Gate wr_en with I$ valid and fetch buffer has space
    and2$ and_wr_en_gate[30:0](wr_en, wr_en_ungated, global_wr_en_buf64);

    mux16_32 we_mask_mux(
        .Y(wr_en_w),
        .IN0( {1'b0, {15{1'b0}}, {16{1'b1}}}), 
        .IN1( {1'b0, {14{1'b0}}, {16{1'b1}}, {1{1'b0}}}), 
        .IN2 ({1'b0, {13{1'b0}}, {16{1'b1}}, {2{1'b0}}}),   // bits [17:2]
        .IN3 ({1'b0, {12{1'b0}}, {16{1'b1}}, {3{1'b0}}}),   // bits [18:3]
        .IN4 ({1'b0, {11{1'b0}}, {16{1'b1}}, {4{1'b0}}}),   // bits [19:4]
        .IN5 ({1'b0, {10{1'b0}}, {16{1'b1}}, {5{1'b0}}}),   // bits [20:5]
        .IN6 ({1'b0, {9{1'b0}},  {16{1'b1}}, {6{1'b0}}}),   // bits [21:6]
        .IN7 ({1'b0, {8{1'b0}},  {16{1'b1}}, {7{1'b0}}}),   // bits [22:7]
        .IN8 ({1'b0, {7{1'b0}},  {16{1'b1}}, {8{1'b0}}}),   // bits [23:8]
        .IN9 ({1'b0, {6{1'b0}},  {16{1'b1}}, {9{1'b0}}}),   // bits [24:9]
        .IN10({1'b0, {5{1'b0}},  {16{1'b1}}, {10{1'b0}}}),  // bits [25:10]
        .IN11({1'b0, {4{1'b0}},  {16{1'b1}}, {11{1'b0}}}),  // bits [26:11]
        .IN12({1'b0, {3{1'b0}},  {16{1'b1}}, {12{1'b0}}}),  // bits [27:12]
        .IN13({1'b0, {2{1'b0}},  {16{1'b1}}, {13{1'b0}}}),  // bits [28:13]
        .IN14({1'b0, 1'b0,        {16{1'b1}}, {14{1'b0}}}),  // bits [29:14]
        .IN15({1'b0, {16{1'b1}}, {15{1'b0}}}),               // bits [30:15]
        .S0(tail_ptr[0]), .S1(tail_ptr[1]), .S2(tail_ptr[2]), .S3(tail_ptr[3])
    );

    //Shift Logic for Cache Line (before entering shift buffer)
    wire [247:0] cl_aligned;
    logic_cl_shifter LOGIC_CL_SHIFTER(
        .eip_lower_bits(from_de_eip_lower_bits),
        .cl(from_f_cache_line),
        .tail_ptr(tail_ptr),
        .cl_aligned(cl_aligned),
        .wr_cl_byte_cnt(wr_cl_byte_cnt)
    );

    //Shift Buffer
    shift_reg FETCH_BUFFER(
        .clk(clk), .rst_n(rst_bar), 
        .shift(from_de_valid_and_load_rr_buf1024), .flush(flush),
        .instr_len(gated_instr_len), 
        .inbytes(cl_aligned), .global_wr_en(global_wr_en_buf64),
        .wr_cl_byte_cnt(wr_cl_byte_cnt), .wr_en(wr_en),
        .outbytes(to_de_outbytes[127:0]), .tail_ptr(tail_ptr),
        .ready(ready)
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

    wire from_f_cl_pf_buf1024;
    bufferH1024$    bufferH1024$(from_f_cl_pf_buf1024, from_f_cl_pf);

    wire [15:0] pfn_outbits;
    assign to_de_pf_expn = pfn_outbits[0];

    shift_reg_tiny PAGE_FAULT_BYTES(
        .clk(clk), .rst_n(rst_bar), 
        .shift(from_de_valid_and_load_rr_buf1024), .flush(),
        .instr_len(), 
        .inbytes({31{from_f_cl_pf_buf1024}}), .global_wr_en(),
        .wr_cl_byte_cnt(), .wr_en(wr_en),
        .outbytes(pfn_outbits), .tail_ptr(),
        .ready()
    ); 

endmodule