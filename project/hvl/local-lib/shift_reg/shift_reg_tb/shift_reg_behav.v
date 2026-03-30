module shift_reg_behav(
    input                 clk,
    input                 rst_n,
    input                 shift,
    input                 flush,            /* NEW: VR */
    input       [3:0]     instr_len,        /* NEW: VR */
    input       [247:0]   inbytes,
    input                 global_wr_en,     /* NEW: VR */
    input       [4:0]     wr_cl_byte_cnt,   /* NEW: VR */
    input       [30:0]    wr_en,
    output      [127:0]   outbytes,
    output  reg [4:0]     tail_ptr,
    output                ready
); 

    

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tail_ptr <= 5'd0;
        end else begin
            case ({flush, shift, global_wr_en})
              3'b000:
                tail_ptr <= tail_ptr;
              3'b001:
                tail_ptr <= wr_cl_byte_cnt[4] ? {1'b1, tail_ptr[3:0]} : wr_cl_byte_cnt;
              3'b010:
                tail_ptr <= tail_ptr - instr_len;
              3'b011:
                tail_ptr <= (tail_ptr - instr_len) | 5'b10000;
              3'b100:
                tail_ptr <= 5'd0;
              3'b101:
                tail_ptr <= 5'd0;
              3'b110:
                tail_ptr <= 5'd0;
              3'b111:
                tail_ptr <= 5'd0;              
            endcase
        end
    end
    
    reg [7:0] buffer [30:0];
    integer i;

    // Concatenate the first 16 bytes for output
    assign outbytes = {buffer[15], buffer[14], buffer[13], buffer[12], 
                       buffer[11], buffer[10], buffer[9],  buffer[8], 
                       buffer[7],  buffer[6],  buffer[5],  buffer[4], 
                       buffer[3],  buffer[2],  buffer[1],  buffer[0]};
    assign ready = ~(tail_ptr[4]);

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