
/*
This module is a 3 bit adder. This module computes total_offset = prefix_num + has_modrm + has_sib

Delay: 
0.35 + 0.35 + 0.3 = 1 ns for modrm and sib calculation. Modrm signal is ready at 4.2ns + 1ns to execute is done at 5.2ns 
with temp_sum. Then has_sib has already arrived by then and can spend 1 ns executing 5.2 + 1ns = 6.2ns total delay for total_offset

*/

module prefix_modrm_sib_adder (
    input wire [1:0] prefix_num,
    input wire has_modrm, //ready at 4.2ns
    input wire has_sib, //ready at 4.55ns
    output wire [2:0] total_offset
);

    wire [3:0] total_offset_dummy;
    assign total_offset  = total_offset_dummy[2:0];
    rom4b32w$ ROM_prefix_modrm_sib_adder (.A({1'b0, prefix_num, has_modrm, has_sib}), .OE(1'b1), .DOUT(total_offset_dummy));

    initial begin
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_prefix_modrm_sib_adder.data", ROM_prefix_modrm_sib_adder.mem);
    end

endmodule