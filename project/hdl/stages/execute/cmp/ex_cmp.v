module ex_cmp(
    input [1:0]     ds, // 00 for 8-bit, 01 for 16-bit, 10 for 32-bit, 11 undefined
    input [31:0]    in0, // in0 - in1
    input [31:0]     in1,

    output [31:0] cmp_eflags,
    output [31:0] cmp_eflags_mask
); 
    
    wire [31:0] sbb_out, sbb_out_buf16, sbb_cout;
    SUB_32b SUB32_SBB(.in0(in0), .in1(in1), .cin(1'b0), .s(sbb_out), .cout(sbb_cout));
    bufferH16$  bufferH16$_sbb_out_buf16[31:0](sbb_out_buf16, sbb_out);

    // TODO: EFLAGS
    // EFLAGS
    wire OF8, OF16, OF32, OF;
    wire SF8, SF16, SF32, SF;
    wire ZF8, ZF16, ZF32, ZF;
    wire AF8, AF16, AF32, AF;
    wire CF8, CF16, CF32, CF;
    wire PF8, PF16, PF32, PF;

    cmp_eflags #(.WIDTH(8)) cmp_eflags8(in0, in1, sbb_out_buf16, sbb_cout,
                                        OF8,
                                        SF8,
                                        ZF8,
                                        AF8,
                                        CF8,
                                        PF8);

    cmp_eflags #(.WIDTH(16)) cmp_eflags16(in0, in1, sbb_out_buf16, sbb_cout,
                                        OF16,
                                        SF16,
                                        ZF16,
                                        AF16,
                                        CF16,
                                        PF16);

    cmp_eflags #(.WIDTH(32)) cmp_eflags32(in0, in1, sbb_out_buf16, sbb_cout,
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

    assign cmp_eflags = {
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

    assign cmp_eflags_mask = 32'h08D5;
endmodule