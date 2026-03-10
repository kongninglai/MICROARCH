module gpr_shifter (
    output [31:0] read_out,
    input [1:0] datasize,
    input [2:0] read_idx,
    input [31:0] read_data
); 
    wire [31:0] read_low8, read_high8, read8, read16;
    assign read_low8 = {24'b0, read_data[7:0]};
    assign read_high8 = {24'b0, read_data[15:8]};
    mux2$ mux2_read8[31:0](read8, read_low8, read_high8, read_idx[2]);
    assign read16 = {16'b0, read_data[15:0]};
    mux4$ mux4_readdata[31:0](read_out, read8, read16, read_data, read_data, datasize[0], datasize[1]);
endmodule