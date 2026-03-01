`timescale 1ns / 1ps

module tb_logic_modrm_imm();

    // Inputs
    reg [7:0] opcode;
    reg ext;
    reg op_size;

    // Outputs
    wire is_modrm;
    wire [2:0] imm_size_inbytes;
    wire [2:0] sum_modrm_imm;
    wire is_far_br;

    // Instantiate the Unit Under Test (UUT)
    logic_modrm_imm UUT (
        .opcode(opcode), 
        .ext(ext), 
        .op_size(op_size), 
        .is_modrm(is_modrm), 
        .imm_size_inbytes(imm_size_inbytes), 
        .sum_modrm_imm(sum_modrm_imm), 
        .is_far_br(is_far_br)
    );

    integer i;

    initial begin
        // -----------------------------------------------------------
        // TEST 1: RAW MEMORY DUMP
        // Use hierarchical paths to look directly inside the ROMs
        // -----------------------------------------------------------
        $display("==================================================");
        $display("   DUMPING ROM_STD_LO (Opcodes 0x00 to 0x7F)      ");
        $display("==================================================");
        // Wait 1ns to ensure readmemh has finished loading
        #1; 
        for (i = 0; i < 32; i = i + 1) begin
            // UUT = your module, ROM_STD_LO = the instance, mem = the reg array
            $display("Row %02d (Opcodes %02X-%02X): %08X", 
                      i, (i*4), (i*4)+3, UUT.ROM_STD_LO.mem[i]);
        end

        $display("\n==================================================");
        $display("   DUMPING ROM_STD_HI (Opcodes 0x80 to 0xFF)      ");
        $display("==================================================");
        for (i = 0; i < 32; i = i + 1) begin
            $display("Row %02d (Opcodes %02X-%02X): %08X", 
                      i, (i*4)+8'h80, (i*4)+8'h83, UUT.ROM_STD_HI.mem[i]);
        end

        // -----------------------------------------------------------
        // TEST 2: FUNCTIONAL DECODE VERIFICATION
        // -----------------------------------------------------------
        $display("\n==================================================");
        $display("   FUNCTIONAL TEST: SWEEPING OPCODES 0x00 TO 0xFF ");
        $display("==================================================");
        
        // Set state to Standard (no prefixes)
        ext = 0;
        op_size = 0;

        for (i = 0; i < 256; i = i + 1) begin
            opcode = i;
            
            // Wait 5ns for signals to propagate through the ROMs and MUXes
            #5; 
            
            $display("Opcode: %02X | Extracted Byte: %b | MRM: %b | IMM_SIZE: %d | SUM: %d | FAR_BR: %b", 
                      opcode, UUT.info_byte, is_modrm, imm_size_inbytes, sum_modrm_imm, is_far_br);
        end

        $display("\nSimulation Complete.");
        $finish;
    end
      
endmodule