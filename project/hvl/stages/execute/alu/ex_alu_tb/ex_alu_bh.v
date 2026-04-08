module ex_alu_bh(
    input  [2:0]  alu_op,
    input  [1:0]  ds,
    input  [31:0] in0,
    input  [31:0] in1,
    input         eflags_cf,
    input         sbb_dir,
    output [31:0] alu_out,
    output [31:0] alu_eflags,
    output [31:0] alu_eflags_mask
);


    // ADD
    wire [31:0] add_out, add_cout;
    HA_32b HA32_ADD(
        .in0 (in0),
        .in1 (in1),
        .s   (add_out),
        .cout(add_cout)
    );

    // ADC
    wire [31:0] adc_out, adc_cout;
    FA_32b FA32_ADC(
        .in0 (in0),
        .in1 (in1),
        .cin (eflags_cf),
        .s   (adc_out),
        .cout(adc_cout)
    );

    // SBB
    wire [31:0] sbb_out, sbb_cout;
    wire [31:0] sbb_in0, sbb_in1;
    assign sbb_in0 = sbb_dir ? in1 : in0;
    assign sbb_in1 = sbb_dir ? in0 : in1;
    SUB_32b SUB32_SBB(
        .in0 (sbb_in0),
        .in1 (sbb_in1),
        .cin (eflags_cf),
        .s   (sbb_out),
        .cout(sbb_cout)
    );

    // OR
    wire [31:0] or_out;
    or2$ or32[31:0](or_out, in0, in1);

    // AND
    wire [31:0] and_out;
    and2$ and32[31:0](and_out, in0, in1);

    reg [31:0] alu_mux_out;
    reg [31:0] alu_mux_cout;

    always @(*) begin
        case (alu_op)
            3'b000: begin // ADD
                alu_mux_out  = add_out;
                alu_mux_cout = add_cout;
            end
            3'b001: begin // OR
                alu_mux_out  = or_out;
                alu_mux_cout = 32'b0;
            end
            3'b010: begin // ADC
                alu_mux_out  = adc_out;
                alu_mux_cout = adc_cout;
            end
            3'b011: begin // SBB
                alu_mux_out  = sbb_out;
                alu_mux_cout = sbb_cout;
            end
            3'b100: begin // AND
                alu_mux_out  = and_out;
                alu_mux_cout = 32'b0;
            end
            default: begin
                alu_mux_out  = 32'b0;
                alu_mux_cout = 32'b0;
            end
        endcase
    end

    assign alu_out = alu_mux_out;


    wire OF8,  OF16,  OF32;
    wire SF8,  SF16,  SF32;
    wire ZF8,  ZF16,  ZF32;
    wire AF8,  AF16,  AF32;
    wire CF8,  CF16,  CF32;
    wire PF8,  PF16,  PF32;

    alu_eflags_bh #(.WIDTH(8)) alu_eflags8 (
        .in0   (in0),
        .in1   (in1),
        .out   (alu_mux_out),
        .cout  (alu_mux_cout),
        .alu_op(alu_op),
        .OF    (OF8),
        .SF    (SF8),
        .ZF    (ZF8),
        .AF    (AF8),
        .CF    (CF8),
        .PF    (PF8)
    );

    alu_eflags_bh #(.WIDTH(16)) alu_eflags16 (
        .in0   (in0),
        .in1   (in1),
        .out   (alu_mux_out),
        .cout  (alu_mux_cout),
        .alu_op(alu_op),
        .OF    (OF16),
        .SF    (SF16),
        .ZF    (ZF16),
        .AF    (AF16),
        .CF    (CF16),
        .PF    (PF16)
    );

    alu_eflags_bh #(.WIDTH(32)) alu_eflags32 (
        .in0   (in0),
        .in1   (in1),
        .out   (alu_mux_out),
        .cout  (alu_mux_cout),
        .alu_op(alu_op),
        .OF    (OF32),
        .SF    (SF32),
        .ZF    (ZF32),
        .AF    (AF32),
        .CF    (CF32),
        .PF    (PF32)
    );

    reg OF, SF, ZF, AF, CF, PF;

    always @(*) begin
        case (ds)
            2'b00: begin
                OF = OF8;  SF = SF8;  ZF = ZF8;
                AF = AF8;  CF = CF8;  PF = PF8;
            end
            2'b01: begin
                OF = OF16; SF = SF16; ZF = ZF16;
                AF = AF16; CF = CF16; PF = PF16;
            end
            2'b10: begin
                OF = OF32; SF = SF32; ZF = ZF32;
                AF = AF32; CF = CF32; PF = PF32;
            end
            default: begin
                OF = 1'b0; SF = 1'b0; ZF = 1'b0;
                AF = 1'b0; CF = 1'b0; PF = 1'b0;
            end
        endcase
    end

    // Pack into x86-style bit positions
    assign alu_eflags = {
        20'b0,   // [31:12]
        OF,      // [11]
        3'b0,    // [10:8]
        SF,      // [7]
        ZF,      // [6]
        1'b0,    // [5]
        AF,      // [4]
        1'b0,    // [3]
        PF,      // [2]
        1'b0,    // [1]
        CF       // [0]
    };

    // =========================================================
    // EFLAGS mask
    //
    // ADD / ADC / SBB : OF SF ZF AF PF CF  => 0x08D5
    // AND / OR        : OF CF are cleared, SF/ZF/PF valid, AF not written
    //                   => mask = OF|SF|ZF|PF|CF = 0x08C5
    // ds == 11        : undefined => mask 0
    // =========================================================

    reg [31:0] mask_r;

    always @(*) begin
        if (ds == 2'b11) begin
            mask_r = 32'b0;
        end else begin
            case (alu_op)
                3'b000, // ADD
                3'b010, // ADC
                3'b011: // SBB
                    mask_r = 32'h0000_08D5;

                3'b001, // OR
                3'b100: // AND
                    mask_r = 32'h0000_08C5;

                default:
                    mask_r = 32'b0;
            endcase
        end
    end

    assign alu_eflags_mask = mask_r;

endmodule