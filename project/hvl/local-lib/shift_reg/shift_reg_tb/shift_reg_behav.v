module shift_reg_behav(
    input clk,
    input rst_n,
    input shift,
    input [3:0] instr_len,
    input [247:0] inbytes, 
    input [30:0] wr_en,
    output [127:0] outbytes,
    output ready
);
    reg [7:0] buffer [30:0];
    integer i;

    // Concatenate the first 16 bytes for output
    assign outbytes = {buffer[15], buffer[14], buffer[13], buffer[12], 
                       buffer[11], buffer[10], buffer[9],  buffer[8], 
                       buffer[7],  buffer[6],  buffer[5],  buffer[4], 
                       buffer[3],  buffer[2],  buffer[1],  buffer[0]};
    assign ready = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 31; i = i + 1) buffer[i] <= 8'h0;
        end else begin
            for (i = 0; i < 31; i = i + 1) begin
                if (shift) begin
                    if (i + instr_len < 31) begin
                        // Shift in data (either from existing buffer or new inbytes)
                        if (wr_en[i + instr_len])
                            buffer[i] <= inbytes[(i + instr_len)*8 +: 8];
                        else
                            buffer[i] <= buffer[i + instr_len];
                    end else begin
                        // NEW: Explicitly zero-fill bytes that are "shifted in" from the left
                        buffer[i] <= 8'h0;
                    end
                end else if (wr_en[i]) begin
                    buffer[i] <= inbytes[i*8 +: 8];
                end
            end
        end
    end
endmodule