module f_to_de(
    input wire clk, 
    input wire rst_bar,

    //Fetch Buffer Inputs
    input wire from_de_instr_len,
    input wire from_de_cache_line_load_signal,
    input wire [127:0] from_f_cache_line,
    input wire from_f_icache_valid,
    input wire from_de_valid,
    input wire from_wb_flush,
    input wire from_ex_flush,
    input wire from_de_stall,
    input wire from_f_cl_pf, 
    input wire [31:0] i_eip_in, //also pass in pr to decode
    input wire from_de_eip_redirection,
    input wire shft_reg_we,
    input wire [3:0] from_de_tail_ptr,

    output wire [31:0] to_de_i_eip,
    output wire [1:0] to_de_exception_flags,
    output wire [127:0] to_de_cache_line

);

    wire [15:0] to_de_pf_expn_bytes_out;
    fetch_buffer FETCH_BUF(
        .clk(clk),
        .rst_bar(rst_bar),
        .from_de_instr_len(from_de_instr_len),
        .from_f_icache_valid(from_f_icache_valid),
        .from_de_valid(from_de_valid),
        .from_wb_flush(from_wb_flush),
        .from_ex_flush(from_ex_flush),
        .from_de_stall(from_de_stall),
        .from_f_cl_pf(from_f_cl_pf),
        .from_f_cache_line(from_f_cache_line),
        .i_eip(i_eip_in),
        .from_de_eip_redirection(from_de_eip_redirection),
        .shft_reg_we(shft_reg_we),
        .tail_ptr(from_de_tail_ptr),
        .to_de_outbytes(to_de_cache_line),
        .to_de_pf_expn_bytes_out(to_de_pf_expn_bytes_out),
        .ready(ready)
    );  





endmodule