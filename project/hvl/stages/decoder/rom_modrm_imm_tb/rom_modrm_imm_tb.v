`timescale 1ns / 1ps

module tb_logic_modrm_imm();

    // 1. UUT Signals
    reg [7:0] opcode;
    reg ext;
    reg op_size;
    wire is_modrm;
    wire [2:0] imm_size_inbytes;
    wire [2:0] sum_modrm_imm;
    wire is_far_br;

    // 2. Golden Model Arrays (32 rows each used, 64 entries declared to be safe)
    reg [31:0] golden_std_lo     [0:63];
    reg [31:0] golden_oso_lo     [0:63];
    reg [31:0] golden_ext_lo     [0:63];
    reg [31:0] golden_ext_oso_lo [0:63];
    
    reg [31:0] golden_std_hi     [0:63];
    reg [31:0] golden_oso_hi     [0:63];
    reg [31:0] golden_ext_hi     [0:63];
    reg [31:0] golden_ext_oso_hi [0:63];

    // 3. Instantiate the Unit Under Test (UUT)
    logic_modrm_imm uut (
        .opcode(opcode), 
        .ext(ext), 
        .op_size(op_size),
        .is_modrm(is_modrm), 
        .imm_size_inbytes(imm_size_inbytes),
        .sum_modrm_imm(sum_modrm_imm), 
        .is_far_br(is_far_br)
    );

    //Error Tracking
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    // 4. Test Variables
    integer i_op, i_ext, i_sz;
    integer error_count;
    reg [31:0] current_row;
    reg [7:0]  expected_byte;
    wire [7:0] hardware_result;

    // Helper to package UUT outputs for easy comparison
    assign hardware_result = {is_modrm, imm_size_inbytes, sum_modrm_imm, is_far_br};

    initial begin
        error_count = 0;

        // 5. Load All 8 Files
<<<<<<< HEAD
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_std_lo.data",     golden_std_lo);
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_std_hi.data",     golden_std_hi);
        
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_oso_lo.data",     golden_oso_lo);
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_oso_hi.data",     golden_oso_hi);
        
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_ext_lo.data",     golden_ext_lo);
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_ext_hi.data",     golden_ext_hi);
        
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_ext_oso_lo.data", golden_ext_oso_lo);
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hdl/rom/rom_ext_oso_hi.data", golden_ext_oso_hi);
=======
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_std_lo.data",     golden_std_lo);
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_std_hi.data",     golden_std_hi);
        
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_oso_lo.data",     golden_oso_lo);
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_oso_hi.data",     golden_oso_hi);
        
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_ext_lo.data",     golden_ext_lo);
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_ext_hi.data",     golden_ext_hi);
        
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_ext_oso_lo.data", golden_ext_oso_lo);
        $readmemh("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/rom/rom_ext_oso_hi.data", golden_ext_oso_hi);
>>>>>>> origin/main

        #10; // Wait for load
        
        $display("---------------------------------------------------------");
        $display("STARTING EXHAUSTIVE PREDECODER SELF-CHECK (1024 TESTS)");
        $display("---------------------------------------------------------");

        // 6. Triple Nested Loop
        for (i_ext = 0; i_ext < 2; i_ext = i_ext + 1) begin
            for (i_sz = 0; i_sz < 2; i_sz = i_sz + 1) begin
                for (i_op = 0; i_op < 256; i_op = i_op + 1) begin
                    
                    // Apply Inputs
                    ext = i_ext;
                    op_size = i_sz;
                    opcode = i_op;

                    // A. Select Row: use opcode[7] to choose between LO and HI arrays
                    // Addresses [6:2] because each array is 32 rows deep
                    case({opcode[7], ext, op_size})
                        3'b000: current_row = golden_std_lo[opcode[6:2]];
                        3'b001: current_row = golden_oso_lo[opcode[6:2]];
                        3'b010: current_row = golden_ext_lo[opcode[6:2]];
                        3'b011: current_row = golden_ext_oso_lo[opcode[6:2]];
                        3'b100: current_row = golden_std_hi[opcode[6:2]];
                        3'b101: current_row = golden_oso_hi[opcode[6:2]];
                        3'b110: current_row = golden_ext_hi[opcode[6:2]];
                        3'b111: current_row = golden_ext_oso_hi[opcode[6:2]];
                    endcase

                    // B. Extract Byte: Bits [1:0] pick the byte in the row
                    case(opcode[1:0])
                        2'b00: expected_byte = current_row[7:0];
                        2'b01: expected_byte = current_row[15:8];
                        2'b10: expected_byte = current_row[23:16];
                        2'b11: expected_byte = current_row[31:24];
                    endcase

                    #5; // Wait for gate delays

                    // Automated check
                    if (hardware_result !== expected_byte) begin
                        $display("[FAIL] BANK:{ext:%b, sz:%b} OP:%h | HW:%b | EXP:%b", 
                                 ext, op_size, opcode, hardware_result, expected_byte);
                        error_count = error_count + 1;
                        FAILURES = FAILURES + 1;
                    end
                    else begin
                        SUCCESSES = SUCCESSES + 1;
                    end
                end
            end
        end

        // 7. Summary
        $display("---------------------------------------------------------");
        if (error_count == 0) begin
            $display("TEST RESULT: PASSED");
            $display("All 1024 combinations perfectly match the ROM data.");
        end else begin
            $display("TEST RESULT: FAILED");
            $display("Total Errors Found: %d", error_count);
        end
        $display("---------------------------------------------------------");

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule