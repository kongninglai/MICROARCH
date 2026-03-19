module address_adder_bh(
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
    // scale_mux=0/1/2/3: index x1, index x2, index x4, index x8
    // size_mux=0/1/2/3: datasize = 0, 1, 3, 7
    // addr = {sreg, 16'b0} + scaled_index + base + disp
    // offset = datasize-1 + scaled_index + base + disp
    wire [31:0] scaled_index1, shifted_sreg1;
    assign scaled_index1 = index1 << scale_mux1;
    
    reg [31:0] datasize;
    always @(*) begin 
        case (size_mux)
            2'b00: datasize = 32'h0;
            2'b01: datasize = 32'h1;
            2'b10: datasize = 32'h3;
            2'b11: datasize = 32'h7;
        endcase
    end
    assign shifted_sreg1 = {sreg1, 16'b0};

    assign addr1 = scaled_index1 + base1 + disp1 + shifted_sreg1;
    assign offset1 = scaled_index1 + base1 + disp1 + datasize;

    // ======= ADDR1 =========
    // if stack_push== push (1): 
    //      addr = (base-datasize) + {sreg, 16'b0}
    //      offset = base + (datasize-1)
    // else:
    //      addr = (base-0) + {sreg, 16'b0}
    //      offset = base + (datasize-1)

    reg [31:0] stack_datasize;
    always @(*) begin 
        case (size_mux)
            2'b00: stack_datasize = 32'h1;
            2'b01: stack_datasize = 32'h2;
            2'b10: stack_datasize = 32'h4;
            2'b11: stack_datasize = 32'h8;
        endcase
    end

    wire [31:0] imm_ret;
    assign imm_ret = ret_with_imm ? imm : 32'b0;

    assign inc_esp = base2 + stack_datasize+imm_ret;
    assign dec_esp = base2 - stack_datasize;

    wire [31:0] shifted_sreg2;
    assign shifted_sreg2 = {sreg2, 16'b0};

    assign offset2 = stack_push ? (base2-1) : (base2+datasize);
    assign addr2 = stack_push ? (base2 - stack_datasize) + shifted_sreg2 : (base2 + shifted_sreg2);

endmodule