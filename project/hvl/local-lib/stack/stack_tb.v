module stack_tb;

initial begin
  // $vcdplusfile("stack_tb.dump.vpd");
  // $vcdpluson(0, stack_tb);
end

localparam WIDTH = 8;
localparam DEPTH = 4;
localparam PTR_WIDTH = 2;

reg clk;
reg rst_n;
reg push;
reg pop;
reg flush;
reg [WIDTH-1:0] push_data;

wire [WIDTH-1:0] pop_data;
wire [WIDTH-1:0] top_data;
wire [PTR_WIDTH:0] count;
wire empty;
wire full;

stack_bh #(
  .WIDTH(WIDTH),
  .DEPTH(DEPTH),
  .PTR_WIDTH(PTR_WIDTH)
) DUT (
  .clk(clk),
  .rst_n(rst_n),
  .push(push),
  .pop(pop),
  .flush(flush),
  .push_data(push_data),
  .pop_data(pop_data),
  .top_data(top_data),
  .count(count),
  .empty(empty),
  .full(full)
);

reg [WIDTH-1:0] ref_stack [0:DEPTH-1];
integer ref_sp;
integer i;

integer FAILURES = 0;
integer SUCCESSES = 0;

always #5 clk = ~clk;

task check;
  input [WIDTH-1:0] exp_top;
  input [PTR_WIDTH:0] exp_count;
  input exp_empty;
  input exp_full;
  begin
    if (top_data !== exp_top ||
        pop_data !== exp_top ||
        count !== exp_count ||
        empty !== exp_empty ||
        full !== exp_full) begin
      FAILURES = FAILURES + 1;
      $display("FAILURE AT TIME %t", $time);
      $display("  top_data: exp=%h got=%h", exp_top, top_data);
      $display("  pop_data: exp=%h got=%h", exp_top, pop_data);
      $display("  count:    exp=%d got=%d", exp_count, count);
      $display("  empty:    exp=%b got=%b", exp_empty, empty);
      $display("  full:     exp=%b got=%b", exp_full, full);
    end else begin
      SUCCESSES = SUCCESSES + 1;
    end
  end
endtask

task check_ref;
  reg [WIDTH-1:0] exp_top;
  reg [PTR_WIDTH:0] exp_count;
  reg exp_empty;
  reg exp_full;
  begin
    exp_top = (ref_sp == 0) ? {WIDTH{1'b0}} : ref_stack[ref_sp-1];
    exp_count = ref_sp[PTR_WIDTH:0];
    exp_empty = (ref_sp == 0);
    exp_full = (ref_sp == DEPTH);
    check(exp_top, exp_count, exp_empty, exp_full);
  end
endtask

task update_ref;
  input do_push;
  input do_pop;
  input do_flush;
  input [WIDTH-1:0] data;
  reg ref_empty;
  reg ref_full;
  reg push_ok;
  reg pop_ok;
  begin
    ref_empty = (ref_sp == 0);
    ref_full = (ref_sp == DEPTH);
    push_ok = do_push && (!ref_full || do_pop);
    pop_ok = do_pop && !ref_empty;

    if (do_flush) begin
      ref_sp = 0;
    end else if (push_ok && pop_ok) begin
      ref_stack[ref_sp-1] = data;
    end else if (push_ok) begin
      ref_stack[ref_sp] = data;
      ref_sp = ref_sp + 1;
    end else if (pop_ok) begin
      ref_sp = ref_sp - 1;
    end
  end
endtask

task step;
  input do_push;
  input do_pop;
  input do_flush;
  input [WIDTH-1:0] data;
  begin
    @(negedge clk);
    push = do_push;
    pop = do_pop;
    flush = do_flush;
    push_data = data;
    #1;
    check_ref;

    @(posedge clk);
    update_ref(do_push, do_pop, do_flush, data);
    #1;
    check_ref;
  end
endtask

initial begin
  clk = 1'b0;
  rst_n = 1'b0;
  push = 1'b0;
  pop = 1'b0;
  flush = 1'b0;
  push_data = {WIDTH{1'b0}};
  ref_sp = 0;
  for (i = 0; i < DEPTH; i = i + 1) begin
    ref_stack[i] = {WIDTH{1'b0}};
  end

  repeat (2) @(posedge clk);
  #1;
  check_ref;

  rst_n = 1'b1;
  #1;
  check_ref;

  step(1'b0, 1'b1, 1'b0, 8'h00);  // Pop empty: ignored.
  step(1'b1, 1'b0, 1'b0, 8'h11);
  step(1'b1, 1'b0, 1'b0, 8'h22);
  step(1'b1, 1'b0, 1'b0, 8'h33);
  step(1'b1, 1'b0, 1'b0, 8'h44);  // Full after this push.
  step(1'b1, 1'b0, 1'b0, 8'h55);  // Push full: ignored.
  step(1'b1, 1'b1, 1'b0, 8'h66);  // Full push/pop: replace top.
  step(1'b1, 1'b1, 1'b1, 8'h99);  // Flush wins over push/pop.
  step(1'b0, 1'b1, 1'b0, 8'h00);  // Pop empty after flush: ignored.
  step(1'b1, 1'b0, 1'b0, 8'h21);
  step(1'b1, 1'b0, 1'b0, 8'h32);
  step(1'b0, 1'b1, 1'b0, 8'h00);
  step(1'b0, 1'b1, 1'b0, 8'h00);
  step(1'b1, 1'b1, 1'b0, 8'h88);  // Empty push/pop: acts like push.

  @(negedge clk);
  push = 1'b0;
  pop = 1'b0;
  flush = 1'b0;
  push_data = {WIDTH{1'b0}};
  #1;
  check_ref;

  $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule
