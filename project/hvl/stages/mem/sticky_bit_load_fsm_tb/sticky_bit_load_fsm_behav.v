module sticky_bit_load_fsm_behav (
  input rst,
  input clk,
  input LINE_0_LOAD_DONE_AND_NEEDS_LINE_1_LOAD_AND_FLUSH_BAR,
  input FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR,
  output reg DOING_LINE_1_LOAD
);

reg DOING_LINE_1_LOAD_NEXT;

always @(*) begin
  DOING_LINE_1_LOAD_NEXT =
    (~DOING_LINE_1_LOAD & LINE_0_LOAD_DONE_AND_NEEDS_LINE_1_LOAD_AND_FLUSH_BAR) |
    ( DOING_LINE_1_LOAD & ~FLUSH_OR_LINE_1_LOAD_DONE_AND_MEM_STALL_BAR);
end

always @(posedge clk or negedge rst) begin
  if (!rst)
    DOING_LINE_1_LOAD <= 1'b0;
  else
    DOING_LINE_1_LOAD <= DOING_LINE_1_LOAD_NEXT;
end

endmodule