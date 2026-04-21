/*
 * alu_op: ADD(000), OR(001), ADC(010), SBB(011), AND(100)
 * 
*/
module ex_alu(
    input [2:0] alu_op,
    input [1:0] ds, // 00 for 8-bit, 01 for 16-bit, 10 for 32-bit, 11 undefined
    input [31:0] in0,
    input [31:0] in1,
    input eflags_cf,
    input sbb_dir,
    output [31:0] alu_out,
    output [31:0] alu_eflags,
    output [31:0] alu_eflags_mask
); 
    // ADD 
    wire [31:0] add_out, add_cout;
    HA_32b HA32_ADD(.in0(in0), .in1(in1), .s(add_out), .cout(add_cout));

    // ADC
    wire [31:0] adc_out, adc_cout;
    FA_32b FA32_ADC(.in0(in0), .in1(in1), .cin(eflags_cf), .s(adc_out), .cout(adc_cout));

    // SBB
    wire [31:0] sbb_out, sbb_cout;
    wire [31:0] sbb_in0, sbb_in1;
    mux2_32 mux2_sbb_in0(sbb_in0, in0, in1, sbb_dir);
    mux2_32 mux2_sbb_in1(sbb_in1, in1, in0, sbb_dir);
    SUB_32b SUB32_SBB(.in0(sbb_in0), .in1(sbb_in1), .cin(eflags_cf), .s(sbb_out), .cout(sbb_cout));

    // OR
    wire [31:0] or_out;
    or2$ or32[31:0](or_out, in0, in1);

    // AND
    wire [31:0] and_out;
    and2$ and32[31:0](and_out, in0, in1);

    // buffer_alu_op
    wire [2:0] buffered_alu_op;
    bufferH64$ buffer64_alu_op[2:0](buffered_alu_op, alu_op);

    // ALU OUT MUX
    wire [31:0] alu_mux_out, alu_mux_out_buf16, alu_mux_cout, alu_mux_cout_buf16;
    bufferH16$  bufferH16$_alu_mux_out_buf16[31:0](alu_mux_out_buf16, alu_mux_out);
    bufferH16$  bufferH16$_alu_mux_cout_buf16[31:0](alu_mux_cout_buf16, alu_mux_cout);
    mux8_32 mux8_aluout(alu_mux_out, add_out, or_out, adc_out, sbb_out, and_out, , , , buffered_alu_op[0], buffered_alu_op[1], buffered_alu_op[2]);
    mux8_32 mux8_alucout(alu_mux_cout, add_cout, 32'b0, adc_cout, sbb_cout, 32'b0, , , , buffered_alu_op[0], buffered_alu_op[1], buffered_alu_op[2]);
    assign alu_out = alu_mux_out_buf16;

    // EFLAGS
    wire OF8, OF16, OF32, OF;
    wire SF8, SF16, SF32, SF;
    wire ZF8, ZF16, ZF32, ZF;
    wire AF8, AF16, AF32, AF;
    wire CF8, CF16, CF32, CF;
    wire PF8, PF16, PF32, PF;

    alu_eflags #(.WIDTH(8)) alu_eflags8(in0, in1, alu_mux_out_buf16, alu_mux_cout_buf16, buffered_alu_op,
                                        OF8,
                                        SF8,
                                        ZF8,
                                        AF8,
                                        CF8,
                                        PF8);

    alu_eflags #(.WIDTH(16)) alu_eflags16(in0, in1, alu_mux_out_buf16, alu_mux_cout_buf16, buffered_alu_op,
                                        OF16,
                                        SF16,
                                        ZF16,
                                        AF16,
                                        CF16,
                                        PF16);

    alu_eflags #(.WIDTH(32)) alu_eflags32(in0, in1, alu_mux_out_buf16, alu_mux_cout_buf16, buffered_alu_op,
                                        OF32,
                                        SF32,
                                        ZF32,
                                        AF32,
                                        CF32,
                                        PF32);
    wire [1:0] buffered_ds;
    bufferH16$ buffer16_ds[1:0](buffered_ds, ds);                                  
    mux4$ mux4_OF(OF, OF8, OF16, OF32, , buffered_ds[0], buffered_ds[1]);
    mux4$ mux4_SF(SF, SF8, SF16, SF32, , buffered_ds[0], buffered_ds[1]);
    mux4$ mux4_ZF(ZF, ZF8, ZF16, ZF32, , buffered_ds[0], buffered_ds[1]);
    mux4$ mux4_AF(AF, AF8, AF16, AF32, , buffered_ds[0], buffered_ds[1]);
    mux4$ mux4_CF(CF, CF8, CF16, CF32, , buffered_ds[0], buffered_ds[1]);
    mux4$ mux4_PF(PF, PF8, PF16, PF32, , buffered_ds[0], buffered_ds[1]);

    assign alu_eflags = {
        20'b0,   // [31:12]
        OF,      // [11]
        3'b0,    // [10:8]
        SF,      // [7]
        ZF,      // [6]
        1'b0,    // [5]
        AF,      // [4]
        1'b0,    // [3]
        PF,      // [2]
        1'b0,    // [1]
        CF       // [0]
    };

    mux8_32 mux8_alu_eflags_mux(alu_eflags_mask, 32'h08D5, 32'h08C5, 32'h08D5, 32'h08D5, 32'h08C5, , , , buffered_alu_op[0], buffered_alu_op[1], buffered_alu_op[2]);
    
endmodule