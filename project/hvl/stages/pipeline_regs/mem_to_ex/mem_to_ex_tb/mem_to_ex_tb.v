module mem_to_ex_tb;

initial begin
  // $vcdplusfile("mem_to_ex_tb.dump.vpd");
  // $vcdpluson(0, mem_to_ex_tb); 
end

localparam WIDTH = 684;
localparam CYCLE_TIME = 10.0;

reg clk, rst_n, we;
// Inputs (regs)
reg [54:0] from_mem_control_sigs;
reg [2:0]  from_mem_dstidA;
reg [2:0]  from_mem_dstidB;
reg [31:0] from_mem_srcregA;
reg [31:0] from_mem_srcregB;
reg [31:0] from_mem_srcregC;
reg [15:0] from_mem_srcSREG;
reg [63:0] from_mem_MMA;
reg [63:0] from_mem_MMB;

reg [15:0] from_mem_target_cs;
reg [63:0] from_mem_load_result;
reg [31:0] from_mem_inc_esp;
reg [31:0] from_mem_dec_esp;
reg [31:0] from_mem_imm;
reg [31:0] from_mem_rel_eip;

reg        from_mem_store_is_io_line_0;
reg [14:4] from_mem_store_addr_line_0;
reg [15:0] from_mem_store_mask_line_0;
reg        from_mem_store_queue_alloc_line_0;
reg [14:4] from_mem_store_addr_line_1;
reg [15:0] from_mem_store_mask_line_1;
reg        from_mem_store_queue_alloc_line_1;
reg [4:0]  from_mem_store_data_shf_amt;

reg [15:0] from_mem_cs;
reg [31:0] from_mem_oeip;
reg [31:0] from_mem_ieip;
reg [31:0] from_mem_pred_eip;
reg [1:0]  from_mem_exception;
reg        from_mem_valid;


// Outputs (wires)
wire [54:0] to_ex_control_sigs;
wire [2:0]  to_ex_dstidA;
wire [2:0]  to_ex_dstidB;
wire [31:0] to_ex_srcregA;
wire [31:0] to_ex_srcregB;
wire [31:0] to_ex_srcregC;
wire [15:0] to_ex_srcSREG;
wire [63:0] to_ex_MMA;
wire [63:0] to_ex_MMB;

wire [15:0] to_ex_target_cs;
wire [63:0] to_ex_load_result;
wire [31:0] to_ex_inc_esp;
wire [31:0] to_ex_dec_esp;
wire [31:0] to_ex_imm;
wire [31:0] to_ex_rel_eip;

wire        to_ex_store_is_io_line_0;
wire [14:4] to_ex_store_addr_line_0;
wire [15:0] to_ex_store_mask_line_0;
wire        to_ex_store_queue_alloc_line_0;
wire [14:4] to_ex_store_addr_line_1;
wire [15:0] to_ex_store_mask_line_1;
wire        to_ex_store_queue_alloc_line_1;
wire [4:0]  to_ex_store_data_shf_amt;

wire [15:0] to_ex_cs;
wire [31:0] to_ex_oeip;
wire [31:0] to_ex_ieip;
wire [31:0] to_ex_pred_eip;
wire [1:0]  to_ex_exception;
wire        to_ex_valid;

reg [WIDTH-1:0] out_exp;

always #(CYCLE_TIME/2.0) clk = ~clk;

