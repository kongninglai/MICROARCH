module  ze_tb;

localparam INP_WIDTH = 16;
localparam OUT_WIDTH = 32;

reg   [INP_WIDTH-1:0]   in;
wire  [OUT_WIDTH-1:0]   out, out_behav;

reg   [OUT_WIDTH-1:0]   out_exp;

ze          #(.INP_WIDTH(INP_WIDTH), .OUT_WIDTH(OUT_WIDTH))
            DUT_ze (.in(in), .out(out));
            
ze_behav    #(.INP_WIDTH(INP_WIDTH), .OUT_WIDTH(OUT_WIDTH))
            REF_ze (.in(in), .out(out_behav));

integer FAILURES  = 0;
integer SUCCESSES = 0;

initial begin

  // Basic tests against hand-computed ground truth
  in        = 16'h7FFF;
  out_exp   = 32'h00007FFF;
  #1;
  if (out_exp !== out || out_exp !== out_behav) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h, out_behav = %h\n", 
              $time, out_exp, out, out_behav);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end

  in        = 16'h8000;
  out_exp   = 32'h00008000;
  #1;
  if (out_exp !== out || out_exp !== out_behav) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t. out_exp = %h, out = %h, out_behav = %h\n", 
              $time, out_exp, out, out_behav);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end

  // More tests comparing structural to behavioral
  in        = 8'd0;
  repeat (256) begin
    #1;
    if (out !== out_behav) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t. out = %h, out_behav = %h\n", 
                $time, out_exp, out, out_behav);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
    in = in + 1;
  end

  #1;

  $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

// Dump all waveforms to d_latch.dump.vpd
initial begin
  $vcdplusfile("ze_tb.dump.vpd");
  $vcdpluson(0, ze_tb); 
end

endmodule