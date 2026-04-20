module gp_forwarding(
    input           from_wb_gpwr0_idx_bit_2,
    input   [31:0]  from_wb_gpwr0_data,
    input   [1:0]   from_wb_gpwr0_size,
    input           from_wb_gpwr0_en,
    input           from_wb_gpwr1_idx_bit_2,
    input   [31:0]  from_wb_gpwr1_data,
    input   [1:0]   from_wb_gpwr1_size,
    input           from_wb_gpwr1_en,

    input   [31:0]  srcreg,
    input   [1:0]   fw_mux,

    output  [31:0]  f_reg
);
    wire [31:0] f_dstA_size8, f_dstA, f_dstB_size8, f_dstB, f_dstAB;
    mux2_32 mux2_f_dstA_size8(f_dstA_size8, {srcreg[31:8], from_wb_gpwr0_data[7:0]}, {srcreg[31:16], from_wb_gpwr0_data[7:0], srcreg[7:0]}, from_wb_gpwr0_idx_bit_2);
    mux4_32 mux4_f_dstA(f_dstA,
                        f_dstA_size8,
                        {srcreg[31:16], from_wb_gpwr0_data[15:0]},
                        from_wb_gpwr0_data, from_wb_gpwr0_data,
                        from_wb_gpwr0_size[0], from_wb_gpwr0_size[1]);
    
    mux2_32 mux2_f_dstB_size8(f_dstB_size8, {srcreg[31:8], from_wb_gpwr1_data[7:0]}, {srcreg[31:16], from_wb_gpwr1_data[7:0], srcreg[7:0]}, from_wb_gpwr1_idx_bit_2);
    mux4_32 mux4_f_dstB(f_dstB,
                        f_dstB_size8,
                        {srcreg[31:16], from_wb_gpwr1_data[15:0]},
                        from_wb_gpwr1_data, from_wb_gpwr1_data,
                        from_wb_gpwr1_size[0], from_wb_gpwr1_size[1]);

    mux2_32 mux2_f_dstAB(f_dstAB, 
                        {srcreg[31:16], from_wb_gpwr1_data[7:0], from_wb_gpwr0_data[7:0]},
                        {srcreg[31:16], from_wb_gpwr0_data[7:0], from_wb_gpwr1_data[7:0]},
                        from_wb_gpwr0_idx_bit_2);
    wire fw_mux_1_en, fw_mux_0_en;
    and2$ and2_fw_mux_1_en(fw_mux_1_en, fw_mux[1], from_wb_gpwr1_en);
    and2$ and2_fw_mux_0_en(fw_mux_0_en, fw_mux[0], from_wb_gpwr0_en);

    mux4_32 mux4_f_reg(f_reg, srcreg, f_dstA, f_dstB, f_dstAB, fw_mux_0_en, fw_mux_1_en);

endmodule