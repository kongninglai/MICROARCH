module ucode_fsm(
    input clk,
    input rst_n,

    input to_rr_valid,
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

    output cmps0,
    output cmps1,
    output cmps2,
    output ucode_stall,
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

    reg [7:0] ucode_opcode;
    wire [95:0] sig_reg, sig_mem, sig_ext, sig_ext_mem;
    ucoderom #(.MEMFILE64("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_reg64.data"), .MEMFILE32("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_reg32.data")) ucoderom_reg(.opcode(ucode_opcode), .sig(sig_reg));
    ucoderom #(.MEMFILE64("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_mem64.data"), .MEMFILE32("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_mem32.data")) ucoderom_mem(.opcode(ucode_opcode), .sig(sig_mem));
    ucoderom #(.MEMFILE64("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_ext64.data"), .MEMFILE32("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_ext32.data")) ucoderom_ext(.opcode(ucode_opcode), .sig(sig_ext));
    ucoderom #(.MEMFILE64("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_ext_mem64.data"), .MEMFILE32("/home/ecelrc/students/kl38888/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_ext_mem32.data")) ucoderom_ext_mem(.opcode(ucode_opcode), .sig(sig_ext_mem));


    wire counter_start, counter_dec, counter_finish;
    ecx_counter ecx_counter_inst(
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
        end else if (~stall) begin 
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

    assign counter_start        = (state == S_IDLE) & rep & to_rr_valid;
    assign counter_dec          = ((state == S_REP_CMPS0) | (state == S_REP_MOVS0));
    // stall: state=S_IDLE & next_state != S_IDLE || state != S_IDLE & next_state != S_IDLE
    assign ucode_stall          = (next_state != S_IDLE);
    assign ucode_valid          = 1'b1;
    wire [95:0] sig_reg_rm, sig_ext_rm, sig_idle;
    wire addr_mode; // 1 for mem mode, 1 for reg mode
    nand2$ nand_addrmode(addr_mode, modrm[1], modrm[0]);
    mux2_64 mux2_reg_rm64(.in0(sig_reg[95:32]), .in1(sig_mem[95:32]), .s0(addr_mode), .out(sig_reg_rm[95:32]));
    mux2_32 mux2_reg_rm32(.in0(sig_reg[31:0]), .in1(sig_mem[31:0]), .s0(addr_mode), .out(sig_reg_rm[31:0]));
    mux2_64 mux2_ext_rm64(.in0(sig_ext[95:32]), .in1(sig_ext_mem[95:32]), .s0(addr_mode), .out(sig_ext_rm[95:32]));
    mux2_32 mux2_ext_rm32(.in0(sig_ext[31:0]), .in1(sig_ext_mem[31:0]), .s0(addr_mode), .out(sig_ext_rm[31:0]));

    mux4_64 mux4_sig64(.in0(sig_reg[95:32]), .in1(sig_reg_rm[95:32]), .in2(sig_ext[95:32]), .in3(sig_ext_rm[95:32]), .s0(has_modrm), .s1(ext_opcode), .out(sig_idle[95:32]));
    mux4_32 mux4_sig32(.in0(sig_reg[31:0]), .in1(sig_reg_rm[31:0]), .in2(sig_ext[31:0]), .in3(sig_ext_rm[31:0]), .s0(has_modrm), .s1(ext_opcode), .out(sig_idle[31:0]));

    assign ucode_sig = (state == S_IDLE) ? sig_idle : sig_reg;
    assign cmps0 = (state == S_REP_CMPS0);
    assign cmps1 = (state == S_REP_CMPS1);
    assign cmps2 = (state == S_REP_CMPS2);
endmodule

module ecx_counter(
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