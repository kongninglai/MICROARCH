module tag_hit_logic_tb;

initial begin
  $vcdplusfile("tag_hit_logic_tb.dump.vpd");
  $vcdpluson(0, tag_hit_logic_tb);
end

localparam NUM_WAYS  = 4;
localparam TAG_WIDTH = 8;
localparam WAY_WIDTH = $clog2(NUM_WAYS);

reg  [NUM_WAYS*TAG_WIDTH-1:0] tag_store_out;
reg  [TAG_WIDTH-1:0]          tag_compare_val;

wire tag_hit, tag_hit_exp;
wire [WAY_WIDTH-1:0] tag_hit_way, tag_hit_way_exp;

tag_hit_logic DUT(
  .tag_store_out(tag_store_out),
  .tag_compare_val(tag_compare_val),
  .tag_hit(tag_hit),
  .tag_hit_way(tag_hit_way)
);

tag_hit_logic_behav REF(
  .tag_store_out(tag_store_out),
  .tag_compare_val(tag_compare_val),
  .tag_hit(tag_hit_exp),
  .tag_hit_way(tag_hit_way_exp)
);

integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
begin
  if ((tag_hit !== tag_hit_exp) || (tag_hit_way !== tag_hit_way_exp)) begin
    FAILURES = FAILURES + 1;
    $display("FAILURE AT TIME %t", $time);
    $display("  tag_store_out = %h", tag_store_out);
    $display("  tag_compare_val = %h", tag_compare_val);
    $display("  DUT -> tag_hit = %b, tag_hit_way = %b", tag_hit, tag_hit_way);
    $display("  REF -> tag_hit = %b, tag_hit_way = %b\n", tag_hit_exp, tag_hit_way_exp);
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
end
endtask

integer i, j;
reg [TAG_WIDTH-1:0] used_tags[NUM_WAYS-1:0];
reg [TAG_WIDTH-1:0] new_tag;

integer t;
reg [TAG_WIDTH-1:0] rand_tag;

task generate_unique_tags;
integer found, k;
begin
  for (i = 0; i < NUM_WAYS; i = i + 1) begin
    found = 1;
    while (found) begin
      new_tag = $random;
      found = 0;
      for (k = 0; k < i; k = k + 1) begin
        if (new_tag == used_tags[k])
          found = 1;
      end
    end
    used_tags[i] = new_tag;
    tag_store_out[i*TAG_WIDTH +: TAG_WIDTH] = new_tag;
  end
end
endtask

initial begin
  for (i = 0; i < NUM_WAYS; i = i + 1) used_tags[i] = 0;
  tag_store_out = 0;
  tag_compare_val = 0;

  for (j = 0; j < 16; j = j + 1) begin
    generate_unique_tags();
    for (i = 0; i < NUM_WAYS; i = i + 1) begin
      tag_compare_val = tag_store_out[i*TAG_WIDTH +: TAG_WIDTH];
      #5;
      check();
    end

    tag_compare_val = 8'hFF;
    #5;
    check();
  end

  for (t = 0; t < 1024; t = t + 1) begin
    generate_unique_tags();
    for (i = 0; i < NUM_WAYS; i = i + 1) begin
      tag_compare_val = tag_store_out[i*TAG_WIDTH +: TAG_WIDTH];
      #5;
      check();
    end
    rand_tag = $random;
    while (|{(used_tags[0] == rand_tag),(used_tags[1] == rand_tag),(used_tags[2] == rand_tag),(used_tags[3] == rand_tag)})
      rand_tag = $random;
    tag_compare_val = rand_tag;
    #5;
    check();
  end

  $display("FAILURES = %d out of %d", FAILURES, FAILURES + SUCCESSES);
  $display("SUCCESSES = %d out of %d", SUCCESSES, FAILURES + SUCCESSES);

  $finish;
end

endmodule