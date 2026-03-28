module logic_cl_shifter_behav(
    input  wire [3:0] eip_lower_bits,
    input  wire [127:0] cl,
    input  wire [4:0] tail_ptr, 

    output reg  [247:0] cl_aligned,
    output reg  [4:0]   wr_cl_byte_cnt
);

reg [255:0] temp_cl;

always @(*) begin
    cl_aligned      = 248'd0;
    wr_cl_byte_cnt  = 5'd0;
    temp_cl         = 256'd0;

    if ((tail_ptr == 5'd0) && (eip_lower_bits != 4'd0)) begin /* Jumping to unaligned EIP case... */
        temp_cl = {128'd0, (cl >> (eip_lower_bits * 8))};
        wr_cl_byte_cnt = (5'd16 - {1'b0, eip_lower_bits});
    end
    else begin /* Regular case...load the full I$ line into the fetch buffer */
        temp_cl = ({128'd0, cl} << (tail_ptr * 8));
        wr_cl_byte_cnt = 5'd16;
    end

    cl_aligned = temp_cl[247:0];
end

endmodule