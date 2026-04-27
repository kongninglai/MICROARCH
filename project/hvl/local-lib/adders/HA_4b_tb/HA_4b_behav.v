module HA_4b_behav (
  input  [3:0] in0,
  input  [3:0] in1,
  output reg [3:0] s,
  output reg cout
);

  reg [4:0] result;

  always @(*) begin
    // full 5-bit addition (captures carry out naturally)
    result = in0 + in1;

    // split outputs
    s    = result[3:0];
    cout = result[4];
  end

endmodule