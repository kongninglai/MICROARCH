module  lshf_var_32b_tb;

initial begin
  $vcdplusfile("lshf_var_32b_tb.dump.vpd");
  $vcdpluson(0, lshf_var_32b_tb); 
end

localparam WIDTH = 32;

reg [1:0] scale_mux1;
reg [15:0] sreg1;
reg [31:0] index1;
reg [31:0] base1;
reg [1:0] size_mux;
reg [31:0] disp1;
wire [31:0] addr1;
wire [31:0] offset1;
reg stack_push;
reg ret_with_imm;
reg [31:0] imm;
reg [15:0] sreg2;
reg [31:0] base2;
wire [31:0] addr2;
wire [31:0] offset2;
wire [31:0] inc_esp;
wire [31:0] dec_esp;

wire [31:0] addr1_bh;
wire [31:0] offset1_bh;
wire [31:0] addr2_bh;
wire [31:0] offset2_bh;
wire [31:0] inc_esp_bh;
wire [31:0] dec_esp_bh;

task clear_inputs;
begin
        scale_mux1 = 2'd0;
        sreg1 = 16'd0;
        index1 = 32'd0;
        base1 = 32'd0;
        size_mux = 2'd0;
        disp1 = 32'd0;
        stack_push = 1'b0;
        ret_with_imm = 1'b0;
        imm = 32'b0;
        sreg2 = 16'd0;
        base2 = 32'd0;
end
endtask

task set_inputs;
  input [1:0] scale_mux1_i;
  input [15:0] sreg1_i;
  input [31:0] index1_i;
  input [31:0] base1_i;
  input [1:0] size_mux_i;
  input [31:0] disp1_i;
  input stack_push_i;
  input ret_with_imm_i;
  input [31:0] imm_i;
  input [15:0] sreg2_i;
  input [31:0] base2_i;
begin
        scale_mux1 = scale_mux1_i;
        sreg1 = sreg1_i;
        index1 = index1_i;
        base1 = base1_i;
        size_mux = size_mux_i;
        disp1 = disp1_i;
        stack_push = stack_push_i;
        ret_with_imm = ret_with_imm_i;
        imm = imm_i;
        sreg2 = sreg2_i;
        base2 = base2_i;
end
endtask

task print_outputs;
begin
        $display("addr1 = %0h, offset1 = %0h", addr1, offset1);
        $display("addr2 = %0h, offset2 = %0h, inc_esp = %0h, dec_esp = %0h", addr2, offset2, inc_esp, dec_esp);
end
endtask

task print_outputs_bh;
begin
        $display("addr1_bh = %0h, offset1_bh = %0h", addr1_bh, offset1_bh);
        $display("addr2_bh = %0h, offset2_bh = %0h, inc_esp_bh = %0h, dec_esp_bh = %0h", addr2_bh, offset2_bh, inc_esp_bh, dec_esp_bh);
end
endtask

address_adder dut (
    .scale_mux1(scale_mux1),
    .sreg1(sreg1),
    .index1(index1),
    .base1(base1),
    .size_mux(size_mux),
    .disp1(disp1),
    .addr1(addr1),
    .offset1(offset1),
    .stack_push(stack_push),
    .ret_with_imm(ret_with_imm),
    .imm(imm),
    .sreg2(sreg2),
    .base2(base2),
    .addr2(addr2),
    .offset2(offset2),
    .inc_esp(inc_esp),
    .dec_esp(dec_esp)
);

address_adder_bh dut_bh (
    .scale_mux1(scale_mux1),
    .sreg1(sreg1),
    .index1(index1),
    .base1(base1),
    .size_mux(size_mux),
    .disp1(disp1),
    .addr1(addr1_bh),
    .offset1(offset1_bh),
    .stack_push(stack_push),
    .ret_with_imm(ret_with_imm),
    .imm(imm),
    .sreg2(sreg2),
    .base2(base2),
    .addr2(addr2_bh),
    .offset2(offset2_bh),
    .inc_esp(inc_esp_bh),
    .dec_esp(dec_esp_bh)
);


integer FAILURES  = 0;
integer SUCCESSES = 0;

task check;
  if ({addr1, offset1, addr2, offset2, inc_esp, dec_esp} !== {addr1_bh, offset1_bh, addr2_bh, offset2_bh, inc_esp_bh, dec_esp_bh}) begin
    FAILURES = FAILURES + 1;
    $display("########FAILURE AT TIME %t.\n", 
              $time);
    print_outputs();
    print_outputs_bh();
  end else begin
    SUCCESSES = SUCCESSES + 1;
  end
endtask

initial begin
    clear_inputs();
    
    // addr1: 0x12(base1) + 0x34(index1) * 0x2(scale1) + 0x5678(disp1) + 0xaabb0000(sreg1) = 0xaabb56F2
    // offset1: 0x12(base1) + 0x34(index1) * 0x2(scale1) + 0x5678(disp1) + 0x7(datasize) = 0x56F9

    // addr2(push): 0x88(base2) - 0x8(stack_datasize) + 0xccdd0000(sreg2) = 0xccdd0080
    // offset2: 0x88(base2) - 0x8(stack_datasize) + 0x7(datasize) = 0x87
    set_inputs(2'b01, 16'haabb, 32'h34, 32'h12, 2'b11, 32'h5678, 1'b0, 1'b1, 32'h7700, 16'hccdd, 32'h88);
    #8;
    print_outputs();
    print_outputs_bh();
    repeat (1 << 8) begin
      #8; 
      check();
      set_inputs($random, $random, $random, $random, $random, $random, $random, $random, $random, $random, $random);
    end

    $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
    $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

  $finish;

end

endmodule