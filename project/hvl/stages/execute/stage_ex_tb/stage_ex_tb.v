module stage_rr_tb;

    initial begin
        $vcdplusfile("stage_rr_tb.dump.vpd");
        $vcdpluson(0, stage_rr_tb); 
    end

reg clk;
reg rst_n;
reg [51:0] to_ex_control_sigs;
reg [2:0] to_ex_dstidA;
reg [2:0] to_ex_dstidB;
reg [31:0] to_ex_srcregA;
reg [31:0] to_ex_srcregB;
reg [31:0] to_ex_srcregC;
reg [15:0] to_ex_srcSREG;
reg [63:0] to_ex_MMA;
reg [63:0] to_ex_MMB;
reg [15:0] to_ex_target_cs;
reg [63:0] to_ex_load_result;
reg [31:0] to_ex_inc_esp;
reg [31:0] to_ex_dec_esp;
reg [31:0] to_ex_imm;
reg to_ex_store_is_io_line_0;
reg [10:0] to_ex_store_addr_line_0;
reg [15:0] to_ex_store_mask_line_0;
reg to_ex_store_queue_alloc_line_0;
reg [10:0] to_ex_store_addr_line_1;
reg [15:0] to_ex_store_mask_line_1;
reg to_ex_store_queue_alloc_line_1;
reg [4:0] to_ex_store_data_shf_amt;
reg [31:0] to_ex_rel_eip;
reg [15:0] to_ex_cs;
reg [31:0] to_ex_oeip;
reg [31:0] to_ex_ieip;
reg [31:0] to_ex_pred_eip;
reg [1:0] to_ex_exception;
reg to_ex_valid;
reg [31:0] to_ex_CMPS0;
reg [31:0] to_ex_CMPS1;
reg [31:0] to_ex_tempEIP;
reg [15:0] to_ex_tempCS;
reg [19:0] to_ex_cs_limit;
wire from_ex_flush;
wire from_ex_ld_cs;
wire from_ex_br_t_nt;
wire from_ex_br_valid;
wire [15:0] from_ex_cs_target;
wire [31:0] from_ex_eip_target;
wire [12:0] from_ex_control_sigs;
wire [2:0] from_ex_dstidA;
wire [2:0] from_ex_dstidB;
wire [31:0] from_ex_gp_wr_data_1;
wire [31:0] from_ex_gp_wr_data_2;
wire [15:0] from_ex_seg_wr_data;
wire [63:0] from_ex_mmx_wr_data;
wire [63:0] from_ex_store_data;
wire from_ex_store_is_io_line_0;
wire [10:0] from_ex_store_addr_line_0;
wire [15:0] from_ex_store_mask_line_0;
wire from_ex_store_queue_alloc_line_0;
wire [10:0] from_ex_store_addr_line_1;
wire [15:0] from_ex_store_mask_line_1;
wire from_ex_store_queue_alloc_line_1;
wire [4:0] from_ex_store_data_shf_amt;
wire [15:0] from_ex_cs;
wire [31:0] from_ex_oeip;
wire from_ex_valid;
wire [1:0] from_ex_exception;

always #8 clk = ~clk;

