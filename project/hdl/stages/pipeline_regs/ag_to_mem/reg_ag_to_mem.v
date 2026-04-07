module reg_ag_to_mem #(
    parameter REG_SIZE=757
)(CLK, Din, Q, QBAR, CLR, PRE,en);
    input  CLK;
    input  CLR;
    input [REG_SIZE-1:0] Din;
    input  PRE;
    input  en;
    output [REG_SIZE-1:0] Q;
    output [REG_SIZE-1:0] QBAR;

    wire [767:0] din_padded, q_padded, qbar_padded;
    assign din_padded = {11'b0, Din};
    assign Q = q_padded[REG_SIZE-1:0];
    assign QBAR = qbar_padded[REG_SIZE-1:0];
    
    genvar i;
    generate
        for (i = 0; i < 12; i=i+1) begin 
            reg64e$ reg64_inst(CLK, din_padded[i*64+63:i*64], q_padded[i*64+63:i*64], qbar_padded[i*64+63:i*64], CLR, PRE,en);
        end
    endgenerate 
endmodule