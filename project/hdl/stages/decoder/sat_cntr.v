/* AUTO GENERATED NAND-NAND LOGIC */
module sat_cntr(
	input wire CurState1,
	input wire CurState0,
	input wire Incr_or_Decr,
	output wire NextState1,
	output wire NextState0
);

  wire [1:0] incr, decr;
  wire [5:0] incr_dummy, decr_dummy;
  mux4_8$ mux4_8$_incr
  (
    {incr_dummy, incr},
    {6'd0, 2'b01},
    {6'd0, 2'b10},
    {6'd0, 2'b11},
    {6'd0, 2'b11},
    CurState0,
    CurState1
  );
  mux4_8$ mux4_8$_decr
  (
    {decr_dummy, decr},
    {6'd0, 2'b00},
    {6'd0, 2'b00},
    {6'd0, 2'b01},
    {6'd0, 2'b10},
    CurState0,
    CurState1
  );
  
  wire [5:0] next_dummy;
  mux2_8$ mux2_8$_next
  (
    {next_dummy, NextState1, NextState0},
    {6'd0, decr},
    {6'd0, incr},
    Incr_or_Decr
  );

endmodule