stage_ex dut (
    .clk(clk),
    .rst_n(rst_n),
    .to_ex_control_sigs(to_ex_control_sigs),
    .to_ex_dstidA(to_ex_dstidA),
    .to_ex_dstidB(to_ex_dstidB),
    .to_ex_srcregA(to_ex_srcregA),
    .to_ex_srcregB(to_ex_srcregB),
    .to_ex_srcregC(to_ex_srcregC),
    .to_ex_srcSREG(to_ex_srcSREG),
    .to_ex_MMA(to_ex_MMA),
    .to_ex_MMB(to_ex_MMB),
    .to_ex_target_cs(to_ex_target_cs),
    .to_ex_load_result(to_ex_load_result),
    .to_ex_inc_esp(to_ex_inc_esp),
    .to_ex_dec_esp(to_ex_dec_esp),
    .to_ex_imm(to_ex_imm),
    .to_ex_store_is_io_line_0(to_ex_store_is_io_line_0),
    .to_ex_store_addr_line_0(to_ex_store_addr_line_0),
    .to_ex_store_mask_line_0(to_ex_store_mask_line_0),
    .to_ex_store_queue_alloc_line_0(to_ex_store_queue_alloc_line_0),
    .to_ex_store_addr_line_1(to_ex_store_addr_line_1),
    .to_ex_store_mask_line_1(to_ex_store_mask_line_1),
    .to_ex_store_queue_alloc_line_1(to_ex_store_queue_alloc_line_1),
    .to_ex_store_data_shf_amt(to_ex_store_data_shf_amt),
    .to_ex_rel_eip(to_ex_rel_eip),
    .to_ex_cs(to_ex_cs),
    .to_ex_oeip(to_ex_oeip),
    .to_ex_ieip(to_ex_ieip),
    .to_ex_pred_eip(to_ex_pred_eip),
    .to_ex_exception(to_ex_exception),
    .to_ex_valid(to_ex_valid),
    .to_ex_CMPS0(to_ex_CMPS0),
    .to_ex_CMPS1(to_ex_CMPS1),
    .to_ex_tempEIP(to_ex_tempEIP),
    .to_ex_tempCS(to_ex_tempCS),
    .to_ex_cs_limit(to_ex_cs_limit),
    .from_ex_flush(from_ex_flush),
    .from_ex_ld_cs(from_ex_ld_cs),
    .from_ex_br_t_nt(from_ex_br_t_nt),
    .from_ex_br_valid(from_ex_br_valid),
    .from_ex_cs_target(from_ex_cs_target),
    .from_ex_eip_target(from_ex_eip_target),
    .from_ex_control_sigs(from_ex_control_sigs),
    .from_ex_dstidA(from_ex_dstidA),
    .from_ex_dstidB(from_ex_dstidB),
    .from_ex_gp_wr_data_1(from_ex_gp_wr_data_1),
    .from_ex_gp_wr_data_2(from_ex_gp_wr_data_2),
    .from_ex_seg_wr_data(from_ex_seg_wr_data),
    .from_ex_mmx_wr_data(from_ex_mmx_wr_data),
    .from_ex_store_data(from_ex_store_data),
    .from_ex_store_is_io_line_0(from_ex_store_is_io_line_0),
    .from_ex_store_addr_line_0(from_ex_store_addr_line_0),
    .from_ex_store_mask_line_0(from_ex_store_mask_line_0),
    .from_ex_store_queue_alloc_line_0(from_ex_store_queue_alloc_line_0),
    .from_ex_store_addr_line_1(from_ex_store_addr_line_1),
    .from_ex_store_mask_line_1(from_ex_store_mask_line_1),
    .from_ex_store_queue_alloc_line_1(from_ex_store_queue_alloc_line_1),
    .from_ex_store_data_shf_amt(from_ex_store_data_shf_amt),
    .from_ex_cs(from_ex_cs),
    .from_ex_oeip(from_ex_oeip),
    .from_ex_valid(from_ex_valid),
    .from_ex_exception(from_ex_exception)
);

task clear_inputs;
begin
        to_ex_control_sigs = 54'd0;
        to_ex_dstidA = 3'd0;
        to_ex_dstidB = 3'd0;
        to_ex_srcregA = 32'd0;
        to_ex_srcregB = 32'd0;
        to_ex_srcregC = 32'd0;
        to_ex_srcSREG = 16'd0;
        to_ex_MMA = 64'd0;
        to_ex_MMB = 64'd0;
        to_ex_target_cs = 16'd0;
        to_ex_load_result = 64'd0;
        to_ex_inc_esp = 32'd0;
        to_ex_dec_esp = 32'd0;
        to_ex_imm = 32'd0;
        to_ex_store_is_io_line_0 = 1'b0;
        to_ex_store_mask_line_0 = 16'd0;
        to_ex_store_queue_alloc_line_0 = 1'b0;
        to_ex_store_addr_line_1 = 11'd0;
        to_ex_store_mask_line_1 = 16'd0;
        to_ex_store_queue_alloc_line_1 = 1'b0;
        to_ex_store_data_shf_amt = 5'd0;
        to_ex_rel_eip = 32'd0;
        to_ex_cs = 16'd0;
        to_ex_oeip = 32'd0;
        to_ex_ieip = 32'd0;
        to_ex_pred_eip = 32'd0;
        to_ex_exception = 2'd0;
        to_ex_valid = 1'b0;
        to_ex_CMPS0 = 32'd0;
        to_ex_CMPS1 = 32'd0;
        to_ex_tempEIP = 32'd0;
        to_ex_tempCS = 16'd0;
        to_ex_cs_limit = 20'd0;
end
endtask

