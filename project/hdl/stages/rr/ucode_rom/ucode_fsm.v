module ucode_fsm(
    input clk,
    input rst_n,

    input to_rr_valid,
    input raw_to_rr_valid,
    input [95:0] to_rr_ucode_sigs,
    input rep,
    input stall,
    input interrupt,
    input exception,
    input movs,
    input cmps,
    input iret,
    input cmps_found,

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
    output not_intex_or_iret,
    output ucode_stall_bar,
    output ucode_valid,
    output [95:0] ucode_sig
);  
    localparam S_IDLE = 4'd0;       // 0000

    localparam S_REP_MOVS0 = 4'd1;  // 0001
    localparam S_REP_MOVS1 = 4'd2;  // 0010

    localparam S_REP_CMPS0 = 4'd3;  // 0011
    localparam S_REP_CMPS1 = 4'd4;  // 0100
    localparam S_REP_CMPS2 = 4'd5;  // 0101

    localparam S_INTEX_INIT0 = 4'd6; // 0110
    localparam S_INTEX_INIT1 = 4'd7; // 0111

    localparam S_IRET0 = 4'd8;       // 1000
    localparam S_IRET1 = 4'd9;       // 1001

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

    // wire [7:0] ucode_opcode;
    // wire [95:0] sig_reg, sig_mem, sig_ext, sig_ext_mem;
    // ucoderom #(.MEMFILE64("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_reg64.data"), .MEMFILE32("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_reg32.data")) ucoderom_reg(.opcode(ucode_opcode), .sig(sig_reg));
    // ucoderom #(.MEMFILE64("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_mem64.data"), .MEMFILE32("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_mem32.data")) ucoderom_mem(.opcode(ucode_opcode), .sig(sig_mem));
    // ucoderom #(.MEMFILE64("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_ext64.data"), .MEMFILE32("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_ext32.data")) ucoderom_ext(.opcode(ucode_opcode), .sig(sig_ext));
    // ucoderom #(.MEMFILE64("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_ext_mem64.data"), .MEMFILE32("/home/ecelrc/students/var2427/MICROARCH/project/hdl/stages/rr/ucode_rom/ucode_ext_mem32.data")) ucoderom_ext_mem(.opcode(ucode_opcode), .sig(sig_ext_mem));

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

    wire Q3,Q2,Q1,Q0;
	wire D3,D2,D1,D0;
    wire d0_in, d1_in, d2_in, d3_in;
    
    wire [3:0] state, next_state;

     wire Q0_prebuf, Q1_prebuf, Q2_prebuf, Q3_prebuf,
        Q0_bar_prebuf, Q1_bar_prebuf, Q2_bar_prebuf, Q3_bar_prebuf;

    assign state = {Q3_prebuf, Q2_prebuf, Q1_prebuf, Q0_prebuf};
    assign next_state = {d3_in, d2_in, d1_in, d0_in};

    wire valid_rep, valid_rep_bar;
    // wire [7:0] ucode_idle;
    wire [95:0] ucode_sig_idle;
    wire to_rr_valid_buf16;
    bufferH16$  bufferH16$_to_rr_valid_buf16(to_rr_valid_buf16, to_rr_valid);
    nand2$ nand2_valid_rep(valid_rep_bar, raw_to_rr_valid, rep);
    bufferHInv16$ buffer_valid_rep(valid_rep, valid_rep_bar);
    // mux2_8$ mux2_ucode_idle(ucode_idle, opcode, OPC_REP_READ_ECX, valid_rep);

    wire [95:0] to_rr_ucode_sigs_buffered;
    bufferH16$ buffer_to_rr_ucode_sigs[95:0](to_rr_ucode_sigs_buffered, to_rr_ucode_sigs);

    mux2_96 mux2_ucode_sig_idle(ucode_sig_idle, to_rr_ucode_sigs_buffered, UCODE_REP_READ_ECX, valid_rep);
    wire [7:0] ucode_opcode_prebuf;
    bufferH64$  bufferH64$_ucode_opcode[7:0](ucode_opcode, ucode_opcode_prebuf);
    // mux16_8b mux16_ucode_opcode(ucode_opcode_prebuf, 
    //                             ucode_idle, opcode, OPC_REP_MOVS1, OPC_REP_CMPS0, 
    //                             OPC_REP_CMPS1, OPC_REP_CMPS2, OPC_INTEX_INIT0, OPC_INTEX_INIT1,
    //                             OPC_IRET0, OPC_IRET1, opcode, opcode, 
    //                             opcode, opcode, opcode, opcode,
    //                             state[0], state[1], state[2], state[3]);
    mux16_96 mux16_ucode_sig(ucode_sig,
                             ucode_sig_idle, to_rr_ucode_sigs_buffered, UCODE_REP_MOVS1, UCODE_REP_CMPS0,
                             UCODE_REP_CMPS1, UCODE_REP_CMPS2, UCODE_INTEX_INIT0, UCODE_INTEX_INIT1,
                             UCODE_IRET0, UCODE_IRET1, to_rr_ucode_sigs_buffered, to_rr_ucode_sigs_buffered,
                             to_rr_ucode_sigs_buffered,to_rr_ucode_sigs_buffered,to_rr_ucode_sigs_buffered,to_rr_ucode_sigs_buffered,
                             Q0, Q1, Q2, Q3);
    // always @(*) begin 
    //     case (state)
    //         S_IDLE: begin 
    //             if (to_rr_valid & rep) begin 
    //                 ucode_opcode = OPC_REP_READ_ECX;
    //             end else begin 
    //                 ucode_opcode = opcode;
    //             end
    //         end
    //         S_REP_MOVS0:    ucode_opcode = opcode; 
    //         S_REP_MOVS1:    ucode_opcode = OPC_REP_MOVS1;
    //         S_REP_CMPS0:    ucode_opcode = OPC_REP_CMPS0;
    //         S_REP_CMPS1:    ucode_opcode = OPC_REP_CMPS1;
    //         S_REP_CMPS2:    ucode_opcode = OPC_REP_CMPS2;
    //         S_INTEX_INIT0:  ucode_opcode = OPC_INTEX_INIT0;
    //         S_INTEX_INIT1:  ucode_opcode = OPC_INTEX_INIT1;
    //         S_IRET0:        ucode_opcode = OPC_IRET0;
    //         S_IRET1:        ucode_opcode = OPC_IRET1;
    //     endcase
    // end

    

    /*** SCRIPT GENERATED FSM ***/
    wire rep_movs, rep_cmps;

    wire big_or_out_bar;
    wire g0, g1, g2, g3, g4, g5, g6, g7;
    wire h0, h1;

    nor4$ n0(g0, reg_ecx[0],  reg_ecx[1],  reg_ecx[2],  reg_ecx[3]);
    nor4$ n1(g1, reg_ecx[4],  reg_ecx[5],  reg_ecx[6],  reg_ecx[7]);
    nor4$ n2(g2, reg_ecx[8],  reg_ecx[9],  reg_ecx[10], reg_ecx[11]);
    nor4$ n3(g3, reg_ecx[12], reg_ecx[13], reg_ecx[14], reg_ecx[15]);
    nor4$ n4(g4, reg_ecx[16], reg_ecx[17], reg_ecx[18], reg_ecx[19]);
    nor4$ n5(g5, reg_ecx[20], reg_ecx[21], reg_ecx[22], reg_ecx[23]);
    nor4$ n6(g6, reg_ecx[24], reg_ecx[25], reg_ecx[26], reg_ecx[27]);
    nor4$ n7(g7, reg_ecx[28], reg_ecx[29], reg_ecx[30], reg_ecx[31]);

    nand4$ n8(h0, g0, g1, g2, g3);
    nand4$ n9(h1, g4, g5, g6, g7);

    nor2$ n10(big_or_out_bar, h0, h1);

    wire rep_bar, movs_bar, cmps_bar;
    inv1$ inv1$_rep_bar(rep_bar, rep);
    inv1$ inv1$_movs_bar(movs_bar, movs);
    inv1$ inv1$_cmps_bar(cmps_bar, cmps);

    nor3$ nor3$_rep_movs(rep_movs, rep_bar, movs_bar, big_or_out_bar);
    nor3$ nor3$_rep_cmps(rep_cmps, rep_bar, cmps_bar, big_or_out_bar);

    /* Inverters */
	wire Q3_bar;
	wire cmps_found_bar;
	inv1$ inv_1(cmps_found_bar, cmps_found);
	wire Q0_bar;
	wire interrupt_bar;
	bufferHInv16$ inv_3(interrupt_bar, interrupt);
	wire Q2_bar;
	wire Q1_bar;
	wire exception_bar;
	bufferHInv16$ inv_6(exception_bar, exception);
	wire counter_finish_bar;
	bufferHInv16$ inv_7(counter_finish_bar, counter_finish);

	/* Product Expressions */
	wire and_0_0_out;
	wire and_0_1_out;
	wire and_0_2_out;
	or2$ and_0_0(and_0_0_out,and_0_1_out,and_0_2_out);
	nand4$ and_0_1(and_0_1_out,Q1_bar,Q0,interrupt_bar,exception_bar);
	nand4$ and_0_2(and_0_2_out,counter_finish_bar,cmps_found_bar,Q3_bar,Q2);
	wire and_1_0_out;
	wire and_1_1_out;
	wire and_1_2_out;
	or2$ and_1_0(and_1_0_out,and_1_1_out,and_1_2_out);
	nand4$ and_1_1(and_1_1_out,Q1_bar,Q0_bar,interrupt_bar,exception_bar);
	nand4$ and_1_2(and_1_2_out,to_rr_valid_buf16,rep_cmps,Q3_bar,Q2_bar);
	wire and_2_0_out;
	wire and_2_1_out;
	nand4$ and_2_0(and_2_0_out,and_2_1_out,exception_bar,to_rr_valid_buf16,iret);
	and4$ and_2_1(and_2_1_out,interrupt_bar,Q2_bar,Q1_bar,Q0_bar);
	wire and_3_0_out;
	wire and_3_1_out;
	nand4$ and_3_0(and_3_0_out,and_3_1_out,to_rr_valid_buf16,interrupt_bar,exception_bar);
	and4$ and_3_1(and_3_1_out,rep_movs,Q2_bar,Q1_bar,Q0_bar);
	wire and_4_0_out;
	wire and_4_1_out;
	nand4$ and_4_0(and_4_0_out,and_4_1_out,Q3_bar,Q1,Q0_bar);
	and3$ and_4_1(and_4_1_out,interrupt_bar,exception_bar,counter_finish_bar);
	wire and_5_0_out;
	wire and_5_1_out;
	nand4$ and_5_0(and_5_0_out,and_5_1_out,cmps_found_bar,Q0,Q1);
	and2$ and_5_1(and_5_1_out,Q3_bar,Q2_bar);
	wire and_6_0_out;
	wire and_6_1_out;
	nand4$ and_6_0(and_6_0_out,and_6_1_out,Q3_bar,cmps_found_bar,Q0_bar);
	and2$ and_6_1(and_6_1_out,exception_bar,Q2);
	wire and_7_0_out;
	wire and_7_1_out;
	nand4$ and_7_0(and_7_0_out,and_7_1_out,Q3_bar,Q2,Q1_bar);
	and2$ and_7_1(and_7_1_out,Q0,interrupt);
	wire and_8_0_out;
	nand3$ and_8_0(and_8_0_out,Q3_bar,Q2_bar,exception);
	wire and_9_0_out;
	nand4$ and_9_0(and_9_0_out,Q3,Q2_bar,Q1_bar,Q0_bar);
	wire and_10_0_out;
	nand3$ and_10_0(and_10_0_out,Q3_bar,Q1_bar,exception);
	wire and_11_0_out;
	nand4$ and_11_0(and_11_0_out,Q3_bar,Q2_bar,Q0_bar,interrupt);
	wire and_12_0_out;
	nand4$ and_12_0(and_12_0_out,Q3_bar,Q2_bar,Q1_bar,Q0);
	wire and_13_0_out;
	nand4$ and_13_0(and_13_0_out,Q3_bar,Q2,Q1,Q0_bar);

	/* Sum Expressions */
	nand2$ or_0_0(D3,and_2_0_out,and_9_0_out);
	wire or_1_1_out;
	nand4$ or_1_0(D2,or_1_1_out,and_5_0_out,and_6_0_out,and_7_0_out);
	and4$ or_1_1(or_1_1_out,and_8_0_out,and_10_0_out,and_11_0_out,and_13_0_out);
	wire or_2_1_out;
	wire or_2_2_out;
	nand2$ or_2_0(D1,or_2_1_out,or_2_2_out);
	and4$ or_2_1(or_2_1_out,and_7_0_out,and_8_0_out,and_10_0_out,and_11_0_out);
	and4$ or_2_2(or_2_2_out,and_12_0_out,and_13_0_out,and_0_0_out,and_1_0_out);
	wire or_3_1_out;
	nand4$ or_3_0(D0,or_3_1_out,and_0_0_out,and_1_0_out,and_3_0_out);
	and4$ or_3_1(or_3_1_out,and_4_0_out,and_6_0_out,and_9_0_out,and_13_0_out);

	/* State Flip Flops */
    wire we;
    nand2$ nand_we(we, exception_bar, stall);

    mux2$ mux2_d0_in(d0_in, Q0, D0, we);
    mux2$ mux2_d1_in(d1_in, Q1, D1, we);
    mux2$ mux2_d2_in(d2_in, Q2, D2, we);
    mux2$ mux2_d3_in(d3_in, Q3, D3, we);
        
	dff$ dff_0(clk, d0_in, Q0_prebuf, Q0_bar_prebuf, rst_n, 1'b1);
	dff$ dff_1(clk, d1_in, Q1_prebuf, Q1_bar_prebuf, rst_n, 1'b1);
	dff$ dff_2(clk, d2_in, Q2_prebuf, Q2_bar_prebuf, rst_n, 1'b1);
	dff$ dff_3(clk, d3_in, Q3_prebuf, Q3_bar_prebuf, rst_n, 1'b1);

  bufferH16$  bufferH16$_Q0(Q0, Q0_prebuf);
  bufferH16$  bufferH16$_Q1(Q1, Q1_prebuf);
  bufferH16$  bufferH16$_Q2(Q2, Q2_prebuf);
  bufferH16$  bufferH16$_Q3(Q3, Q3_prebuf);
  bufferH16$  bufferH16$_Q0_bar(Q0_bar, Q0_bar_prebuf);
  bufferH16$  bufferH16$_Q1_bar(Q1_bar, Q1_bar_prebuf);
  bufferH16$  bufferH16$_Q2_bar(Q2_bar, Q2_bar_prebuf);
  bufferH16$  bufferH16$_Q3_bar(Q3_bar, Q3_bar_prebuf);

    // state==S_IDLE: state=0000
    wire state_is_IDLE, state_is_IDLE_prebuf, state_is_REP_CMPS0, state_is_REP_CMPS1, state_is_REP_CMPS2, state_is_REP_MOVS0, state_is_REP_MOVS1, next_state_not_IDLE;
    wire state_is_IRET0, state_is_IRET1, state_is_INTEX_INIT1, state_is_INTEX_INIT0;
    nor4$ nor_state_is_IDLE(state_is_IDLE_prebuf, state[0], state[1], state[2], state[3]);
    bufferH16$  bufferH16$_state_is_IDLE(state_is_IDLE, state_is_IDLE_prebuf);
    nor4$ nor_state_is_REP_MOVS0(state_is_REP_MOVS0, Q3, Q2, Q1, Q0_bar);
    nor4$ nor_state_is_REP_MOVS1(state_is_REP_MOVS1, Q3, Q2, Q1_bar, Q0);
    nor4$ nor_state_is_REP_CMPS0(state_is_REP_CMPS0, Q3, Q2, Q1_bar, Q0_bar);
    nor4$ nor_state_is_REP_CMPS1(state_is_REP_CMPS1, Q3, Q2_bar, Q1, Q0);
    nor4$ nor_state_is_REP_CMPS2(state_is_REP_CMPS2, Q3, Q2_bar, Q1, Q0_bar);
    nor4$ nor_state_is_INTEX_INIT0(state_is_INTEX_INIT0, Q3, Q2_bar, Q1_bar, Q0);
    nor4$ nor_state_is_INTEX_INIT1(state_is_INTEX_INIT1, Q3, Q2_bar, Q1_bar, Q0_bar);
    nor4$ nor_state_is_IRET0(state_is_IRET0, Q3_bar, Q2, Q1, Q0);
    nor4$ nor_state_is_IRET1(state_is_IRET1, Q3_bar, Q2, Q1, Q0_bar);
    nor4$ nor_not_intex_or_iret(not_intex_or_iret, state_is_INTEX_INIT0, state_is_INTEX_INIT1, state_is_IRET0, state_is_IRET1);
    and3$ and_counter_start(counter_start, state_is_IDLE, rep, to_rr_valid);
    or2$ or_counter_dec(counter_dec, state_is_REP_CMPS0, state_is_REP_MOVS0);
    nor4$ nor_ucode_stall_bar(ucode_stall_bar, D3, D2, D1, D0);

    wire next_state_is_IDLE, idle_valid;
    nor4$ nor_next_state_is_IDLE(next_state_is_IDLE, d3_in, d2_in, d1_in, d0_in);
    and2$ and2_idle_valid(idle_valid, to_rr_valid, next_state_is_IDLE);
    mux2$ mux_valid(ucode_valid, 1'b1, idle_valid, state_is_IDLE);

    // assign counter_start        = (state == S_IDLE) & rep & to_rr_valid;
    // assign counter_dec          = ((state == S_REP_CMPS0) | (state == S_REP_MOVS0));
    // stall: state=S_IDLE & next_state != S_IDLE || state != S_IDLE & next_state != S_IDLE
    // assign ucode_stall_bar          = ~(next_state != S_IDLE);
    // assign ucode_valid          = (state == S_IDLE) ? (to_rr_valid & next_state == S_IDLE) : 1'b1;
    // wire [95:0] sig_reg_rm, sig_ext_rm, sig_idle;
    // wire addr_mode, addr_mode_prebuf; // 1 for mem mode, 1 for reg mode
    // nand2$ nand_addrmode(addr_mode_prebuf, modrm[1], modrm[0]);
    // bufferH16$  bufferH16$_addr_mode(addr_mode, addr_mode_prebuf);
    // mux2_64 mux2_reg_rm64(.in0(sig_reg[95:32]), .in1(sig_mem[95:32]), .s0(addr_mode), .out(sig_reg_rm[95:32]));
    // mux2_32 mux2_reg_rm32(.in0(sig_reg[31:0]), .in1(sig_mem[31:0]), .s0(addr_mode), .out(sig_reg_rm[31:0]));
    // mux2_64 mux2_ext_rm64(.in0(sig_ext[95:32]), .in1(sig_ext_mem[95:32]), .s0(addr_mode), .out(sig_ext_rm[95:32]));
    // mux2_32 mux2_ext_rm32(.in0(sig_ext[31:0]), .in1(sig_ext_mem[31:0]), .s0(addr_mode), .out(sig_ext_rm[31:0]));

    // mux4_64 mux4_sig64(.in0(sig_reg[95:32]), .in1(sig_reg_rm[95:32]), .in2(sig_ext[95:32]), .in3(sig_ext_rm[95:32]), .s0(has_modrm), .s1(ext_opcode), .out(sig_idle[95:32]));
    // mux4_32 mux4_sig32(.in0(sig_reg[31:0]), .in1(sig_reg_rm[31:0]), .in2(sig_ext[31:0]), .in3(sig_ext_rm[31:0]), .s0(has_modrm), .s1(ext_opcode), .out(sig_idle[31:0]));

    // mux2_64 mux2_ucode_sig64(.in0(sig_reg[95:32]), .in1(sig_idle[95:32]), .s0(state_is_IDLE), .out(ucode_sig[95:32]));
    // mux2_32 mux2_ucode_sig32(.in0(sig_reg[31:0]), .in1(sig_idle[31:0]), .s0(state_is_IDLE), .out(ucode_sig[31:0]));
    // assign ucode_sig = (state == S_IDLE) ? sig_idle : sig_reg;
    assign movs0 = state_is_REP_MOVS0;
    assign movs1 = state_is_REP_MOVS1;
    assign cmps0 = state_is_REP_CMPS0;
    assign cmps1 = state_is_REP_CMPS1;
    assign cmps2 = state_is_REP_CMPS2;
    assign iret0 = state_is_IRET0;
    assign intex = state_is_INTEX_INIT1;
    and2$ and2_clear_int(clear_int, state_is_INTEX_INIT1, next_state_is_IDLE);
    // assign clear_int = state_is_INTEX_INIT1;
    or2$ or2_handling_intex(handling_intex, state_is_INTEX_INIT0, state_is_INTEX_INIT1);
    // assign cmps0 = (state == S_REP_CMPS0);
    // assign cmps1 = (state == S_REP_CMPS1);
    // assign cmps2 = (state == S_REP_CMPS2);
    // assign iret0 = (state == S_IRET0);
    // assign intex = (state == S_INTEX_INIT1);
    // assign clear_int = (state == S_INTEX_INIT1);
    // assign handling_intex = (state == S_INTEX_INIT0) | (state == S_INTEX_INIT1);

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
    wire [31:0] counter, counter_bar, next_counter;
    wire we, start_or_dec, stall_bar;
    inv1$ inv_stall_bar(stall_bar, stall);
    or2$ or_start_or_dec(start_or_dec, start, dec);
    and2$ and_we(we, start_or_dec, stall_bar);

    reg32e$ reg32e$_inst(clk, next_counter, counter, counter_bar, rst_n, 1'b1, we);
    
    wire [31:0] counter_minus_1;
    big_decrement #(
    .WIDTH(32)
    ) big_decrement_counter (
    .a(counter),
    .s(counter_minus_1)
    );

    mux2_32 mux_next_counter(next_counter, counter_minus_1, reg_ecx, start);

    wire big_or_out;
    big_or #(
      .WIDTH(32)
    ) big_or_counter (
      .out(big_or_out),
      .in(counter)
    );
    inv1$ inv_counter_finish(counter_finish, big_or_out);

endmodule