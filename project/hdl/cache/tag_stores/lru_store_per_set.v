/* AUTO GENERATED MOORE LOGIC */
module lru_store_per_set
(
  input     rst, clk, T1, T0, valid,
  output              V1, V0
);

wire  Q0,
      Q1,
      Q2,
      Q3,
      Q4;

wire  Q0_prebuf,
      Q1_prebuf,
      Q2_prebuf,
      Q3_prebuf,
      Q4_prebuf;


wire D4, D3, D2, D1, D0;


wire [31:0] out_00, out_01, out_10, out_11;

rom32b32w$   rom32b32w$_out_00({Q2,Q1,Q0,T1,T0}, rst, out_00);
rom32b32w$   rom32b32w$_out_01({Q2,Q1,Q0,T1,T0}, rst, out_01);
rom32b32w$   rom32b32w$_out_10({Q2,Q1,Q0,T1,T0}, rst, out_10);
rom32b32w$   rom32b32w$_out_11({Q2,Q1,Q0,T1,T0}, rst, out_11);

initial begin
  $readmemb("/home/ecelrc/students/var2427/MICROARCH/project/hdl/cache/tag_stores/lru_rom_00.txt", rom32b32w$_out_00.mem);
  $readmemb("/home/ecelrc/students/var2427/MICROARCH/project/hdl/cache/tag_stores/lru_rom_01.txt", rom32b32w$_out_01.mem);
  $readmemb("/home/ecelrc/students/var2427/MICROARCH/project/hdl/cache/tag_stores/lru_rom_10.txt", rom32b32w$_out_10.mem);
  $readmemb("/home/ecelrc/students/var2427/MICROARCH/project/hdl/cache/tag_stores/lru_rom_11.txt", rom32b32w$_out_11.mem);
end

assign V1 = Q4;
assign V0 = Q3;

wire [2:0] D_DUMMY;

mux8_8    mux8_8_D
(
  {D_DUMMY, D4, D3, D2, D1, D0},

  {3'd0, Q4, Q3, Q2, Q1, Q0},
  {3'd0, Q4, Q3, Q2, Q1, Q0},
  {3'd0, Q4, Q3, Q2, Q1, Q0},
  {3'd0, Q4, Q3, Q2, Q1, Q0},

  out_00[7:0],
  out_01[7:0],
  out_10[7:0],
  out_11[7:0],

  Q3,
  Q4,
  valid
);

dff$ dff_0(clk, D0, , Q0_prebuf, rst, 1'b1);
dff$ dff_1(clk, D1, , Q1_prebuf, rst, 1'b1);
dff$ dff_2(clk, D2, , Q2_prebuf, rst, 1'b1);
dff$ dff_3(clk, D3, , Q3_prebuf, rst, 1'b1);
dff$ dff_4(clk, D4, , Q4_prebuf, rst, 1'b1);

bufferHInv16$   bufferHInv16$_Q0(Q0, Q0_prebuf);
bufferHInv16$   bufferHInv16$_Q1(Q1, Q1_prebuf);
bufferHInv16$   bufferHInv16$_Q2(Q2, Q2_prebuf);
bufferHInv16$   bufferHInv16$_Q3(Q3, Q3_prebuf);
bufferHInv16$   bufferHInv16$_Q4(Q4, Q4_prebuf);

endmodule