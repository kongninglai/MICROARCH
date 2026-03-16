module ghr(
    input wire clk, 
    input wire rst_bar,
    input wire [7:0] ghr_in,
    output wire [7:0] ghr_out

);
    dff$ GHR [7:0] (.clk(clk), .d(ghr_in), .q(ghr_out), .qbar(), .r(rst_bar), .s(1'b1));

endmodule