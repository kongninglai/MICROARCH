module shift_reg(
    input clk,
    input rst_n,
    input shift,
    input [3:0] instr_len,
    input gate,
    input [247:0] inbytes,
    input [30:0] wr_en,
    output [127:0] outbytes,
    output ready
); 
    wire [7:0] inbytes_i[30:0];
    wire [7:0] q[30:0];

    wire [7:0] d[30:0];
    wire [7:0] d_instr_len[30:0];
    wire [7:0] d_no_inst_len[30:0];
    wire [30:0] en, en_buf16;
    bufferH16$  bufferH16$_en_buf16[30:0](en_buf16, en);

    genvar i;
    generate 
        for (i = 0; i < 31; i=i+1) begin : inbytes_rearrangement_gen
            assign inbytes_i[i] = inbytes[i*8+7:i*8];
        end
    endgenerate

    wire [7:0] updated_q[45:0];
    wire [7:0] updated_q_buf16[45:0];

    generate
      for (i = 0; i <= 45; i = i + 1) begin : updated_q_buffering
        bufferH16$    bufferH16$_updated_q_buf16[7:0](updated_q_buf16[i], updated_q[i]);
      end
    endgenerate

    generate
        for (i = 31; i <= 45; i = i + 1) begin : DUMMY_UPDATED_Q_GEN
            assign updated_q[i] = 8'h00;
        end
    endgenerate

    wire [3:0] update_idx, update_idx_buf256, update_idx_dummy;
    buffer$ buffer$_update_idx[3:0](update_idx, instr_len);
    // mux2_8$ mux_update_idx({update_idx_dummy, update_idx}, 8'd0, {4'd0, instr_len}, shift);
    bufferH256$   bufferH256$_update_idx_buf256[3:0](update_idx_buf256, update_idx);

    generate 
        for (i = 0; i < 31; i=i+1) begin : shifted_input_gen
            wire not_shift, not_shift_and_wr_bar;
            mux2_8$ mux2_8_update(updated_q[i], q[i], inbytes_i[i], wr_en[i]);
    
            mux16_8b mux16_8b_shift(d_instr_len[i], updated_q_buf16[i],     updated_q_buf16[i+1],   updated_q_buf16[i+2],   updated_q_buf16[i+3], 
                                          updated_q_buf16[i+4],   updated_q_buf16[i+5],   updated_q_buf16[i+6],   updated_q_buf16[i+7], 
                                          updated_q_buf16[i+8],   updated_q_buf16[i+9],   updated_q_buf16[i+10],  updated_q_buf16[i+11], 
                                          updated_q_buf16[i+12],  updated_q_buf16[i+13],  updated_q_buf16[i+14],  updated_q_buf16[i+15], 
                                          update_idx_buf256[0], update_idx_buf256[1], update_idx_buf256[2], update_idx_buf256[3]);

            assign d_no_inst_len[i] = updated_q[i];
            mux2_8$ mux2_8$_gate(d[i], d_no_inst_len[i], d_instr_len[i], gate);

            inv1$ inv_shift(not_shift, shift);
            nand2$ nand_not_shift_and_wr_bar(not_shift_and_wr_bar, not_shift, wr_en[i]);

            nand2$ nand_en(en[i], not_shift, not_shift_and_wr_bar);
            reg_n #(
                .WIDTH(8),
                .USE_EN_BAR(0)
            ) reg_n_disk_addr (
                .clk(clk), .rst(rst_n),
                .en({8{en_buf16[i]}}), .d(d[i]),
                .q(q[i])
            );
        end
    endgenerate
    
    assign outbytes = {q[15], q[14], q[13], q[12], q[11], q[10], q[9], q[8], q[7], q[6], q[5], q[4], q[3], q[2], q[1], q[0]};
    assign ready = 1'b1;
endmodule