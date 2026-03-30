module regfile_seg_bh (  
    input clk,
    input rst_n,

    input [2:0] segrd0_idx,
    input [2:0] segrd1_idx,
    output [15:0] segrd0_data,
    output [15:0] segrd1_data,
    output [19:0] segrd0_limit,
    output [19:0] segrd1_limit,
    output [15:0] cs,
    output [19:0] cs_limit,
    input [2:0] segwr_idx,
    input [15:0] segwr_data,
    input segwr_en,

    input cs_wr_en,
    input [15:0] cs_wr_data
); 
    reg [15:0] registers [0:7];

    reg [15:0] reg_cs;

    assign cs = reg_cs;

    wire [15:0] segrd0_with_cs, segrd1_with_cs;
    assign segrd0_with_cs = (segrd0_idx == 3'd1) ? reg_cs : registers[segrd0_idx];
    assign segrd1_with_cs = (segrd1_idx == 3'd1) ? reg_cs : registers[segrd1_idx];

    assign segrd0_data = (segwr_en && (segwr_idx == segrd0_idx)) ? segwr_data : segrd0_with_cs;
    assign segrd1_data = (segwr_en && (segwr_idx == segrd1_idx)) ? segwr_data : segrd1_with_cs;

    integer i;
    always @(posedge clk) begin 
        if (~rst_n) begin
            for (i = 0; i < 8; i=i+1) begin 
                registers[i] <= 'b0;
            end
        end else begin
            if (segwr_en) registers[segwr_idx] <= segwr_data;
        end
    end

    always @(posedge clk) begin 
        if (~rst_n) begin
            reg_cs <='b0;
        end else begin
            if (cs_wr_en) reg_cs <= cs_wr_data;
        end
    end

    reg [19:0] slim0, slim1;

    always @(*) begin 
        case (segrd0_idx) 
            3'b000: slim0 = 20'h003ff;
            3'b001: slim0 = 20'h04fff;
            3'b010: slim0 = 20'h04000;
            3'b011: slim0 = 20'h011ff;
            3'b100: slim0 = 20'h003ff;
            3'b101: slim0 = 20'h007ff;
            3'b110: slim0 = 20'bx;
            3'b111: slim0 = 20'bx;
            default: slim0 = 20'bx;
        endcase     
        case (segrd1_idx) 
            3'b000: slim1 = 20'h003ff;
            3'b001: slim1 = 20'h04fff;
            3'b010: slim1 = 20'h04000;
            3'b011: slim1 = 20'h011ff;
            3'b100: slim1 = 20'h003ff;
            3'b101: slim1 = 20'h007ff;
            3'b110: slim1 = 20'bx;
            3'b111: slim1 = 20'bx;
            default: slim1 = 20'bx;
        endcase               
    end
    assign segrd0_limit = slim0;
    assign segrd1_limit = slim1;
    assign cs_limit = 20'h04fff;
endmodule