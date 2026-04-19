module logic_sib_disp(
    input wire [7:0] modrm_byte,
    output wire [2:0] disp_size_inbytes,
    output wire [1:0] disp_size,
    output wire [2:0] disp_plus_sib,
    output wire is_sib_true
);  
    wire [31:0] disp_plus_sib_dummy;
    assign disp_size_inbytes  = disp_plus_sib_dummy[7:5];
    assign disp_size          = disp_plus_sib_dummy[4:3];
    assign disp_plus_sib      = disp_plus_sib_dummy[2:0];
    assign is_sib_true        = disp_plus_sib_dummy[8];
    rom32b32w$ ROM_MODRM_TO_DISP_SIB_LEN (.A({modrm_byte[7:6], modrm_byte[2:0]}), .OE(1'b1), .DOUT(disp_plus_sib_dummy));

    initial begin
        $readmemh("/home/ecelrc/students/var2427/MICROARCH/project/hdl/rom/rom_mrm_to_disp_sib_len.data", ROM_MODRM_TO_DISP_SIB_LEN.mem);
    end

endmodule
