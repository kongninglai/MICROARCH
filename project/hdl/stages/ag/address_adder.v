module address_adder(
    input [1:0] scale_mux1,
    input [15:0] sreg1,
    input [31:0] index1,
    input [31:0] base1,
    input [1:0] size_mux,
    input [31:0] disp1,
    output [31:0] addr1,
    output [31:0] offset1,

    input stack_push,
    input ret_with_imm,
    input [31:0] imm,
    input [15:0] sreg2,
    input [31:0] base2,
    output [31:0] addr2,
    output [31:0] offset2,
    output [31:0] inc_esp,
    output [31:0] dec_esp
);  
    // ======= ADDR1 =========
    // scale_mux=0/1/2/3: index x1, index x2, index x4, index x8
    // size_mux=0/1/2/3: datasize = 0, 1, 3, 7
    // addr = ({sreg, 16'b0} + scaled_index) + (base + disp)
    // offset = (datasize-1 + scaled_index) + (base + disp)
    wire [31:0] shifted_sreg1;
    assign shifted_sreg1 = {sreg1, 16'b0};
    wire [31:0] index1_x2, index1_x4, index1_x8, scaled_index1;
    wire [31:0] scaled_index1_buf16;
    bufferH16$  bufferH16$_scaled_index1[31:0](scaled_index1_buf16, scaled_index1);
    lshf_const #(.WIDTH(32), .SHF_AMT(1)) lshf_index_1(.in(index1), .out(index1_x2));
    lshf_const #(.WIDTH(32), .SHF_AMT(2)) lshf_index_2(.in(index1), .out(index1_x4));
    lshf_const #(.WIDTH(32), .SHF_AMT(3)) lshf_index_3(.in(index1), .out(index1_x8));
    mux4_32 mux_shifted_index(scaled_index1, index1, index1_x2, index1_x4, index1_x8, scale_mux1[0], scale_mux1[1]);

    wire [31:0] datasize, datasize_buf16;
    wire [1:0]  size_mux_buf16;
    bufferH16$  bufferH16$_size_mux_buf16[1:0](size_mux_buf16, size_mux);
    mux4_32 mux_datasize(datasize, 32'h0, 32'h1, 32'h3, 32'h7, size_mux_buf16[0], size_mux_buf16[1]);
    bufferH16$  bufferH16$_datasize_buf16[31:0](datasize_buf16, datasize);

    wire [31:0] sum_sreg1_index1, sum_base1_disp1, sum_index1_size;
    wire [31:0] sum_base1_disp1_buf16;
    bufferH16$  bufferH16$_sum_base1_disp1_buf16[31:0](sum_base1_disp1_buf16, sum_base1_disp1);
    PA_32b PA_sreg_index(.s(sum_sreg1_index1), .in0(scaled_index1_buf16), .in1(shifted_sreg1));
    PA_32b PA_base_disp(.s(sum_base1_disp1), .in0(base1), .in1(disp1));
    PA_32b PA_index_size(.s(sum_index1_size), .in0(scaled_index1_buf16), .in1(datasize_buf16));

    PA_32b PA_addr1(.s(addr1), .in0(sum_sreg1_index1), .in1(sum_base1_disp1_buf16));
    PA_32b PA_offset1(.s(offset1), .in0(sum_index1_size), .in1(sum_base1_disp1_buf16));

    // ======= ADDR1 =========
    // if stack_push: 
    //      addr = (base-datasize) + {sreg, 16'b0}
    //      offset = base + (datasize-1)
    // else:
    //      addr = (base-0) + {sreg, 16'b0}
    //      offset = base + (datasize-1)
    wire [31:0] shifted_sreg2;
    assign shifted_sreg2 = {sreg2, 16'b0};

    wire [31:0] esp_dec_size, esp_inc_size;
    mux4_32 mux_esp_dec_size(esp_dec_size, 32'hFFFFFFFF, 32'hFFFFFFFE, 32'hFFFFFFFC, 32'hFFFFFFF8, size_mux_buf16[0], size_mux_buf16[1]);
    mux4_32 mux_esp_inc_size(esp_inc_size, 32'h1, 32'h2, 32'h4, 32'h8, size_mux_buf16[0], size_mux_buf16[1]);

    wire [31:0] sum_esp_dec, sum_esp_inc;
    PA_32b PA_base2_dec(.s(sum_esp_dec), .in0(base2), .in1(esp_dec_size));
    PA_32b PA_base2_inc(.s(sum_esp_inc), .in0(base2), .in1(esp_inc_size));

    wire [31:0] imm_ret, sum_esp_inc_imm;
    mux2_32 mux_imm(imm_ret, 32'b0, imm, ret_with_imm);
    PA_32b PA_esp_inc_imm(.s(sum_esp_inc_imm), .in0(sum_esp_inc), .in1(imm_ret));

    wire [31:0] sum_base2, sum_base2_buf16;
    mux2_32 mux_base2(sum_base2, base2, sum_esp_dec, stack_push);
    bufferH16$  bufferH16$_sum_base2_buf16[31:0](sum_base2_buf16, sum_base2);

    PA_32b PA_addr2(.s(addr2), .in0(sum_base2_buf16), .in1(shifted_sreg2));
    PA_32b PA_offset2(.s(offset2), .in0(sum_base2_buf16), .in1(datasize_buf16));
    assign inc_esp = sum_esp_inc_imm;
    assign dec_esp = sum_esp_dec;

    // TODO: NEED TO FIX RET with imm, where esp is incremented by imm16

endmodule