mem_to_ex DUT (
  .clk(clk),
  .rst_n(rst_n),
  .we(we),

  .from_mem_control_sigs(from_mem_control_sigs),
  .from_mem_dstidA(from_mem_dstidA),
  .from_mem_dstidB(from_mem_dstidB),
  .from_mem_srcregA(from_mem_srcregA),
  .from_mem_srcregB(from_mem_srcregB),
  .from_mem_srcregC(from_mem_srcregC),
  .from_mem_srcSREG(from_mem_srcSREG),
  .from_mem_MMA(from_mem_MMA),
  .from_mem_MMB(from_mem_MMB),

  .from_mem_target_cs(from_mem_target_cs),
  .from_mem_load_result(from_mem_load_result),
  .from_mem_inc_esp(from_mem_inc_esp),
  .from_mem_dec_esp(from_mem_dec_esp),
  .from_mem_imm(from_mem_imm),
  .from_mem_rel_eip(from_mem_rel_eip),

  .from_mem_store_is_io_line_0(from_mem_store_is_io_line_0),
  .from_mem_store_addr_line_0(from_mem_store_addr_line_0),
  .from_mem_store_mask_line_0(from_mem_store_mask_line_0),
  .from_mem_store_queue_alloc_line_0(from_mem_store_queue_alloc_line_0),
  .from_mem_store_addr_line_1(from_mem_store_addr_line_1),
  .from_mem_store_mask_line_1(from_mem_store_mask_line_1),
  .from_mem_store_queue_alloc_line_1(from_mem_store_queue_alloc_line_1),
  .from_mem_store_data_shf_amt(from_mem_store_data_shf_amt),

  .from_mem_cs(from_mem_cs),
  .from_mem_oeip(from_mem_oeip),
  .from_mem_ieip(from_mem_ieip),
  .from_mem_pred_eip(from_mem_pred_eip),
  .from_mem_exception(from_mem_exception),
  .from_mem_valid(from_mem_valid),

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
  .to_ex_rel_eip(to_ex_rel_eip),

  .to_ex_store_is_io_line_0(to_ex_store_is_io_line_0),
  .to_ex_store_addr_line_0(to_ex_store_addr_line_0),
  .to_ex_store_mask_line_0(to_ex_store_mask_line_0),
  .to_ex_store_queue_alloc_line_0(to_ex_store_queue_alloc_line_0),
  .to_ex_store_addr_line_1(to_ex_store_addr_line_1),
  .to_ex_store_mask_line_1(to_ex_store_mask_line_1),
  .to_ex_store_queue_alloc_line_1(to_ex_store_queue_alloc_line_1),
  .to_ex_store_data_shf_amt(to_ex_store_data_shf_amt),

  .to_ex_cs(to_ex_cs),
  .to_ex_oeip(to_ex_oeip),
  .to_ex_ieip(to_ex_ieip),
  .to_ex_pred_eip(to_ex_pred_eip),
  .to_ex_exception(to_ex_exception),
  .to_ex_valid(to_ex_valid)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  input [WIDTH-1:0] out, out_exp;
  if (out !== out_exp) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h\n", 
              $time, out_exp, out);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
  clk = 0; rst_n = 0; we = 1; out_exp = 0;

  #(CYCLE_TIME);
  rst_n = 1;
  
  repeat (1 << 12) begin
    // Drive inputs with random values
    {
      from_mem_control_sigs,
      from_mem_dstidA,
      from_mem_dstidB,
      from_mem_srcregA,
      from_mem_srcregB,
      from_mem_srcregC,
      from_mem_srcSREG,
      from_mem_MMA,
      from_mem_MMB,
      from_mem_target_cs,
      from_mem_load_result,
      from_mem_inc_esp,
      from_mem_dec_esp,
      from_mem_imm,
      from_mem_rel_eip,
      from_mem_store_is_io_line_0,
      from_mem_store_addr_line_0,
      from_mem_store_mask_line_0,
      from_mem_store_queue_alloc_line_0,
      from_mem_store_addr_line_1,
      from_mem_store_mask_line_1,
      from_mem_store_queue_alloc_line_1,
      from_mem_store_data_shf_amt,
      from_mem_cs,
      from_mem_oeip,
      from_mem_ieip,
      from_mem_pred_eip,
      from_mem_exception,
      from_mem_valid
    } = {
      {$random}, {$random}, {$random}, {$random}, {$random}, 
      {$random}, {$random}, {$random}, {$random}, {$random}, 
      {$random}, {$random}, {$random}, {$random}, {$random}, 
      {$random}, {$random}, {$random}, {$random}, {$random}, 
      {$random}, {$random}
    };

    out_exp = {
      from_mem_control_sigs,
      from_mem_dstidA,
      from_mem_dstidB,
      from_mem_srcregA,
      from_mem_srcregB,
      from_mem_srcregC,
      from_mem_srcSREG,
      from_mem_MMA,
      from_mem_MMB,
      from_mem_target_cs,
      from_mem_load_result,
      from_mem_inc_esp,
      from_mem_dec_esp,
      from_mem_imm,
      from_mem_rel_eip,
      from_mem_store_is_io_line_0,
      from_mem_store_addr_line_0,
      from_mem_store_mask_line_0,
      from_mem_store_queue_alloc_line_0,
      from_mem_store_addr_line_1,
      from_mem_store_mask_line_1,
      from_mem_store_queue_alloc_line_1,
      from_mem_store_data_shf_amt,
      from_mem_cs,
      from_mem_oeip,
      from_mem_ieip,
      from_mem_pred_eip,
      from_mem_exception,
      from_mem_valid
    };

    #(CYCLE_TIME);

    check({
      to_ex_control_sigs,
      to_ex_dstidA,
      to_ex_dstidB,
      to_ex_srcregA,
      to_ex_srcregB,
      to_ex_srcregC,
      to_ex_srcSREG,
      to_ex_MMA,
      to_ex_MMB,
      to_ex_target_cs,
      to_ex_load_result,
      to_ex_inc_esp,
      to_ex_dec_esp,
      to_ex_imm,
      to_ex_rel_eip,
      to_ex_store_is_io_line_0,
      to_ex_store_addr_line_0,
      to_ex_store_mask_line_0,
      to_ex_store_queue_alloc_line_0,
      to_ex_store_addr_line_1,
      to_ex_store_mask_line_1,
      to_ex_store_queue_alloc_line_1,
      to_ex_store_data_shf_amt,
      to_ex_cs,
      to_ex_oeip,
      to_ex_ieip,
      to_ex_pred_eip,
      to_ex_exception,
      to_ex_valid
    }, out_exp);
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
  $finish;
end

endmodule