module shift_reg(
    input clk,
    input rst_n,
    input shift,
    input [3:0] instr_len,
    input [247:0] inbytes,
    input [30:0] wr_en,
    output [127:0] outbytes,
    output ready
); 
    wire [7:0] inbytes_i[30:0];
    wire [7:0] q[30:0];

    wire [7:0] d[30:0];
    wire [30:0] en;

    genvar i;
    generate 
        for (i = 0; i < 31; i=i+1) begin 
            assign inbytes_i[i] = inbytes[i*8+7:i*8];
        end
    endgenerate

    wire [7:0] updated_q[45:0];

    generate
        for (i = 31; i <= 45; i = i + 1) begin : DUMMY_UPDATED_Q_GEN
            assign updated_q[i] = 8'h00;
        end
    endgenerate

    wire debug_en;
    wire [7:0] debug_d, debug_q, debug_inbytes;
    assign debug_en = en[1];
    assign debug_d = d[1];
    assign debug_q = q[1];
    assign debug_inbytes = inbytes_i[1];
    generate 
        for (i = 0; i < 31; i=i+1) begin
            localparam [4:0] i_31 = 5'd30 - i;
            wire [3:0] update_idx;
            wire le, shift_en, not_shift, not_shift_and_wr;
            mux2$ mux2_update[7:0](updated_q[i], q[i], inbytes_i[i], wr_en[i]);
    
            mux2$ mux_update_idx[3:0](update_idx, 4'b0, instr_len, shift);
            mux16 mux16_shift[7:0](d[i], updated_q[i], updated_q[i+1], updated_q[i+2], updated_q[i+3], 
                                        updated_q[i+4], updated_q[i+5], updated_q[i+6], updated_q[i+7], 
                                        updated_q[i+8], updated_q[i+9], updated_q[i+10], updated_q[i+11], 
                                        updated_q[i+12], updated_q[i+13], updated_q[i+14], updated_q[i+15], 
                                        update_idx[0], update_idx[1], update_idx[2], update_idx[3]);
            // en[i] = (shift & instr_len < 32-i) | (~shift & wr_en[i])
            le_5b le5_instrlen(le, {1'b0, instr_len}, i_31);
            and2$ and_shift_en(shift_en, le, shift);
            inv1$ inv_shift(not_shift, shift);
            and2$ and_not_shift_and_wr(not_shift_and_wr, not_shift, wr_en[i]);

            wire rst;
            inv1$ inv_debug_en(rst, rst_n);
            or3$ or_en(en[i], shift_en, not_shift_and_wr, rst);
            reg_n #(
                .WIDTH(8),
                .USE_EN_BAR(0)
            ) reg_n_disk_addr (
                .clk(clk), .rst(rst_n),
                .en({8{en[i]}}), .d(d[i]),
                .q(q[i])
            );
        end
    endgenerate
    
    assign outbytes = {q[15], q[14], q[13], q[12], q[11], q[10], q[9], q[8], q[7], q[6], q[5], q[4], q[3], q[2], q[1], q[0]};
    assign ready = 1'b1;
endmodule