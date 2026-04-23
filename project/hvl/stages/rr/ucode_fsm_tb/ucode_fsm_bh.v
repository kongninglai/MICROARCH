module ucode_fsm_bh(
    input clk,
    input rst_n,

    input to_rr_valid,
    input [95:0] to_rr_ucode_sigs,
    input rep,
    input stall,
    input interrupt,
    input exception, // from wb
    input movs,
    input cmps,
    input iret,
    input cmps_found, // TODO: HOW TO DEAL WITH CMP? if mismatch, partial flush the pipeline (rr_to_ag, ag_to_mem)

    input [7:0] opcode,
    input ext_opcode,
    input [1:0] modrm,
    input has_modrm,

    input [31:0] reg_ecx,

    output movs0,
    output movs1,
    output cmps0,
    output cmps1,
    output cmps2,
    output iret0,
    output clear_int,
    output intex,
    output handling_intex,
    output ucode_stall_bar,
    output ucode_valid,
    output [95:0] ucode_sig
); 
    localparam S_IDLE = 4'd0;

    localparam S_REP_MOVS0 = 4'd1;
    localparam S_REP_MOVS1 = 4'd2;

    localparam S_REP_CMPS0 = 4'd3;
    localparam S_REP_CMPS1 = 4'd4;
    localparam S_REP_CMPS2 = 4'd5;

    localparam S_INTEX_INIT0 = 4'd6;
    localparam S_INTEX_INIT1 = 4'd7;

    localparam S_IRET0 = 4'd8;
    localparam S_IRET1 = 4'd9;

    localparam OPC_REP_READ_ECX     = 8'd39;
    localparam OPC_REP_MOVS1        = 8'd40;
    localparam OPC_REP_CMPS0        = 8'd42;
    localparam OPC_REP_CMPS1        = 8'd41;
    localparam OPC_REP_CMPS2        = 8'd47;
    localparam OPC_INTEX_INIT0      = 8'd43;
    localparam OPC_INTEX_INIT1      = 8'd44;
    localparam OPC_IRET0            = 8'd45;
    localparam OPC_IRET1            = 8'd46;

    localparam UCODE_REP_READ_ECX = 96'b00xxxxx0x01xxxxxx000100000000000xxx00xxxxxxxxxxxxxxxxxxxxxx00xxxxxxxx0xxxxxxxxxxxxxxxxxxxxxxxxxx;
    localparam UCODE_REP_MOVS1    = 96'b10110xx0x01xxxxxx100100000000000xxx00xxxxxxxx1100xxxxxxxxxx0010xxxx0x0xxxxxxxxxxxxxxxxxxxxxxxxxx;
    localparam UCODE_REP_CMPS0    = 96'b00xxxxxxxxxx01x0x000000100010000xxx00xxxxxxxxxxxxxxxxxxxxxx101010xx0x0xxxxxxxxxxxxxxxxxxxxxxxxxx;
    localparam UCODE_REP_CMPS1    = 96'b11101111010x01xx1100110010001000xxx00xxxxxxxx0101000xxxxxxx101010xx1x0xxxxxxxxxxxxxxxxxxxxxxxxxx;
    localparam UCODE_REP_CMPS2    = 96'b10110xx0x01xxxxxx100100000000001xxx00100xxxxx1100xxxxxxxxxx0010xxxxxx0xxxxxxxxxxxxxxxxxxxxxxxxxx;
    localparam UCODE_INTEX_INIT0  = 96'b01xxx00xx11xxxxx1100000010001000xxx00xxxxxxxxxxxx010xxx100001xx10xxx10xxxxxxxxxxxxxxxxxxxxxxxxxx;
    localparam UCODE_INTEX_INIT1  = 96'b01xxx00xx11xxxxx1100000010001000xxx11xxx10010xxxx010xxx101111xx11xxx10xxxxxxxxxxxxxxxxxxxxxxxxxx;
    localparam UCODE_IRET0        = 96'b01xxx00xx11xxxxx1100000010001000xxx00xxxxxxxxxxxx001xxxxxxx10xx11xx1x0xxxxxxxxxxxxxxxxxxxxxxxxxx;
    localparam UCODE_IRET1        = 96'b01xxx00xx11xxxxx1100000010001001xxx1111110111xxxx001xxxxxxx10xx10xx1x0xxxxxxxxxxxxxxxxxxxxxxxxxx;

    reg [7:0] ucode_opcode;

    wire counter_start, counter_dec, counter_finish;
    ecx_counter_bh ecx_counter_inst(
        .clk(clk),
        .rst_n(rst_n),
        .start(counter_start),
        .dec(counter_dec),
        .reg_ecx(reg_ecx),
        .stall(stall),
        .counter_finish(counter_finish)
    );

    reg [3:0] state, next_state;

    always @(posedge clk) begin
        if (!rst_n) begin 
            state <= S_IDLE;
        end else if ((~stall) | exception) begin 
            state <= next_state;
        end
    end

    always @(*) begin 
        next_state = state;
        case (state)
            S_IDLE: begin 
                if (interrupt | exception) begin 
                    next_state = S_INTEX_INIT0;
                end else if (to_rr_valid & iret) begin 
                    next_state = S_IRET0;
                end else if (to_rr_valid & movs & rep & (reg_ecx!=0)) begin 
                    next_state = S_REP_MOVS0;
                end else if (to_rr_valid & cmps & rep & (reg_ecx!=0)) begin 
                    next_state = S_REP_CMPS0;
                end
            end

            S_REP_MOVS0: begin 
                if (exception) begin 
                    next_state = S_INTEX_INIT0;
                end else begin 
                    next_state = S_REP_MOVS1;
                end
            end

            S_REP_MOVS1: begin 
                if (interrupt | exception) begin 
                    next_state = S_INTEX_INIT0;
                end else if (counter_finish) begin 
                    next_state = S_IDLE;
                end else begin 
                    next_state = S_REP_MOVS0;
                end
            end

            S_REP_CMPS0: begin 
                if (exception) begin 
                    next_state = S_INTEX_INIT0;
                end else if (cmps_found) begin 
                    next_state = S_IDLE;
                end else begin 
                    next_state = S_REP_CMPS1;
                end
            end

            S_REP_CMPS1: begin 
                if (exception) begin 
                    next_state = S_INTEX_INIT0;
                end else if (cmps_found) begin 
                    next_state = S_IDLE;
                end else begin 
                    next_state = S_REP_CMPS2;
                end
            end

            S_REP_CMPS2: begin 
                if (interrupt | exception) begin 
                    next_state = S_INTEX_INIT0;
                end else if (counter_finish | cmps_found) begin 
                    next_state = S_IDLE;
                end else begin 
                    next_state = S_REP_CMPS0;
                end
            end

            S_INTEX_INIT0: begin 
                next_state = S_INTEX_INIT1;
            end

            S_INTEX_INIT1: begin 
                next_state = S_IDLE;
            end

            S_IRET0: begin 
                next_state = S_IRET1;
            end

            S_IRET1: begin 
                next_state = S_IDLE;
            end

            default: next_state = state;
        endcase
    end

    always @(*) begin 
        case (state)
            S_IDLE: begin 
                if (to_rr_valid & rep) begin 
                    ucode_opcode = OPC_REP_READ_ECX;
                end else begin 
                    ucode_opcode = opcode;
                end
            end
            S_REP_MOVS0:    ucode_opcode = opcode; 
            S_REP_MOVS1:    ucode_opcode = OPC_REP_MOVS1;
            S_REP_CMPS0:    ucode_opcode = OPC_REP_CMPS0;
            S_REP_CMPS1:    ucode_opcode = OPC_REP_CMPS1;
            S_REP_CMPS2:    ucode_opcode = OPC_REP_CMPS2;
            S_INTEX_INIT0:  ucode_opcode = OPC_INTEX_INIT0;
            S_INTEX_INIT1:  ucode_opcode = OPC_INTEX_INIT1;
            S_IRET0:        ucode_opcode = OPC_IRET0;
            S_IRET1:        ucode_opcode = OPC_IRET1;
        endcase
    end

    reg [95:0] reg_ucode_sigs;
    assign ucode_sig = reg_ucode_sigs;
    always @(*) begin 
        case (state)
            S_IDLE: begin 
                if (to_rr_valid & rep) begin 
                    reg_ucode_sigs = UCODE_REP_READ_ECX;
                end else begin 
                    reg_ucode_sigs = to_rr_ucode_sigs;
                end
            end
            S_REP_MOVS0:    reg_ucode_sigs = to_rr_ucode_sigs; 
            S_REP_MOVS1:    reg_ucode_sigs = UCODE_REP_MOVS1;
            S_REP_CMPS0:    reg_ucode_sigs = UCODE_REP_CMPS0;
            S_REP_CMPS1:    reg_ucode_sigs = UCODE_REP_CMPS1;
            S_REP_CMPS2:    reg_ucode_sigs = UCODE_REP_CMPS2;
            S_INTEX_INIT0:  reg_ucode_sigs = UCODE_INTEX_INIT0;
            S_INTEX_INIT1:  reg_ucode_sigs = UCODE_INTEX_INIT1;
            S_IRET0:        reg_ucode_sigs = UCODE_IRET0;
            S_IRET1:        reg_ucode_sigs = UCODE_IRET1;
        endcase
    end
    assign counter_start        = (state == S_IDLE) & rep & to_rr_valid;
    assign counter_dec          = ((state == S_REP_CMPS0) | (state == S_REP_MOVS0));
    // stall: state=S_IDLE & next_state != S_IDLE || state != S_IDLE & next_state != S_IDLE
    assign ucode_stall_bar          = ~(next_state != S_IDLE);
    assign ucode_valid          = (state == S_IDLE) ? to_rr_valid : 1'b1;
    
    assign movs0 = (state == S_REP_MOVS0);
    assign movs1 = (state == S_REP_MOVS1);
    assign cmps0 = (state == S_REP_CMPS0);
    assign cmps1 = (state == S_REP_CMPS1);
    assign cmps2 = (state == S_REP_CMPS2);
    assign iret0 = (state == S_IRET0);
    assign intex = (state == S_INTEX_INIT1);
    assign clear_int = (state == S_INTEX_INIT1);
    assign handling_intex = (state == S_INTEX_INIT0) | (state == S_INTEX_INIT1);
endmodule

module ecx_counter_bh(
    input clk,
    input rst_n,

    input start,
    input dec,
    input [31:0] reg_ecx,
    input stall,

    output counter_finish
); 
    reg [31:0] counter, next_counter;

    always @(posedge clk) begin
        if (!rst_n) begin 
            counter <= 32'd0;
        end else if ((start | dec) & (~stall)) begin 
            counter <= next_counter;
        end
    end

    always @(*) begin 
        next_counter = start ? reg_ecx : (counter-1);
    end

    assign counter_finish = (counter == 32'd0);
endmodule