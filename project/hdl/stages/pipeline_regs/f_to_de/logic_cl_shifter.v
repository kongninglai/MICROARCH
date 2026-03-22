module logic_cl_shifter(
    input wire icache_miss,
    input wire sb_miss, //stream buffer
    input wire [127:0] cl,
    input wire from_de_cache_line_load_signal,
    input wire [4:0] tail_ptr, 

    output wire [127:0] shifted_cl,
    output wire shft_reg_we,
    



);

endmodule