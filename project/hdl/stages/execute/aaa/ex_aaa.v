module ex_aaa(
    input [31:0] eax,
    input eflags_af,
    output [31:0] aaa_out,
    output [31:0] aaa_eflags,
    output [31:0] aaa_eflags_mask
);
    wire [7:0] al, ah;
    assign al = eax[7:0];
    assign ah = eax[15:8];

    wire [7:0] al_add_6, ah_inc_1;
    PA_8b PA_al_add_6(.in0(al), .in1(8'h6), .s(al_add_6));
    big_increment #(.WIDTH(8)) inc_ah(.a(ah), .s(ah_inc_1));

    wire al_gt_9, adjust_al;
    gt9_4b gp_al(.in(al[3:0]), .gt(al_gt_9));

    or2$ gt_9_or_af(adjust_al, al_gt_9, eflags_af);

    mux2_32 mux_aaa_out(aaa_out, {eax[31:8], 4'b0, al[3:0]}, {eax[31:16], ah_inc_1, 4'b0, al_add_6[3:0]}, adjust_al);

    // EFLAGS
    wire AF, CF;
    mux2$ mux_af(AF, 1'b0, 1'b1, adjust_al);
    mux2$ mux_cf(CF, 1'b0, 1'b1, adjust_al);

    assign aaa_eflags = {
        27'b0,   // [31:5]
        AF,      // [4]
        3'b0,    // [3:1]
        CF       // [0]
    };

    assign aaa_eflags_mask = 32'h011;
endmodule