module f_to_de(
    input wire clk, 
    input wire rst_bar,

    //Fetch Buffer Inputs
    input wire from_de_instr_len,
    input wire from_de_cache_line_load_signal,
    input wire [127:0] from_f_cache_line,

    input wire [30:0] from_f_page_fault_bits,

    output wire [1:0] to_de_exception_flags,
    output wire [127:0] to_de_cache_line

);



endmodule