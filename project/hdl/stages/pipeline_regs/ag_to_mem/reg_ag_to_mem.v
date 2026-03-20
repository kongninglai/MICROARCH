module reg_ag_to_mem(CLK, Din, Q, QBAR, CLR, PRE,en);
    input  CLK;
    input  CLR;
    input [716:0] Din;
    input  PRE;
    input  en;
    output [716:0] Q;
    output [716:0] QBAR;

    wire [735:0] din_padded, q_padded, qbar_padded;
    assign din_padded = {19'b0, Din};
    assign Q = q_padded[716:0];
    assign QBAR = qbar_padded[716:0];
    
    genvar i;
    generate
        for (i = 0; i < 11; i=i+1) begin 
            reg64e$ reg64_inst(CLK, din_padded[i*64+63:i*64], q_padded[i*64+63:i*64], qbar_padded[i*64+63:i*64], CLR, PRE,en);
        end
    endgenerate 
    reg32e$ reg32_inst(CLK, din_padded[735:704], q_padded[735:704], qbar_padded[735:704], CLR, PRE,en);
endmodule