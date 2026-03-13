module ucoderom #(
    parameter MEMFILE=""
)(
    input   [7:0] opcode,
    output  [63:0] sig
); 
    reg [63:0] ucode_mem[255:0];
    wire [63:0] rom00, rom01, rom02, rom03, rom04, rom05, rom06, rom07;
    rom64b32w$ ucoderom00(opcode[4:0], 1'b1, rom00);
    rom64b32w$ ucoderom01(opcode[4:0], 1'b1, rom01);
    rom64b32w$ ucoderom02(opcode[4:0], 1'b1, rom02);
    rom64b32w$ ucoderom03(opcode[4:0], 1'b1, rom03);
    rom64b32w$ ucoderom04(opcode[4:0], 1'b1, rom04);
    rom64b32w$ ucoderom05(opcode[4:0], 1'b1, rom05);
    rom64b32w$ ucoderom06(opcode[4:0], 1'b1, rom06);
    rom64b32w$ ucoderom07(opcode[4:0], 1'b1, rom07);

    integer i;
    initial begin
        // $display("Loading %0s.", MEMFILE);
        $readmemb(MEMFILE, ucode_mem);
        for (i=0; i<32; i=i+1) begin 
            ucoderom00.mem[i]=ucode_mem[i];
            ucoderom01.mem[i]=ucode_mem[32+i];
            ucoderom02.mem[i]=ucode_mem[64+i];
            ucoderom03.mem[i]=ucode_mem[96+i];
            ucoderom04.mem[i]=ucode_mem[128+i];
            ucoderom05.mem[i]=ucode_mem[160+i];
            ucoderom06.mem[i]=ucode_mem[192+i];
            ucoderom07.mem[i]=ucode_mem[224+i];
        end
    end

    mux8 mux8_sig[63:0](sig, rom00, rom01, rom02, rom03, rom04, rom05, rom06, rom07, opcode[5], opcode[6], opcode[7]);
endmodule