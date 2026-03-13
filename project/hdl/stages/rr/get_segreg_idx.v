module get_segreg_idx(
    output [2:0] seg_idx,
    input [2:0] base_reg_idx,
    input [2:0] seg_override
);
    // base_reg_idx == 100/101 => seg_idx = 010 (SS)
    // otherwise seg_idx = seg_override
    wire base2_inv, use_ss;
    inv1$ inv_base2(base2_inv, base_reg_idx[2]);
    nor2$ nor2_use_ss(use_ss, base2_inv, base_reg_idx[1]);

    mux2$ mux2_seg_idx[2:0](seg_idx, seg_override, 3'b010, use_ss);
endmodule