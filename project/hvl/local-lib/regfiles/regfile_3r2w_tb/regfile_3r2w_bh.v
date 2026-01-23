module regfile_3r2w_bh #(
    parameter WIDTH=32,
    parameter DEPTH=8,
    parameter IDX_SIZE=3
)(
    input clk,
    input rst_n,

    input [IDX_SIZE-1:0] rd_reg0_idx,
    input [IDX_SIZE-1:0] rd_reg1_idx,
    input [IDX_SIZE-1:0] rd_reg2_idx,
    output [WIDTH-1:0] rd_reg0_data,
    output [WIDTH-1:0] rd_reg1_data,
    output [WIDTH-1:0] rd_reg2_data,

    input [IDX_SIZE-1:0] wr_reg0_idx,
    input [WIDTH-1:0] wr_reg0_data,
    input wr0_en,

    input [IDX_SIZE-1:0] wr_reg1_idx,
    input [WIDTH-1:0] wr_reg1_data,
    input wr1_en
); 

    reg [WIDTH-1:0] registers [0:DEPTH-1];

    assign rd_reg0_data = (wr0_en && (wr_reg0_idx == rd_reg0_idx)) ? wr_reg0_data : ((wr1_en && (wr_reg1_idx == rd_reg0_idx)) ? wr_reg1_data : registers[rd_reg0_idx]);
    assign rd_reg1_data = (wr0_en && (wr_reg0_idx == rd_reg1_idx)) ? wr_reg0_data : ((wr1_en && (wr_reg1_idx == rd_reg1_idx)) ? wr_reg1_data : registers[rd_reg1_idx]);
    assign rd_reg2_data = (wr0_en && (wr_reg0_idx == rd_reg2_idx)) ? wr_reg0_data : ((wr1_en && (wr_reg1_idx == rd_reg2_idx)) ? wr_reg1_data : registers[rd_reg2_idx]);

    integer i;
    always @(posedge clk) begin 
        if (~rst_n) begin
            for (i = 0; i < DEPTH; i=i+1) begin 
                registers[i] <= 'b0;
            end
        end else begin
            if (wr0_en) registers[wr_reg0_idx] <= wr_reg0_data;
            if (wr1_en && !(wr0_en && (wr_reg0_idx==wr_reg1_idx))) registers[wr_reg1_idx] <= wr_reg1_data;
        end
    end


endmodule