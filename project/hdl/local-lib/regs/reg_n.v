module  reg_n #(
  parameter   WIDTH=8,
  parameter   USE_EN_BAR=0,
  parameter   RESET_TO_ONES=0
) (
  input               clk, rst,
  input   [WIDTH-1:0] en, d,

  output  [WIDTH-1:0] q
);

wire      [WIDTH-1:0] in;

genvar i;
generate
  for (i = 0; i < WIDTH; i = i + 1) begin : reg_enable_generation
    if (USE_EN_BAR == 0) begin : active_high_gen
      mux2$     mux2$_in_en(in[i], q[i], d[i], en[i]);
    end else begin : active_low_gen
      mux2$     mux2$_in_enbar(in[i], d[i], q[i], en[i]);
    end
  end

  if (RESET_TO_ONES == 0) begin : reset_to_zeros_gen
    dff$      dff$_q[WIDTH-1:0](clk, in, q, , rst, 1'b1);
  end else begin : reset_to_ones_gen
    dff$      dff$_q[WIDTH-1:0](clk, in, q, , 1'b1, rst);
  end

endgenerate


endmodule