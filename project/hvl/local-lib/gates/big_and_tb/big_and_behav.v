module big_and_behav #(
  parameter WIDTH = 32
) (
  output reg       out,
  input  [WIDTH-1:0]    in
);

integer i;
always @(*) begin
    out = 1'b1;
    for (i = 0; i < WIDTH; i = i + 1) begin
        out = out & in[i];
    end
end

endmodule
