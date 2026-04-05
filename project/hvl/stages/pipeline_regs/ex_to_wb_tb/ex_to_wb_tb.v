module ex_to_wb_tb;

initial begin
  $vcdplusfile("ex_to_wb_tb.dump.vpd");
  $vcdpluson(0, ex_to_wb_tb); 
end

localparam WIDTH = 339;
localparam CYCLE_TIME = 10.0;

reg clk, rst_n, we;
reg [WIDTH-1:0] din;
wire [WIDTH-1:0] q_out;
reg [WIDTH-1:0] out_exp;

always #(CYCLE_TIME/2.0) clk = ~clk;

reg [11:0] from_ex_control_sigs;
reg [2:0] from_ex_dstidA;
reg [2:0] from_ex_dstidB;
reg [31:0] from_ex_gp_wr_data_1;
reg [31:0] from_ex_gp_wr_data_2;
reg [15:0] from_ex_seg_wr_data;
reg [63:0] from_ex_mmx_wr_data;
reg [63:0] from_ex_store_data;
reg from_ex_store_is_io_line_0;
reg [10:0] from_ex_store_addr_line_0;
reg [15:0] from_ex_store_mask_line_0;
reg from_ex_store_queue_alloc_line_0;
reg [10:0] from_ex_store_addr_line_1;
reg [15:0] from_ex_store_mask_line_1;
reg from_ex_store_queue_alloc_line_1;
reg [4:0] from_ex_store_data_shf_amt;
reg [15:0] from_ex_cs;
reg [31:0] from_ex_oeip;
reg from_ex_valid;
reg [1:0] from_ex_exception;
wire [11:0] to_wb_control_sigs;
wire [2:0] to_wb_dstidA;
wire [2:0] to_wb_dstidB;
wire [31:0] to_wb_gp_wr_data_1;
wire [31:0] to_wb_gp_wr_data_2;
wire [15:0] to_wb_seg_wr_data;
wire [63:0] to_wb_mmx_wr_data;
wire [63:0] to_wb_store_data;
wire to_wb_store_is_io_line_0;
wire [10:0] to_wb_store_addr_line_0;
wire [15:0] to_wb_store_mask_line_0;
wire to_wb_store_queue_alloc_line_0;
wire [10:0] to_wb_store_addr_line_1;
wire [15:0] to_wb_store_mask_line_1;
wire to_wb_store_queue_alloc_line_1;
wire [4:0] to_wb_store_data_shf_amt;
wire [15:0] to_wb_cs;
wire [31:0] to_wb_oeip;
wire to_wb_valid;
wire [1:0] to_wb_exception;


assign q_out = {to_wb_control_sigs, to_wb_dstidA, to_wb_dstidB, to_wb_gp_wr_data_1, to_wb_gp_wr_data_2, to_wb_seg_wr_data, to_wb_mmx_wr_data, to_wb_store_data, to_wb_store_is_io_line_0, to_wb_store_addr_line_0, to_wb_store_mask_line_0, to_wb_store_queue_alloc_line_0, to_wb_store_addr_line_1, to_wb_store_mask_line_1, to_wb_store_queue_alloc_line_1, to_wb_store_data_shf_amt, to_wb_cs, to_wb_oeip, to_wb_valid, to_wb_exception};

ex_to_wb dut (
    .clk(clk),
    .rst_n(rst_n),
    .we(we),
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
    .from_ex_exception(from_ex_exception),
    .to_wb_control_sigs(to_wb_control_sigs),
    .to_wb_dstidA(to_wb_dstidA),
    .to_wb_dstidB(to_wb_dstidB),
    .to_wb_gp_wr_data_1(to_wb_gp_wr_data_1),
    .to_wb_gp_wr_data_2(to_wb_gp_wr_data_2),
    .to_wb_seg_wr_data(to_wb_seg_wr_data),
    .to_wb_mmx_wr_data(to_wb_mmx_wr_data),
    .to_wb_store_data(to_wb_store_data),
    .to_wb_store_is_io_line_0(to_wb_store_is_io_line_0),
    .to_wb_store_addr_line_0(to_wb_store_addr_line_0),
    .to_wb_store_mask_line_0(to_wb_store_mask_line_0),
    .to_wb_store_queue_alloc_line_0(to_wb_store_queue_alloc_line_0),
    .to_wb_store_addr_line_1(to_wb_store_addr_line_1),
    .to_wb_store_mask_line_1(to_wb_store_mask_line_1),
    .to_wb_store_queue_alloc_line_1(to_wb_store_queue_alloc_line_1),
    .to_wb_store_data_shf_amt(to_wb_store_data_shf_amt),
    .to_wb_cs(to_wb_cs),
    .to_wb_oeip(to_wb_oeip),
    .to_wb_valid(to_wb_valid),
    .to_wb_exception(to_wb_exception)
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
  clk = 0; rst_n = 0; we = 1; din = 0; out_exp = 0;
  #(CYCLE_TIME);
  rst_n = 1;
  
  repeat (1 << 12) begin
    din = { {$random}, {$random}, {$random}, {$random}, {$random}, 
            {$random}, {$random}, {$random}, {$random}, {$random}, 
            {$random}};
    {from_ex_control_sigs, from_ex_dstidA, from_ex_dstidB, from_ex_gp_wr_data_1, from_ex_gp_wr_data_2, from_ex_seg_wr_data, from_ex_mmx_wr_data, from_ex_store_data, from_ex_store_is_io_line_0, from_ex_store_addr_line_0, from_ex_store_mask_line_0, from_ex_store_queue_alloc_line_0, from_ex_store_addr_line_1, from_ex_store_mask_line_1, from_ex_store_queue_alloc_line_1, from_ex_store_data_shf_amt, from_ex_cs, from_ex_oeip, from_ex_valid, from_ex_exception} = din;
    out_exp = din;
    #(CYCLE_TIME);
    check(q_out, out_exp);
  end

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
  $finish;
end

endmodule