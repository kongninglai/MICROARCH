module dummy_fe(
    input clk,
    input rst_n,

    input [127:0] to_de_outbytes,
    input         to_de_valid,

    input         from_rr_stall,

    output [5:0]  from_de_prefix,
    output [7:0]  from_de_opcode,
    output [7:0]  from_de_modrm,
    output [7:0]  from_de_sib,
    output [31:0] from_de_disp,
    output [1:0]  from_de_dispsize,
    output [47:0] from_de_imm,
    output [2:0]  from_de_imm_size,
    output [1:0]  from_de_addr_mode,
    output [31:0] from_de_oeip,
    output [31:0] from_de_ieip,
    output [31:0] from_de_pred_eip,
    output [1:0]  from_de_exception,
    output        from_de_valid
); 
    wire prefix_rep, prefix_op_size, prefix_ext;
    wire [2:0] prefix_seg_ov_id;
    wire [3:0] instr_len;

    block_decoder block_decoder_inst (
        .cache_line(to_de_outbytes),
        .prefix_rep(prefix_rep),
        .prefix_op_size(prefix_op_size),
        .prefix_seg_ov_id(prefix_seg_ov_id),
        .prefix_ext(prefix_ext),
        .opcode(from_de_opcode),
        .modrm_v(),
        .modrm(from_de_modrm),
        .sib(from_de_sib),
        .disp_size_mux(from_de_dispsize),
        .disp(from_de_disp),
        .imm_size(),
        .imm(from_de_imm),
        .addressing_mode(from_de_addr_mode),
        .instr_length(instr_len)
    );

    assign from_de_prefix = {prefix_rep, prefix_op_size, prefix_seg_ov_id, prefix_ext};
    assign from_de_imm_size = 3'd0;

    reg [31:0] EIP;
    always @(posedge clk) begin
        if (!rst_n) begin 
            EIP <= 32'b0;
        end else if (from_de_valid & ~from_rr_stall) begin 
            EIP <= EIP + instr_len;
        end
    end

    assign from_de_oeip = EIP;
    assign from_de_ieip = EIP + instr_len;
    assign from_de_pred = EIP + instr_len;
    assign from_de_exception = 2'b0;
    assign #(3) from_de_valid = to_de_valid;

endmodule

module dummy_fe_to_be(
    input clk,
    input rst_n,

    input from_rr_stall,

    input [5:0]  from_de_prefix,
    input [7:0]  from_de_opcode,
    input [7:0]  from_de_modrm,
    input [7:0]  from_de_sib,
    input [31:0] from_de_disp,
    input [1:0]  from_de_dispsize,
    input [47:0] from_de_imm,
    input [2:0]  from_de_imm_size,
    input [1:0]  from_de_addr_mode,
    input [31:0] from_de_oeip,
    input [31:0] from_de_ieip,
    input [31:0] from_de_pred_eip,
    input [1:0]  from_de_exception,
    input        from_de_valid,

    output reg [5:0]  to_rr_prefix,
    output reg [7:0]  to_rr_opcode,
    output reg [7:0]  to_rr_modrm,
    output reg [7:0]  to_rr_sib,
    output reg [31:0] to_rr_disp,
    output reg [1:0]  to_rr_dispsize,
    output reg [47:0] to_rr_imm,
    output reg [2:0]  to_rr_imm_size,
    output reg [1:0]  to_rr_addr_mode,
    output reg [31:0] to_rr_oeip,
    output reg [31:0] to_rr_ieip,
    output reg [31:0] to_rr_pred_eip,
    output reg [1:0]  to_rr_exception,
    output reg        to_rr_valid
);

    always @(posedge clk) begin
        if (!rst_n) begin
            to_rr_prefix    <= 6'b0;
            to_rr_opcode    <= 8'b0;
            to_rr_modrm     <= 8'b0;
            to_rr_sib       <= 8'b0;
            to_rr_disp      <= 32'b0;
            to_rr_dispsize  <= 2'b0;
            to_rr_imm       <= 48'b0;
            to_rr_imm_size  <= 3'b0;
            to_rr_addr_mode <= 2'b0;
            to_rr_oeip      <= 32'b0;
            to_rr_ieip      <= 32'b0;
            to_rr_pred_eip  <= 32'b0;
            to_rr_exception <= 2'b0;
            to_rr_valid     <= 1'b0;
        end else if (~from_rr_stall) begin 
            to_rr_prefix    <= from_de_prefix;   
            to_rr_opcode    <= from_de_opcode;  
            to_rr_modrm     <= from_de_modrm;    
            to_rr_sib       <= from_de_sib;      
            to_rr_disp      <= from_de_disp;     
            to_rr_dispsize  <= from_de_dispsize;
            to_rr_imm       <= from_de_imm;      
            to_rr_imm_size  <= from_de_imm_size; 
            to_rr_addr_mode <= from_de_addr_mode;
            to_rr_oeip      <= from_de_oeip;   
            to_rr_ieip      <= from_de_ieip;     
            to_rr_pred_eip  <= from_de_pred_eip;
            to_rr_exception <= from_de_exception;
            to_rr_valid     <= from_de_valid;    
        end
    end
endmodule