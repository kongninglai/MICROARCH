module lshf_const_behav #(
  parameter   WIDTH     = 32,
  parameter   SHF_AMT   = 16,
  parameter   SHF_ONES  = 0
) (
  input       [WIDTH-1:0]   in,
  output      [WIDTH-1:0]   out
);
  
  localparam [WIDTH-1:0] FILL_MASK = SHF_ONES ? ({WIDTH{1'b1}} >> (WIDTH - SHF_AMT)) : {WIDTH{1'b0}};

  assign out = (in << SHF_AMT) | FILL_MASK;
  
endmodule