module br_target(
    input wire [31:0] o_eip,
    output wire hit, //is this a branch that can be resolved in decode?
    output wire [31:0] bp_eip_target
);
    //Hardcode to not hit and provide dummy target (can be same as o_eip since it won't be used)
    assign hit = 1'b0;
    assign bp_eip_target = 32'h00000015; //HARDCODE FOR TB

endmodule