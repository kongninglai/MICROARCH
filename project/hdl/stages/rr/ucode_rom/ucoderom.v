module ucoderom #(
    parameter MEMFILE64="",
    parameter MEMFILE32=""
)(
    input   [7:0] opcode,
    output  [95:0] sig
); 
    reg [63:0] ucode_mem64[255:0];
    reg [31:0] ucode_mem32[255:0];
    wire [63:0] rom00, rom01, rom02, rom03, rom04, rom05, rom06, rom07;
    wire [31:0] rom10, rom11, rom12, rom13, rom14, rom15, rom16, rom17;

    rom64b32w$ ucoderom00(opcode[4:0], 1'b1, rom00);
    rom64b32w$ ucoderom01(opcode[4:0], 1'b1, rom01);
    rom64b32w$ ucoderom02(opcode[4:0], 1'b1, rom02);
    rom64b32w$ ucoderom03(opcode[4:0], 1'b1, rom03);
    rom64b32w$ ucoderom04(opcode[4:0], 1'b1, rom04);
    rom64b32w$ ucoderom05(opcode[4:0], 1'b1, rom05);
    rom64b32w$ ucoderom06(opcode[4:0], 1'b1, rom06);
    rom64b32w$ ucoderom07(opcode[4:0], 1'b1, rom07);

    rom32b32w$ ucoderom10(opcode[4:0], 1'b1, rom10);
    rom32b32w$ ucoderom11(opcode[4:0], 1'b1, rom11);
    rom32b32w$ ucoderom12(opcode[4:0], 1'b1, rom12);
    rom32b32w$ ucoderom13(opcode[4:0], 1'b1, rom13);
    rom32b32w$ ucoderom14(opcode[4:0], 1'b1, rom14);
    rom32b32w$ ucoderom15(opcode[4:0], 1'b1, rom15);
    rom32b32w$ ucoderom16(opcode[4:0], 1'b1, rom16);
    rom32b32w$ ucoderom17(opcode[4:0], 1'b1, rom17);

    integer i;
    initial begin
        // $display("Loading %0s.", MEMFILE);
        $readmemb(MEMFILE64, ucode_mem64);
        $readmemb(MEMFILE32, ucode_mem32);
        for (i=0; i<32; i=i+1) begin 
            ucoderom00.mem[i]=ucode_mem64[i];
            ucoderom01.mem[i]=ucode_mem64[32+i];
            ucoderom02.mem[i]=ucode_mem64[64+i];
            ucoderom03.mem[i]=ucode_mem64[96+i];
            ucoderom04.mem[i]=ucode_mem64[128+i];
            ucoderom05.mem[i]=ucode_mem64[160+i];
            ucoderom06.mem[i]=ucode_mem64[192+i];
            ucoderom07.mem[i]=ucode_mem64[224+i];

            ucoderom10.mem[i]=ucode_mem32[i];
            ucoderom11.mem[i]=ucode_mem32[32+i];
            ucoderom12.mem[i]=ucode_mem32[64+i];
            ucoderom13.mem[i]=ucode_mem32[96+i];
            ucoderom14.mem[i]=ucode_mem32[128+i];
            ucoderom15.mem[i]=ucode_mem32[160+i];
            ucoderom16.mem[i]=ucode_mem32[192+i];
            ucoderom17.mem[i]=ucode_mem32[224+i];
        end
    end

    mux8_64 mux8_sig64(sig[95:32], rom00, rom01, rom02, rom03, rom04, rom05, rom06, rom07, opcode[5], opcode[6], opcode[7]);
    mux8_32 mux8_sig32(sig[31:0], rom10, rom11, rom12, rom13, rom14, rom15, rom16, rom17, opcode[5], opcode[6], opcode[7]);
endmodule