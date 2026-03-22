module fetch_buffer(
    input wire clk, 
    input wire rst_bar,
    input wire from_de_instr_len,
    input wire from_de_valid,
    input wire from_wb_flush,
    input wire from_de_stall,
    input wire [127:0] from_f_cache_line,
    output wire [4:0] tail_ptr
);  

    //Tail Pointer Logic
    wire from_de_cache_line_load_signal;
    logic_tail_ptr(
        .clk(clk),
        .rst_bar(rst_bar),
        .incr_amt(from_de_instr_len),
        .de_valid(from_de_valid),
        .flush(from_wb_flush),
        .stall(from_de_stall),
        .fb_req_cl(from_de_cache_line_load_signal), //fetch buffer request cache line signal (if there is space in the fetch buffer)
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


    //Shift Buffer
    wire shift_signal;
    shift_reg(.clk(clk), .rst_n(rst_bar), .shift(shift_signal), .instr_len(from_de_instr_len), .inbytes(from_f_cache_line), 
                .wr_en(wr_en), .outbytes(to_de_cache_line), .ready(ready));
    ); 

endmodule