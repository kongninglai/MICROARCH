module lru_store_behav #(
  parameter NUM_SETS=8,
  parameter INDEX_WIDTH=$clog2(NUM_SETS),
  parameter NUM_WAYS=4,
  parameter WAY_WIDTH=$clog2(NUM_WAYS),
  parameter TAG_WIDTH=8,
  parameter RANK_BURST_SIZE=4,
  parameter MEM_ADDR_WIDTH=15
) (
  input                                             rst,
                                                    clk,
  input     [WAY_WIDTH-1:0]                         TAG_HIT_WAY,
  input                                             CACHE_HIT,
  input     [MEM_ADDR_WIDTH-1:RANK_BURST_SIZE]      CC_ADDR_OUT,
  output reg [WAY_WIDTH-1:0]                        VICT_WAY
);

wire [INDEX_WIDTH-1:0] set_index;
assign set_index = CC_ADDR_OUT[RANK_BURST_SIZE+INDEX_WIDTH-1:RANK_BURST_SIZE];

wire [NUM_SETS-1:0] touch_valids;

genvar i;
generate
  for (i = 0; i < NUM_SETS; i = i + 1) begin : TOUCH
    assign touch_valids[i] = CACHE_HIT && (set_index == i);
  end
endgenerate

wire [NUM_SETS-1:0] VICT_WAYS_BIT1, VICT_WAYS_BIT0;

generate
  for (i = 0; i < NUM_SETS; i = i + 1) begin : PER_SET
    lru_store_per_set_behav per_set (
      .rst(rst),
      .clk(clk),
      .valid(touch_valids[i]),
      .T1(TAG_HIT_WAY[WAY_WIDTH-1]),
      .T0(TAG_HIT_WAY[0]),
      .V1(VICT_WAYS_BIT1[i]),
      .V0(VICT_WAYS_BIT0[i])
    );
  end
endgenerate

always @(*) begin
  case (set_index)
    3'd0: VICT_WAY = {VICT_WAYS_BIT1[0], VICT_WAYS_BIT0[0]};
    3'd1: VICT_WAY = {VICT_WAYS_BIT1[1], VICT_WAYS_BIT0[1]};
    3'd2: VICT_WAY = {VICT_WAYS_BIT1[2], VICT_WAYS_BIT0[2]};
    3'd3: VICT_WAY = {VICT_WAYS_BIT1[3], VICT_WAYS_BIT0[3]};
    3'd4: VICT_WAY = {VICT_WAYS_BIT1[4], VICT_WAYS_BIT0[4]};
    3'd5: VICT_WAY = {VICT_WAYS_BIT1[5], VICT_WAYS_BIT0[5]};
    3'd6: VICT_WAY = {VICT_WAYS_BIT1[6], VICT_WAYS_BIT0[6]};
    3'd7: VICT_WAY = {VICT_WAYS_BIT1[7], VICT_WAYS_BIT0[7]};
    default: VICT_WAY = 0;
  endcase
end

endmodule