task set_inputs;
input [53:0] to_ex_control_sigs_i;
input [2:0] to_ex_dstidA_i;
input [2:0] to_ex_dstidB_i;
input [31:0] to_ex_srcregA_i;
input [31:0] to_ex_srcregB_i;
input [31:0] to_ex_srcregC_i;
input [15:0] to_ex_srcSREG_i;
input [63:0] to_ex_MMA_i;
input [63:0] to_ex_MMB_i;
input [15:0] to_ex_target_cs_i;
input [63:0] to_ex_load_result_i;
input [31:0] to_ex_inc_esp_i;
input [31:0] to_ex_dec_esp_i;
input [31:0] to_ex_imm_i;
input to_ex_store_is_io_line_0_i;
input [15:0] to_ex_store_mask_line_0_i;
input to_ex_store_queue_alloc_line_0_i;
input [14:4] to_ex_store_addr_line_1_i;
input [15:0] to_ex_store_mask_line_1_i;
input to_ex_store_queue_alloc_line_1_i;
input [4:0] to_ex_store_data_shf_amt_i;
input [31:0] to_ex_rel_eip_i;
input [15:0] to_ex_cs_i;
input [31:0] to_ex_oeip_i;
input [31:0] to_ex_ieip_i;
input [31:0] to_ex_pred_eip_i;
input [1:0] to_ex_exception_i;
input to_ex_valid_i;
input [31:0] to_ex_CMPS0_i;
input [31:0] to_ex_CMPS1_i;
input [31:0] to_ex_tempEIP_i;
input [15:0] to_ex_tempCS_i;
input [19:0] to_ex_cs_limit_i;
begin
        to_ex_control_sigs = to_ex_control_sigs_i;
        to_ex_dstidA = to_ex_dstidA_i;
        to_ex_dstidB = to_ex_dstidB_i;
        to_ex_srcregA = to_ex_srcregA_i;
        to_ex_srcregB = to_ex_srcregB_i;
        to_ex_srcregC = to_ex_srcregC_i;
        to_ex_srcSREG = to_ex_srcSREG_i;
        to_ex_MMA = to_ex_MMA_i;
        to_ex_MMB = to_ex_MMB_i;
        to_ex_target_cs = to_ex_target_cs_i;
        to_ex_load_result = to_ex_load_result_i;
        to_ex_inc_esp = to_ex_inc_esp_i;
        to_ex_dec_esp = to_ex_dec_esp_i;
        to_ex_imm = to_ex_imm_i;
        to_ex_store_is_io_line_0 = to_ex_store_is_io_line_0_i;
        to_ex_store_mask_line_0 = to_ex_store_mask_line_0_i;
        to_ex_store_queue_alloc_line_0 = to_ex_store_queue_alloc_line_0_i;
        to_ex_store_addr_line_1 = to_ex_store_addr_line_1_i;
        to_ex_store_mask_line_1 = to_ex_store_mask_line_1_i;
        to_ex_store_queue_alloc_line_1 = to_ex_store_queue_alloc_line_1_i;
        to_ex_store_data_shf_amt = to_ex_store_data_shf_amt_i;
        to_ex_rel_eip = to_ex_rel_eip_i;
        to_ex_cs = to_ex_cs_i;
        to_ex_oeip = to_ex_oeip_i;
        to_ex_ieip = to_ex_ieip_i;
        to_ex_pred_eip = to_ex_pred_eip_i;
        to_ex_exception = to_ex_exception_i;
        to_ex_valid = to_ex_valid_i;
        to_ex_CMPS0 = to_ex_CMPS0_i;
        to_ex_CMPS1 = to_ex_CMPS1_i;
        to_ex_tempEIP = to_ex_tempEIP_i;
        to_ex_tempCS = to_ex_tempCS_i;
        to_ex_cs_limit = to_ex_cs_limit_i;
end
endtask

task print_outputs;
begin
        $display("flush = %h", from_ex_flush);
        $display("ld_cs = %h", from_ex_ld_cs);
        $display("br_t_nt = %h, br_valid = %h, cs_target = %h, eip_target = %h", from_ex_br_t_nt, from_ex_br_valid, from_ex_cs_target, from_ex_eip_target);
        $display("control_sigs = %b", from_ex_control_sigs);
        $display("dstidA = %h, dstidB = %h", from_ex_dstidA, from_ex_dstidB);
        $display("gp_wr_data_1 = %h, gp_wr_data_2 = %h, seg_wr_data = %h", from_ex_gp_wr_data_1, from_ex_gp_wr_data_2, from_ex_seg_wr_data);
        $display("mmx_wr_data = %h, store_data = %h", from_ex_mmx_wr_data, from_ex_store_data);
        $display("store_is_io_line_0 = %h, store_mask_line_0 = %h, store_queue_alloc_line_0 = %h, store_addr_line_1 = %h, store_mask_line_1 = %h, store_queue_alloc_line_1 = %h, store_data_shf_amt = %h", 
                        from_ex_store_is_io_line_0, from_ex_store_mask_line_0, from_ex_store_queue_alloc_line_0, from_ex_store_addr_line_1, from_ex_store_mask_line_1, from_ex_store_queue_alloc_line_1, from_ex_store_data_shf_amt);
        $display("cs = %h, oeip = %h", from_ex_cs, from_ex_oeip);
        $display("valid = %h", from_ex_valid);
        $display("exception = %h", from_ex_exception);
end
endtask

initial begin 
    clk = 1'b0;
    rst_n = 1'b0;
    clear_inputs();
    @(posedge clk);
    @(posedge clk);
    rst_n = 1'b1;

    print_outputs();
end

endmodule