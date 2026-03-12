module reg_rr_to_ag(CLK, Din, Q, QBAR, CLR, PRE,en);
    input  CLK;
    input  CLR;
    input [638:0] Din;
    input  PRE;
    input  en;
    output [638:0] Q;
    output [638:0] QBAR;

    wire [639:0] din_padded, q_padded, qbar_padded;
    assign din_padded = {1'b0, Din};
    assign Q = q_padded[638:0];
    assign QBAR = qbar_padded[638:0];
    
    genvar i;
    generate
        for (i = 0; i < 10; i=i+1) begin 
            reg64e$ reg64_inst(CLK, din_padded[i*64+63:i*64], q_padded[i*64+63:i*64], qbar_padded[i*64+63:i*64], CLR, PRE,en);
        end
    endgenerate 
endmodule