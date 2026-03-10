module regfile_gp_bh (
    input clk,
    input rst_n,

    input [2:0] rd_reg0_idx,
    input [2:0] rd_reg1_idx,
    input [2:0] rd_reg2_idx,
    input [2:0] rd_reg3_idx,

    input [1:0] rd_reg0_ds,
    input [1:0] rd_reg1_ds,
    input [1:0] rd_reg2_ds,
    input [1:0] rd_reg3_ds,

    output [31:0] rd_reg0_data,
    output [31:0] rd_reg1_data,
    output [31:0] rd_reg2_data,
    output [31:0] rd_reg3_data,

    input [2:0] wr_reg0_idx,
    input [31:0] wr_reg0_data,
    input [1:0] wr_reg0_ds, // 00(8-bit), 01(16-bit), 10(32-bit), 11(64-bit/UNUSED)
    input wr0_en,

    input [2:0] wr_reg1_idx,
    input [31:0] wr_reg1_data,
    input [1:0] wr_reg1_ds,
    input wr1_en
); 


    reg [31:0] registers [0:7];

    wire [2:0] wr0_pidx, wr1_pidx;
    reg [31:0] wr0_wrdata, wr1_wrdata;
    assign wr0_pidx = (wr_reg0_ds==2'b00) ? {1'b0, wr_reg0_idx[1:0]} : wr_reg0_idx;
    assign wr1_pidx = (wr_reg1_ds==2'b00) ? {1'b0, wr_reg1_idx[1:0]} : wr_reg1_idx;

    // low  8-bit:  wr_data = {registers[wr0_pidx][31:8], wr_reg0_data[7:0]};
    // high 8-bit:  wr_data = {registers[wr0_pidx][31:16], wr_reg0_data[7:0], registers[wr0_pidx][7:0]};
    // low 16-bit:  wr_data = {registers[wr0_pidx][31:16], wr_reg0_data[15:0]};
    // full 32-bit: wr_data = wr_reg0_data;

    always @(*) begin 
        case (wr_reg0_ds) 
            2'b00: wr0_wrdata = wr_reg0_idx[2] ? {registers[wr0_pidx][31:16], wr_reg0_data[7:0], registers[wr0_pidx][7:0]} : {registers[wr0_pidx][31:8], wr_reg0_data[7:0]};
            2'b01: wr0_wrdata = {registers[wr0_pidx][31:16], wr_reg0_data[15:0]};
            2'b10: wr0_wrdata = wr_reg0_data;
            2'b11: wr0_wrdata = wr_reg0_data;
            default: wr0_wrdata = wr_reg0_data;
        endcase

        case (wr_reg1_ds) 
            2'b00: wr1_wrdata = wr_reg1_idx[2] ? {registers[wr1_pidx][31:16], wr_reg1_data[7:0], registers[wr1_pidx][7:0]} : {registers[wr1_pidx][31:8], wr_reg1_data[7:0]};
            2'b01: wr1_wrdata = {registers[wr1_pidx][31:16], wr_reg1_data[15:0]};
            2'b10: wr1_wrdata = wr_reg1_data;
            2'b11: wr1_wrdata = wr_reg1_data;
            default: wr1_wrdata = wr_reg1_data;
        endcase
    end
    
    wire write_same_low_high;
    assign write_same_low_high = (wr_reg0_ds==2'b00) & (wr_reg1_ds==2'b00) & wr0_en & wr1_en & (wr_reg0_idx[2] ^ wr_reg1_idx[2]) & (wr_reg0_idx[1:0] == wr_reg1_idx[1:0]);
    wire [31:0] wr0_wrdata_merged01, wr0_wrdata_merged10, wr0_wrdata_merged;
    assign wr0_wrdata_merged01 = {registers[wr0_pidx][31:16], wr_reg0_data[7:0], wr_reg1_data[7:0]};
    assign wr0_wrdata_merged10 = {registers[wr0_pidx][31:16], wr_reg1_data[7:0], wr_reg0_data[7:0]};
    assign  wr0_wrdata_merged = write_same_low_high ? (wr_reg0_idx[2] ? wr0_wrdata_merged01 : wr0_wrdata_merged10) : wr0_wrdata;

    integer i;
    always @(posedge clk) begin 
        if (~rst_n) begin
            for (i = 0; i < 8; i=i+1) begin 
                registers[i] <= 'b0;
            end
        end else begin
            // case 1: write 0 & 1 are completely different registers: write both
            // case 2: write 0 & 1 same index, only write 0 (use write 0 data)
            // case 3: write 0 & 1 low/high 8-bit of same registers, write 0 (use merged 0 & 1 data)
            // so only write 1 when wr0_pidx != wr1_pidx
            if (wr0_en) registers[wr0_pidx] <= wr0_wrdata_merged;
            if (wr1_en && !(wr0_en & (wr0_pidx==wr1_pidx))) registers[wr1_pidx] <= wr1_wrdata;
        end
    end

    wire [2:0] rd0_pidx, rd1_pidx, rd2_pidx, rd3_pidx;
    assign rd0_pidx = (rd_reg0_ds==2'b00) ? {1'b0, rd_reg0_idx[1:0]} : rd_reg0_idx;
    assign rd1_pidx = (rd_reg1_ds==2'b00) ? {1'b0, rd_reg1_idx[1:0]} : rd_reg1_idx;
    assign rd2_pidx = (rd_reg2_ds==2'b00) ? {1'b0, rd_reg2_idx[1:0]} : rd_reg2_idx;
    assign rd3_pidx = (rd_reg3_ds==2'b00) ? {1'b0, rd_reg3_idx[1:0]} : rd_reg3_idx;

    wire [31:0] rd0_data, rd1_data, rd2_data, rd3_data;
    assign rd0_data = (wr0_en && (wr0_pidx == rd0_pidx)) ? wr0_wrdata_merged : ((wr1_en && (wr1_pidx == rd0_pidx)) ? wr1_wrdata : registers[rd0_pidx]);
    assign rd1_data = (wr0_en && (wr0_pidx == rd1_pidx)) ? wr0_wrdata_merged : ((wr1_en && (wr1_pidx == rd1_pidx)) ? wr1_wrdata : registers[rd1_pidx]);
    assign rd2_data = (wr0_en && (wr0_pidx == rd2_pidx)) ? wr0_wrdata_merged : ((wr1_en && (wr1_pidx == rd2_pidx)) ? wr1_wrdata : registers[rd2_pidx]);
    assign rd3_data = (wr0_en && (wr0_pidx == rd3_pidx)) ? wr0_wrdata_merged : ((wr1_en && (wr1_pidx == rd3_pidx)) ? wr1_wrdata : registers[rd3_pidx]);

    function automatic [31:0] extract_read_data;
            input [1:0] datasize;
            input [2:0] read_idx;
            input [31:0] read_data;

            case (datasize) 
                2'b00: extract_read_data = read_idx[2] ? {24'b0, read_data[15:8]} : {24'b0, read_data[7:0]};
                2'b01: extract_read_data = {16'b0, read_data[15:0]};
                2'b10: extract_read_data = read_data;
                2'b11: extract_read_data = read_data;
                default: extract_read_data = read_data;
            endcase

    endfunction
    
    assign rd_reg0_data = extract_read_data(rd_reg0_ds, rd_reg0_idx, rd0_data);
    assign rd_reg1_data = extract_read_data(rd_reg1_ds, rd_reg1_idx, rd1_data);
    assign rd_reg2_data = extract_read_data(rd_reg2_ds, rd_reg2_idx, rd2_data);
    assign rd_reg3_data = extract_read_data(rd_reg3_ds, rd_reg3_idx, rd3_data);

endmodule
