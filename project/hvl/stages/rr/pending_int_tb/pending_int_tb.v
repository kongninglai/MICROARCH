module pending_int_tb;

initial begin
  // $vcdplusfile("pending_int_tb.dump.vpd");
  // $vcdpluson(0, pending_int_tb); 
end

reg clk;
reg rst_n;
reg set_int;
reg clear_int;
wire pending_int_bh, pending_int;

pending_int_bh REF(
    .clk(clk),
    .rst_n(rst_n),
    .set_int(set_int),
    .clear_int(clear_int),
    .pending_int(pending_int_bh)
); 

pending_int DUT(
    .clk(clk),
    .rst_n(rst_n),
    .set_int(set_int),
    .clear_int(clear_int),
    .pending_int(pending_int)
); 

initial clk = 1'b0;
always #5 clk = ~clk;

integer FAILURES  = 0;
integer SUCCESSES = 0;

task clear_inputs;
begin
    set_int      = 1'b0;
    clear_int  = 1'b0;
end
endtask

task check_output;
        input expected;
        input [255:0] test_name;
begin
    #1; // wait a delta after posedge
    if (pending_int_bh !== expected) begin
        $display("[FAIL] %0s: expected pending_int_bh=%0b, got=%0b at time=%0t",
                    test_name, expected, pending_int_bh, $time);
        FAILURES = FAILURES + 1;
    end else if (pending_int_bh !== pending_int) begin 
        $display("[FAIL] %0s: expected pending_int_bh=%0b, got pending_int=%0b at time=%0t",
                    test_name, pending_int_bh, pending_int, $time);
        FAILURES = FAILURES + 1;
    end else begin
        SUCCESSES = SUCCESSES + 1;
    end
end
endtask

task pulse_interrupt;
    begin
        @(negedge clk);
        set_int = 1'b1;
        @(negedge clk);
        set_int = 1'b0;
    end
    endtask

task pulse_ack;
begin
    @(negedge clk);
    clear_int = 1'b1;
    @(negedge clk);
    clear_int = 1'b0;
end
endtask

initial begin
    FAILURES = 0;
    SUCCESSES = 0;

    clear_inputs();
    rst_n = 1'b0;

    // reset
    repeat (2) @(posedge clk);
    check_output(1'b0, "reset keeps int_pending=0");

    rst_n = 1'b1;
    @(posedge clk);
    check_output(1'b0, "after reset release, int_pending=0");

    // -----------------------------------
    // Test 1: single interrupt sets pending
    // -----------------------------------
    pulse_interrupt();
    @(posedge clk);
    check_output(1'b1, "interrupt sets int_pending");

    // -----------------------------------
    // Test 2: hold state when no input
    // -----------------------------------
    @(posedge clk);
    check_output(1'b1, "int_pending holds at 1 without ack");

    // -----------------------------------
    // Test 3: ack clears pending
    // -----------------------------------
    pulse_ack();
    @(posedge clk);
    check_output(1'b0, "ack clears int_pending");

    // -----------------------------------
    // Test 4: ack when already 0 stays 0
    // -----------------------------------
    pulse_ack();
    @(posedge clk);
    check_output(1'b0, "ack when already 0 keeps int_pending=0");

    // -----------------------------------
    // Test 5: two interrupts still keep pending=1
    // -----------------------------------
    pulse_interrupt();
    @(posedge clk);
    check_output(1'b1, "first interrupt sets pending");

    pulse_interrupt();
    @(posedge clk);
    check_output(1'b1, "second interrupt keeps pending=1");

    // -----------------------------------
    // Test 6: same-cycle interrupt and ack
    // expected: set wins over clear
    // -----------------------------------
    @(negedge clk);
    set_int     = 1'b1;
    clear_int   = 1'b1;
    @(posedge clk);
    check_output(1'b1, "same-cycle interrupt+ack => set wins");

    @(negedge clk);
    set_int     = 1'b0;
    clear_int   = 1'b0;

    // -----------------------------------
    // Test 7: clear after same-cycle set/ack
    // -----------------------------------
    pulse_ack();
    @(posedge clk);
    check_output(1'b0, "ack clears pending after same-cycle set/ack");

    // -----------------------------------
    // Test 8: reset clears pending even if it was 1
    // -----------------------------------
    pulse_interrupt();
    @(posedge clk);
    check_output(1'b1, "interrupt sets pending before reset");

    @(negedge clk);
    rst_n = 1'b0;
    @(posedge clk);
    check_output(1'b0, "reset clears pending from 1 to 0");

    @(negedge clk);
    rst_n = 1'b1;
    clear_inputs();
    @(posedge clk);
    check_output(1'b0, "after second reset release, int_pending=0");

    $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
    $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

    $finish;
end

endmodule