module shifter_tb;

initial begin
  $vcdplusfile("shifter_tb.dump.vpd");
  $vcdpluson(0, shifter_tb); 
end


reg clk, rst_n;
reg shift;
wire ready;
reg [3:0] instr_len;
reg [31:0] wr_en;
wire [127:0] outbytes;
reg [255:0] inbytes;

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

shift_reg shifter_dut(
    .clk(clk),
    .rst_n(rst_n),
    .shift(shift),
    .instr_len(instr_len),
    .inbytes(inbytes),
    .wr_en(wr_en),
    .outbytes(outbytes),
    .ready(ready)
);


// assign inbytes = {128'b0, bytes};

task apply_reset;
begin
    shift = 1'b0;
    wr_en = 32'b0;
    rst_n = 1'b0;
    instr_len = 4'b0;
    inbytes = 256'b0;
    repeat (2) @(posedge clk);
    rst_n = 1'b1;
end
endtask

task check;
begin
    $display("out bytes=%02h %02h %02h %02h %02h %02h %02h %02h %02h %02h %02h %02h %02h %02h %02h %02h", outbytes[7:0], outbytes[15:8], outbytes[23:16], outbytes[31:24], outbytes[39:32], outbytes[47:40], outbytes[55:48], outbytes[63:56], outbytes[71:64], outbytes[79:72], outbytes[87:80], outbytes[95:88], outbytes[103:96], outbytes[111:104], outbytes[119:112], outbytes[127:120]);
end
endtask

initial begin
    apply_reset();
    @(posedge clk);

    // Test 1:write 16 bytes into the register (from cache)
    wr_en = 32'h0000_ffff;
    inbytes = 256'hxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_0011_2233_4455_6677_8899_aabb_ccdd_eeff;
    @(posedge clk);
    #1
    check();

    // Test 2: Consume 13 bytes (3 bytes left)
    @(posedge clk);
    wr_en = 32'h0;
    shift = 1'b1;
    instr_len = 4'd13;

    @(posedge clk);
    shift = 1'b0;
    #1
    check();

    // Test 3: consume 1 byte, and write 16 bytes (3-1+16=18 bytes)
    @(posedge clk);
    shift = 1'b1;
    instr_len = 4'd1;
    wr_en = 32'h0007_fff8;
    inbytes = 256'hxxxx_xxxx_xxxx_xxxx_xx00_1122_3344_5566_7788_99aa_bbcc_ddee_ffxx_xxxx;
    @(posedge clk);
    shift = 1'b0;
    wr_en = 32'h0;
    #1
    check();

    // Test 4: consume 15 byte (18-15=3 bytes left)
    @(posedge clk);
    shift = 1'b1;
    instr_len = 4'd15;
    wr_en = 32'h0;
    inbytes = 256'hx;
    @(posedge clk);
    shift = 1'b0;
    #1
    check();
    
    $finish;
end

endmodule