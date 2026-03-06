module logic_imm(
    input wire [87:0] cache_bits, //bytes 2-12 of the instruction cache
    input wire has_sib,
    input wire [2:0] prefix_num,
    input wire [1:0] imm_size, //ready at 3.04ns
    input wire is_far_br,
    output wire [31:0] imm_bytes
);  



endmodule