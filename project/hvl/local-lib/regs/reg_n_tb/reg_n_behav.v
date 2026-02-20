module  reg_n_behav #(
  parameter   WIDTH=8,
  parameter   USE_EN_BAR=0,
  parameter   RESET_TO_ONES=0
) (
  input                   clk, rst,
  input       [WIDTH-1:0] en, d,

  output  reg [WIDTH-1:0] q
);

integer i;

always @(posedge clk or rst) begin
  if (rst == 0) begin
    if (RESET_TO_ONES == 0)
      q <= {WIDTH{1'b0}};
    else
      q <= {WIDTH{1'b1}};
  end
  else begin
    for (i = 0; i < WIDTH; i = i + 1) begin
      if (USE_EN_BAR == 0) begin
        if (en[i])
          q[i] <= d[i];
        else
          q[i] <= q[i];
      end
      else begin
        if (!en[i])
          q[i] <= d[i];
        else
          q[i] <= q[i];
      end
    end
  end
end

endmodule