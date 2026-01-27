module  mmu_tb;

initial begin
  $vcdplusfile("mmu_tb.dump.vpd");
  $vcdpluson(0, mmu_tb); 
  $vcdpluson(0, mmu_tb.DUT); 
  $vcdpluson(0, mmu_tb.DUT.mem_module.rank_group_generation[0].rank_generation[0].rank_inst.chip_generation[0].sram128x8$_inst.mem); 
end

reg     rst, clk, RD, WR;

reg   [31:0]  DATA_driver;
reg           DATA_driver_enable;
reg   [14:0]  ADDR_driver;
reg           ADDR_driver_enable;

wire  [31:0]  DATA_BUS = DATA_driver_enable ? DATA_driver : {32{1'bz}};
wire   [14:0]  ADDR_BUS = ADDR_driver_enable ? ADDR_driver : {15{1'bz}};

wire  [2:0]   STATE = {mmu_tb.DUT.Q2, mmu_tb.DUT.Q1, mmu_tb.DUT.Q0};

mmu DUT (
  .rst(rst), .clk(clk), .RD(RD), .WR(WR),
  .DATA_BUS(DATA_BUS),
  .ADDR_BUS(ADDR_BUS)
);

integer SUCCESSES = 0;
integer FAILURES = 0;

integer i;

localparam CYCLE_TIME = 10;

initial begin
  clk = 0;
  forever begin
    #(CYCLE_TIME / 2) clk = ~clk;
  end
end

task check_read;
  input [14:0] ADDR;
  begin
    if (DATA_BUS != {{17{1'b0}}, ADDR}) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t. DATA_BUS_exp = %h, DATA_BUS = %h\n", 
                $time, {{17{1'b0}}, ADDR}, DATA_BUS);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

task read;
  input [14:0]  ADDR;
  begin
    DATA_driver_enable    = 1'b0;
    ADDR_driver_enable    = 1'b1;
    ADDR_driver           = ADDR;
    RD = 0;
    WR = 1;
    #(CYCLE_TIME);
    RD = 1;
    #(8*CYCLE_TIME);
    check_read(ADDR);
    #(3*CYCLE_TIME);
    check_read(ADDR+4);
    #(3*CYCLE_TIME);
    check_read(ADDR+8);
    #(3*CYCLE_TIME);
    check_read(ADDR+12);
    #(CYCLE_TIME);
  end
endtask

task write;
  input [14:0] ADDR;
  input [31:0] DATA;
  begin
    DATA_driver_enable    = 1'b1;
    DATA_driver           = DATA;
    ADDR_driver_enable    = 1'b1;
    ADDR_driver           = ADDR;
    RD                    = 1'b1;
    WR                    = 1'b1;
    #(2*CYCLE_TIME);
    WR                    = 1'b0;
    #(9*CYCLE_TIME);
    DATA_driver           = DATA+4;
    ADDR_driver           = ADDR+4;
    #(9*CYCLE_TIME);
    DATA_driver           = DATA+8;
    ADDR_driver           = ADDR+8;
    #(9*CYCLE_TIME);
    DATA_driver           = DATA+12;
    ADDR_driver           = ADDR+12;
    #(CYCLE_TIME);
    WR                    = 1'b1;
    #(8*CYCLE_TIME);
  end
endtask

initial begin
  rst = 1'b1;
  ADDR_driver_enable    = 1'b1;
  ADDR_driver           = 15'd0;
  WR                    = 1'b1;
  RD                    = 1'b1;
  DATA_driver_enable    = 1'b0;
  DATA_driver           = {32{1'bz}};
  #(CYCLE_TIME);
  rst = 1'b0;
  #(CYCLE_TIME);
  rst = 1'b1;
  #(0.5*CYCLE_TIME);

  for (i = 0; i < 32768; i = i + 16) begin
    write(i, i);
    read(i);
  end



  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule