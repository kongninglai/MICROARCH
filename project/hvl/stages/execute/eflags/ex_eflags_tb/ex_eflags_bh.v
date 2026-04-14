module ex_eflags_bh(
    input clk,
    input rst_n,

    input [31:0] alu_eflags,
    input [31:0] shf_eflags,
    input [31:0] bsf_eflags,
    input [31:0] aaa_eflags,
    input [31:0] cmp_eflags,
    input [31:0] alu_eflags_mask,
    input [31:0] shf_eflags_mask,
    input [31:0] bsf_eflags_mask,
    input [31:0] aaa_eflags_mask,
    input [31:0] cmp_eflags_mask,
    input [31:0] LR,
    input [2:0]  sig_eflags_mux,
    input        ldEFLAGS,

    output [31:0] eflags
); 
    reg [31:0] eflags_in, eflags_reg;
    assign eflags = eflags_reg;
    
    always @(*) begin 
        case (sig_eflags_mux)
            3'b000: eflags_in = ((~alu_eflags_mask) & eflags_reg) | (alu_eflags_mask & alu_eflags);
            3'b001: eflags_in = ((~shf_eflags_mask) & eflags_reg) | (shf_eflags_mask & shf_eflags);
            3'b010: eflags_in = ((~bsf_eflags_mask) & eflags_reg) | (bsf_eflags_mask & bsf_eflags);
            3'b011: eflags_in = ((~aaa_eflags_mask) & eflags_reg) | (aaa_eflags_mask & aaa_eflags);
            3'b100: eflags_in = ((~cmp_eflags_mask) & eflags_reg) | (cmp_eflags_mask & cmp_eflags);
            3'b101: eflags_in = {eflags_reg[31:11], 1'b0, eflags_reg[9:0]};
            3'b110: eflags_in = {eflags_reg[31:11], 1'b1, eflags_reg[9:0]};
            3'b111: eflags_in = LR;
        endcase
    end

    always @(posedge clk) begin 
        if (~rst_n) begin
            eflags_reg <= 32'h0;
        end else begin
            if (ldEFLAGS) eflags_reg <= eflags_in;
        end
    end
endmodule