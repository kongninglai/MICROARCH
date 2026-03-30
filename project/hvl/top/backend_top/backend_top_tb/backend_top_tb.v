module backend_top_tb;

    initial begin
        $vcdplusfile("backend_top_tb.dump.vpd");
        $vcdpluson(0, backend_top_tb); 
    end

    integer i;
    integer NUM_TESTS = 0;
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    reg clk;
    reg rst_n;
    reg [5:0] to_rr_prefix;
    reg [7:0] to_rr_opcode;
    reg [7:0] to_rr_modrm;
    reg [7:0] to_rr_sib;
    reg [31:0] to_rr_disp;
    reg [1:0] to_rr_dispsize;
    reg [47:0] to_rr_imm;
    reg [2:0] to_rr_imm_size;
    reg [1:0] to_rr_addr_mode;
    reg [31:0] to_rr_oeip;
    reg [31:0] to_rr_ieip;
    reg [31:0] to_rr_pred_eip;
    reg [1:0] to_rr_exception;
    reg to_rr_valid;
    wire from_rr_stall;
    wire [31:0] from_regunit_cs_limit;
    wire from_ex_flush;
    wire from_ex_br_t_nt;
    wire from_ex_br_valid;
    wire [31:0] from_ex_eip_target;
    wire from_wb_flush;

    backend_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .to_rr_prefix(to_rr_prefix),
        .to_rr_opcode(to_rr_opcode),
        .to_rr_modrm(to_rr_modrm),
        .to_rr_sib(to_rr_sib),
        .to_rr_disp(to_rr_disp),
        .to_rr_dispsize(to_rr_dispsize),
        .to_rr_imm(to_rr_imm),
        .to_rr_imm_size(to_rr_imm_size),
        .to_rr_addr_mode(to_rr_addr_mode),
        .to_rr_oeip(to_rr_oeip),
        .to_rr_ieip(to_rr_ieip),
        .to_rr_pred_eip(to_rr_pred_eip),
        .to_rr_exception(to_rr_exception),
        .to_rr_valid(to_rr_valid),
        .from_rr_stall(from_rr_stall),
        .from_regunit_cs_limit(from_regunit_cs_limit),
        .from_ex_flush(from_ex_flush),
        .from_ex_br_t_nt(from_ex_br_t_nt),
        .from_ex_br_valid(from_ex_br_valid),
        .from_ex_eip_target(from_ex_eip_target),
        .from_wb_flush(from_wb_flush)
    );

    always #5 clk = ~clk;
    
    task clear_inputs;
    begin
            to_rr_prefix = 6'd0;
            to_rr_opcode = 8'd0;
            to_rr_modrm = 8'd0;
            to_rr_sib = 8'd0;
            to_rr_disp = 32'd0;
            to_rr_dispsize = 2'd0;
            to_rr_imm = 48'd0;
            to_rr_imm_size = 3'd0;
            to_rr_addr_mode = 2'd0;
            to_rr_oeip = 32'd0;
            to_rr_ieip = 32'd0;
            to_rr_pred_eip = 32'd0;
            to_rr_exception = 2'd0;
            to_rr_valid = 1'b0;
    end
    endtask

    task apply_inputs;
        input [5:0] prefix;
        input [7:0] opcode;
        input [7:0] modrm;
        input [7:0] sib;
        input [31:0] disp;
        input [1:0] dispsize;
        input [47:0] imm;
        input [2:0] imm_size;
        input [1:0] addr_mode;
        input [31:0] oeip;
        input [31:0] ieip;
        input [31:0] pred_eip;
        input [1:0] exception;
        input valid;
    begin 
        to_rr_prefix      = prefix;          
        to_rr_opcode      = opcode;    
        to_rr_modrm       = modrm;     
        to_rr_sib         = sib;       
        to_rr_disp        = disp;      
        to_rr_dispsize    = dispsize;  
        to_rr_imm         = imm;       
        to_rr_imm_size    = imm_size;  
        to_rr_addr_mode   = addr_mode; 
        to_rr_oeip        = oeip;      
        to_rr_ieip        = ieip;  
        to_rr_pred_eip    = pred_eip;
        to_rr_exception   = exception;    
        to_rr_valid       = valid;     
    end
    endtask

    task print_arch_status;
    begin 
        $display("======================================");
        $display("General Purpose RegFile");
        $display("======================================");
        for(i = 0; i < 8; i = i + 1) begin
            $display("reg[%0d] = %h", i, dut.inst_regunit.gprf.q[i]);
        end

        $display("======================================");
        $display("Segment RegFile");
        $display("======================================");
        for(i = 0; i < 8; i = i + 1) begin
            if(i==1) begin 
                $display("reg[%0d](CS) = %h", i, dut.inst_regunit.segrf.cs_q);
            end else begin 
                $display("reg[%0d] = %h", i, dut.inst_regunit.segrf.seg_rf.q[i]);
            end
        end

        $display("======================================");
        $display("MMX RegFile");
        $display("======================================");
        for(i = 0; i < 8; i = i + 1) begin
            $display("reg[%0d] = %h", i, dut.inst_regunit.mmxrf.mmx_regs.q[i]);
        end
        $display("\n");

        $display("eflags=%08h", dut.inst_stage_ex.eflags_out);
        $display("\n");
    end
    endtask

    task insert_nop; 
        apply_inputs(6'b000110, 8'h01, 8'hc0, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 32'h0, 2'b0, 1'b0);
    endtask

    task test_with_nops;
        input [5:0] prefix;
        input [7:0] opcode;
        input [7:0] modrm;
        input [7:0] sib;
        input [31:0] disp;
        input [1:0] dispsize;
        input [47:0] imm;
        input [2:0] imm_size;
        input [1:0] addr_mode;
        input [31:0] oeip;
        input [31:0] ieip;
        input [31:0] pred_eip;
        input [1:0] exception;
        input valid;
    begin 
        @(posedge clk);
        apply_inputs(prefix, opcode, modrm, sib, disp, dispsize, imm, imm_size, addr_mode, oeip, ieip, pred_eip, exception, valid);
        @(posedge clk); // updated rr_to_ag
        insert_nop();
        @(posedge clk); // updated ag_to_mem
        insert_nop();
        @(posedge clk); // updated mem_to_ex
        insert_nop();
        @(posedge clk); // updated ex_to_wb
        insert_nop();
        @(posedge clk); // updated register files
        insert_nop();
        #8
        print_arch_status();
        $display("\n");
        NUM_TESTS = NUM_TESTS + 1;
    end
    endtask

    initial begin 
        clk = 1'b0;
        rst_n = 1'b0;
        clear_inputs();
        @(posedge clk);
        @(posedge clk);
        rst_n = 1'b1;
        
        print_arch_status();

        $display("======================================");
        $display("[ALU] TEST CASE%0d: ADD BH, 0x8", NUM_TESTS);
        $display("======================================");
        // 80 c7 08
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h80, 8'hc7, 8'bx, 32'bx, 2'b00,
                        48'h8, 3'b001, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);

        $display("======================================");
        $display("[ALU] TEST CASE%0d: ADD EAX, 0x12345678", NUM_TESTS);
        $display("======================================");
        // 05 78 56 34 12
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h05, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h12345678, 3'b100, 2'b00, 32'h0, 32'h5, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("[ALU] TEST CASE%0d: ADD AX, BX", NUM_TESTS);
        $display("======================================");
        // 66 01 D8
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b010110, 8'h01, 8'hD8, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h2, 32'bx, 2'b0, 1'b1);


        $display("======================================");
        $display("[CMPXCHG] TEST CASE%0d: MOV EAX, 0x5", NUM_TESTS);
        $display("======================================");
        // b8 05 00 00 00
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hb8, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h5, 3'b100, 2'b00, 32'h0, 32'h5, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("[CMPXCHG] TEST CASE%0d: MOV EBX, 0x5", NUM_TESTS);
        $display("======================================");
        // bb 05 00 00 00
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hbb, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h5, 3'b100, 2'b00, 32'h0, 32'h5, 32'bx, 2'b0, 1'b1);

        $display("======================================");
        $display("[CMPXCHG] TEST CASE%0d: MOV ECX, 0x9", NUM_TESTS);
        $display("======================================");
        // b9 09 00 00 00
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hb9, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h9, 3'b100, 2'b00, 32'h0, 32'h5, 32'bx, 2'b0, 1'b1);

        $display("======================================");
        $display("[CMPXCHG] TEST CASE%0d: CMPXCHG EBX, ECX", NUM_TESTS);
        $display("======================================");
        // 0f b1 cb
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000111, 8'hb1, 8'hcb, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("[CMPXCHG] TEST CASE%0d: CMPXCHG EBX, ECX", NUM_TESTS);
        $display("======================================");
        // 0f b1 cb
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000111, 8'hb1, 8'hcb, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("[MMX] TEST CASE%0d: MOVQ MM0, [EBX]", NUM_TESTS);
        $display("======================================");
        // 0f 6f 03
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000111, 8'h6f, 8'h03, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("[MMX] TEST CASE%0d: PAVGB MM2, MM0", NUM_TESTS);
        $display("======================================");
        // 0f e0 d0
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000111, 8'he0, 8'hd0, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b01, 32'h0, 32'h3, 32'bx, 2'b0, 1'b1);
        
        $display("======================================");
        $display("[STACK] TEST CASE%0d: MOV ESP 0x1234", NUM_TESTS);
        $display("======================================");
        // bc 34 12 00 00
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'hbc, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'h1234, 3'b100, 2'b00, 32'h0, 32'h5, 32'bx, 2'b0, 1'b1);

        $display("======================================");
        $display("[STACK] TEST CASE%0d: POP DS", NUM_TESTS);
        $display("======================================");
        // 1f
        // prefix(6), opcode(8), modrm(8), sib(8), disp(32), dispsize(2),
        // imm(48), imm_size(3), addr_mode(2), oeip(32), ieip(32), valid
        test_with_nops(6'b000110, 8'h1f, 8'bx, 8'bx, 32'bx, 2'b00,
                        48'bx, 3'b000, 2'b00, 32'h0, 32'h5, 32'bx, 2'b0, 1'b1);

                        
        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule