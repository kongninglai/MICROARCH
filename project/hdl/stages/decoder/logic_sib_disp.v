module logic_sib_disp(
    input wire [7:0] modrm_byte,
    output wire [2:0] disp_plus_sib
);  
    wire [3:0] disp_plus_sib_dummy;
    assign disp_plus_sib = disp_plus_sib_dummy[2:0];
    rom4b32w$ ROM_MODRM_TO_DISP_SIB_LEN (.A({modrm_byte[7:6], modrm_byte[2:0]}), .OE(1'b1), .DOUT(disp_plus_sib_dummy));

    initial begin
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_mrm_to_disp_sib_len.data", ROM_MODRM_TO_DISP_SIB_LEN.mem);
    end

endmodule
