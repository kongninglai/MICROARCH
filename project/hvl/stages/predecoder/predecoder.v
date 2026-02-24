
//Pass in
module predecoder(
    input [127:0]  instr_bytes_in, // input instruction bytes (cache line size 16B)
    input [31:0] eip_in,    
    //input [15:0] instr_cnt,            
    output reg [2:0] prefix_mux_out,     // one-hot [segment, operand_size, rep]
    output reg ext_opcode,
    output reg [7:0] opcode,
    output reg [7:0] modrm,
    output reg [7:0] sib,
    output reg [31:0] disp,
    output reg disp_size_mux,       // 0 32-bit, 1 8-bit
    output reg [31:0] imm,
    output reg [1:0] imm_size_mux,  // 8, 16, 32, unused
    output reg [1:0] reg0_mux,      // zero val, modrm[2:0], sib[2:0], unused (2 bits)
    output reg [1:0] imm_type,      // reg, rel, double, unused (2 bits)
    output reg [3:0] instr_len      // max-length = 16 bytes

);

    //Functions
    function bit is_prefix_rep_fn;
        input [7:0] byte;
        begin
            is_prefix_rep_fn = (byte == 8'hF3);
        end
    endfunction

    function bit is_prefix_segover_fn;
        input [7:0] byte;
        begin
            is_prefix_segover_fn = (byte == 8'h66); //segment register override
        end
    endfunction

    function bit is_prefix_opsizeover_fn;
        input [7:0] byte;
        begin
            is_prefix_opsizeover_fn = (byte == 8'h26) || (byte == 8'h2E) || (byte == 8'h36) || (byte == 8'h3E) || (byte == 8'h64) || (byte == 8'h65); //operand size override
        end
    endfunction

    function bit is_prefix_ext_fn;
        input [7:0] byte;
        begin
            is_prefix_ext_fn = (byte == 8'h0F); //external opcode
        end
    endfunction

    function bit is_prefix_fn;
        input [7:0] byte;
        begin

            is_prefix_fn = is_prefix_rep_fn(byte)
                        || is_prefix_segover_fn(byte)
                        || is_prefix_opsizeover_fn(byte)
                        || is_prefix_ext_fn(byte);
        end
    endfunction

    //Detects All Prefixes for One Byte and Returns a One-Hot Encoding
    //[3:0] - Rep, OpSize, SegOver, ExtOp
    function [3:0] detect_prefixes_fn;
        input [7:0] byte; 

        begin
            detect_prefixes_fn = 4'b0000; //default
            detect_prefixes_fn[3] = is_prefix_rep_fn(byte);
            detect_prefixes_fn[2] = is_prefix_opsizeover_fn(byte);
            detect_prefixes_fn[1] = is_prefix_segover_fn(byte);
            detect_prefixes_fn[0] = is_prefix_ext_fn(byte);
        end
    endfunction

    //Opcode input into the function should not contain 0x0F byte and should only contain the main byte of the opcode
    function bit needs_modrm_fn;
        input [7:0] opcode,
        input ext_opcode;
        begin
            if (ext_opcode == 2'b1) begin
                case(opcode)
                    8'h42, 8'h63, 8'h6B, 8'h68, 8'h69, 
                    8'h6F, 8'h7F, 8'hB0, 8'hB1, 8'hBC, 
                    8'hFD, 8'hFE, 8'hE0, 8'hE3: begin
                        needs_modrm_fn = 1;
                    end
                    default: begin
                        needs_modrm_fn = 0;
                    end
                endcase
            end

            else begin
                case(opcode)
                    8'h00, 8'h01, 8'h02, 8'h03,
                    8'h08, 8'h09, 8'h0A, 8'h0B,
                    8'h20, 8'h21, 8'h22, 8'h23,
                    8'h80, 8'h81, 8'h83, 8'h86,
                    8'h87, 8'h88, 8'h89, 8'h8A,
                    8'h8B, 8'h8C, 8'h8E, 8'h8F,
                    8'hC0, 8'hC1, 8'hC6, 8'hC7,
                    8'hD0, 8'hD1, 8'hD2, 8'hD3,
                    8'hF6, 8'hF7, 8'hFF, 8'h11, 
                    8'h13, 8'h19, 8'h1B: begin
                        needs_modrm_fn = 1;
                    end
                    default: begin
                        needs_modrm_fn = 0;
                    end
                endcase
            end
        end
    endfunction

    //Returns a boolean on whether a certain opcode uses the SIB byte
    function bit needs_sib_fn;
        input [7:0] modrm;
        reg [1:0] mod;
        reg [2:0] reg;
        reg [2:0] rm;

        begin
            mod = modrm[7:6];
            reg = modrm[5:3];
            rm = modrm[2:0];

            needs_sib_fn = (rm == 3'b100) && (mod != 2'b11); //indicates SIB byte if true
        end
    endfunction

    //Returns displacement size in bytes (0, 1, 4) for a given modrm for some opcode 
    //(No address override prefix, so no 2 byte displacement)
    function [1:0] disp_num_fn;
        input [7:0] modrm,
        input [7:0] sib;
        reg [1:0] mod;
        reg [2:0] reg;
        reg [2:0] rm;
        reg [2:0] sib_bits;

        begin
            mod = modrm[7:6];
            reg = modrm[5:3];
            rm = modrm[2:0];
            sib_bits = sib[2:0];

            if (mod == 2'b01) begin
                disp_num_fn = 2'b01; //1-byte
            end
            else if (mod == 2'b10) || (mod == 2'b00 && rm == 3'b101) begin
                disp_num_fn = 2'b10; //4-byte
            end
            else begin
                disp_num_fn = 2'b00; //no displacement
            end
        end
    endfunction

    function [2:0] imm_num_fn;
        input [7:0] opcode,
        input ext_opcode,
        input op_size_prefix;

        //Handles 2-byte opcode
        if (ext_opcode == 1'b1) begin
            case (opcode)
                8'h85, 8'h87: begin
                if (op_size_prefix == 1'b1) begin
                    imm_num_fn = 3'b010; //2-byte immediate
                end
                else begin
                    imm_num_fn = 3'b100; //4-byte immediate
                end
            endcase
        end

        //Handles 1-byte opcode
        else begin
            if (opcode[7:3] == 8'hB0) begin
                imm_num_fn = 3'b001; //1-byte immediate
            end
            else if (opcode[7:3] == 8'hB8) begin //2-byte /4-byte immediate
                if (op_size_prefix == 1'b1) begin
                    imm_num_fn = 3'b010; //2-byte
                end
                else begin
                    imm_num_fn = 3'b100; //4-byte
                end
            end
            case (opcode)

                8'h04,   // ADD AL, imm8
                8'h0C,   // OR  AL, imm8
                8'h24,   // AND AL, imm8
                8'h6A,   // PUSH imm8
                8'h75,   // JNZ rel8
                8'h77,   // JA  rel8
                8'h80,   // GRP1 r/m8, imm8
                8'h83,   // GRP1 r/m16/32, imm8 (sign-extended)
                8'hB0,
                8'hC0,   // GRP2 r/m8, imm8
                8'hC1:   // GRP2 r/m16/32, imm8
                8'hC6,   // MOV r/m8, imm8
                8'hEB:   // JMP rel8
                    imm_num_fn = 3'b001; //1-byte

                8'hC2, 
                8'hCA:
                    imm_num_fn = 3'b010; //2-byte

                8'h05,   // ADD EAX, imm
                8'h0D,   // OR  EAX, imm
                8'h25,   // AND EAX, imm
                8'h68,   // PUSH imm
                8'h81,   // GRP1 r/m16/32, imm
                8'hC7,   // MOV r/m16/32, imm
                8'hE8,   // CALL rel
                8'hE9,   // JMP  rel
                8'h9A,
                8'hEA:
                begin

                    // Operand-size–dependent immediate
                    if (operand_size_prefix == 1'b1) begin
                        imm_num_fn = 3'b010; //2-byte
                    end
                    else begin
                        imm_num_fn = 3'b100; //4-byte
                    end
                end

                default: begin
                    imm_num_fn = 0;
                end
                
            endcase
            
        end
    endfunction


    // IMM_REGULAR = 2'b00
    // IMM_REL     = 2'b01
    // IMM_DOUBLE  = 2'b10
    // IMM_UNUSED  = 2'b11    
    function [2:0] imm_type_fn;
        input [7:0] opcode,
        input ext_opcode,
        input op_size_prefix;
        reg [1:0] imm_type;

        //Initialize
        imm_type = 2'b00; //IMM_REGULAR
        
        //Handles 2-byte opcode
        if (ext_opcode == 1'b1) begin
            case (opcode)
                8'h85, 8'h87: begin
                    imm_type = 2'b01; //IMM_REL
                end
            endcase
        end


        //Handles 1-byte opcode
        else begin

            if ((opcode == 8'h75) || (opcode == 8'h77) || (opcode == 8'hEB) || (opcode == 8'hE8) || (opcode == 8'hE9)) begin
                imm_type = 2'b01; //IMM_REL
            end
            else if ((opcode == 8'h9A) || (opcode == 8'hEA)) begin
                imm_type = 2'b10; //IMM_DOUBLE
            end
            default: begin
                imm_type = 2'b00; //IMM_REGULAR
            end
              
        end
    endfunction

    //Break cache line into accessible bytes
    wire [7:0] byte [15:0];

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin
            assign byte[i] = input_line[8*i +: 8];
        end
    endgenerate

    //Combinational Logic
    wire [3:0] pref0, pref1, pref2, pref3;
    wire [3:0] final_prefixes;
    wire [2:0] prefix_count;
    wire [7:0] opcode_w;
    wire is_modrm1, is_modrm2, is_modrm3, is_modrm4, is_modrm5;
    wire [7:0] modrm_w;
    wire needs_sib1, needs_sib2, needs_sib3, needs_sib4, needs_sib5;
    wire [7:0] sib_w;
    wire needs_sib; //sib_signal
    wire [1:0] disp_num; //precalculated
    wire [2:0] disp_start_byte;
    wire [31:0] disp32_w; //speculative
    wire [31:0] disp8_w; //speculative
    wire [7:0] zero_byte;
    
    assign zero_byte = 8'd0;
    assign sib = sib_w;
    always @(*) begin

        //Default
        prefix_mux_out = 3'b000; 
        ext_opcode = 1'b0;
        opcode = 7'd0;
        modrm = 7'd0;
        sib = 7'd0;
        disp = 32'd0;
        disp_num = disp_num_fn(modrm, sib);
        disp_size_mux = 1'b0;     
        imm = 32'd0;
        imm_size_mux = 2'd0;
        reg0_mux = 2'd0;
        imm_type = 2'd0;

        //Prefix Logic
        pref0 = is_prefix_fn(byte[0]) ? detect_prefixes_fn(byte[0]) : 4'b0000;
        pref1 = is_prefix_fn(byte[1]) ? detect_prefixes_fn(byte[1]) : 4'b0000;
        pref2 = is_prefix_fn(byte[2]) ? detect_prefixes_fn(byte[2]) : 4'b0000;
        pref3 = is_prefix_fn(byte[3]) ? detect_prefixes_fn(byte[3]) : 4'b0000;
        final_prefixes = pref0 | pref1 | pref2 | pref3; //Combine prefixes
        prefix_mux_out = final_prefixes[3:1];
        ext_opcode = final_prefixes[0];

        //Opcode Logic
        is_pref0 = is_prefix_fn(byte[0]);
        is_pref1 = is_prefix_fn(byte[1]);
        is_pref2 = is_prefix_fn(byte[2]);
        is_pref3 = is_prefix_fn(byte[3]);
        prefix_adder = is_pref0 + is_pref1 + is_pref2 + is_pref3;

        case (prefix_adder)
            3'b000: opcode_w = byte[0];
            3'b001: opcode_w = byte[1];
            3'b010: opcode_w = byte[2];
            3'b011: opcode_w = byte[3];
            3'b100: opcode_w = byte[4];
            default: opcode_w = 8'd0;
        endcase
        opcode = opcode_w;

        //Modrm Logic
        is_modrm1 = needs_modrm_fn(byte[0], ext_opcode); //speculative
        is_modrm2 = needs_modrm_fn(byte[1], ext_opcode); //speculative
        is_modrm3 = needs_modrm_fn(byte[2], ext_opcode); //speculative
        is_modrm4 = needs_modrm_fn(byte[3], ext_opcode); //speculative
        is_modrm5 = needs_modrm_fn(byte[4], ext_opcode); //speculative

        case (prefix_adder)
            3'b000: modrm_w = is_modrm1 ? byte[1] : 8'd0;
            3'b001: modrm_w = is_modrm2 ? byte[2] : 8'd0;
            3'b010: modrm_w = is_modrm3 ? byte[3] : 8'd0;
            3'b011: modrm_w = is_modrm4 ? byte[4] : 8'd0;
            3'b100: modrm_w = is_modrm5 ? byte[5] : 8'd0;
            default: modrm_w = 8'd0;
        endcase
        modrm = modrm_w;

        //SIB Logic
        needs_sib1 = needs_sib_fn(byte[1]); //speculative
        needs_sib2 = needs_sib_fn(byte[2]); //speculative
        needs_sib3 = needs_sib_fn(byte[3]); //speculative
        needs_sib4 = needs_sib_fn(byte[4]); //speculative
        needs_sib5 = needs_sib_fn(byte[5]); //speculative
        case (prefix_adder)
            if(byte[1] == modrm) begin
                sib_w = needs_sib1 ? byte[1] : 8'd0;
                needs_sib = needs_sib1;
            end
            if (byte[2] == modrm) begin
                sib_w = needs_sib2 ? byte[2] : 8'd0;
                needs_sib = needs_sib2;
            end
            if(byte[3] == modrm) begin
                sib_w = needs_sib3 ? byte[3] : 8'd0;
                needs_sib = needs_sib3;
            end
            if (byte[4] == modrm) begin
                sib_w = needs_sib4 ? byte[4] : 8'd0;
                needs_sib = needs_sib4;
            end
            if (byte[5] == modrm) begin
                sib_w = needs_sib5 ? byte[5] : 8'd0;
                needs_sib = needs_sib5;
            end
            default: sib_w = 8'd0;
        endcase
    
        //Displacement Logic
        disp_start_byte = prefix_adder + needs_sib;

        case (disp_start_byte)
            3'b000: disp32_w = {byte[5], byte[4], byte[3], byte[2]};
            3'b001: disp32_w = {byte[6], byte[5], byte[4], byte[3]};
            3'b010: disp32_w = {byte[7], byte[6], byte[5], byte[4]};
            3'b011: disp32_w = {byte[8], byte[7], byte[6], byte[5]};
            3'b100: disp32_w = {byte[9], byte[8], byte[7], byte[6]};
            3'b101: disp32_w = {byte[10], byte[9], byte[8], byte[7]};
            default: disp32_w = 32'd0;
        endcase

        case (disp_start_byte)
            3'b000: disp8_w = {zero_byte, zero_byte, zero_byte, byte[2]};
            3'b001: disp8_w = {zero_byte, zero_byte, zero_byte, byte[3]};
            3'b010: disp8_w = {zero_byte, zero_byte, zero_byte, byte[4]};
            3'b011: disp8_w = {zero_byte, zero_byte, zero_byte, byte[5]};
            3'b100: disp8_w = {zero_byte, zero_byte, zero_byte, byte[6]};
            3'b101: disp8_w = {zero_byte, zero_byte, zero_byte, byte[7]};
            default: disp8_w = 32'd0;
        endcase

    end

endmodule
            
            



