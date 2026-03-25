module regunit_tb;
    initial begin
        $vcdplusfile("regunit_tb.dump.vpd");
        $vcdpluson(0, regunit_tb); 
    end

    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    reg clk;
    reg rst_n;
    reg [7:0] from_rr_opcode;
    reg [5:0] from_rr_modrm;
    reg [5:0] from_rr_sib;
    reg from_rr_has_sib;
    reg [2:0] from_rr_sig_gprd0_mux;
    reg [1:0] from_rr_sig_gprd2_mux;
    reg from_rr_sig_srcregA_mux;
    reg from_rr_sig_srcregB_mux;
    reg [1:0] from_rr_sig_ds;
    wire [31:0] to_rr_srcregA;
    wire [31:0] to_rr_srcregB;
    wire [31:0] to_rr_srcregC;
    wire [31:0] to_rr_basereg1;
    wire [31:0] to_rr_indexreg1;
    wire [31:0] to_rr_basereg2;
    wire [2:0] to_dep_srcregA_idx;
    wire [2:0] to_dep_srcregB_idx;
    wire [2:0] to_dep_srcregC_idx;
    wire [2:0] to_dep_basereg1_idx;
    wire [2:0] to_dep_indexreg1_idx;
    wire [2:0] to_dep_basereg2_idx;
    reg from_rr_sig_srcsreg_mux;
    reg [2:0] from_rr_seg_prefix;
    reg from_rr_sig_segrd0_mux;
    reg from_rr_sig_segrd1_mux;
    wire [15:0] to_rr_srcSREG;
    wire [15:0] to_rr_SREG1;
    wire [15:0] to_rr_SREG2;
    wire [19:0] to_rr_SLIM1;
    wire [19:0] to_rr_SLIM2;
    wire [15:0] CS;
    wire [19:0] CS_LIMIT;
    wire [2:0] to_dep_srcSREG_idx;
    wire [2:0] to_dep_SREG1_idx;
    wire [2:0] to_dep_SREG2_idx;
    wire [63:0] to_rr_MMA;
    wire [63:0] to_rr_MMB;
    wire [2:0] to_dep_MMA_idx;
    wire [2:0] to_dep_MMB_idx;
    reg [2:0] from_wb_gpwr0_idx;
    reg [31:0] from_wb_gpwr0_data;
    reg [1:0] from_wb_gpwr0_size;
    reg from_wb_gpwr0_en;
    reg [2:0] from_wb_gpwr1_idx;
    reg [31:0] from_wb_gpwr1_data;
    reg [1:0] from_wb_gpwr1_size;
    reg from_wb_gpwr1_en;
    reg [2:0] from_wb_segwr_idx;
    reg [15:0] from_wb_segwr_data;
    reg from_wb_segwr_en;
    reg [15:0] from_ex_cs_wr_data;
    reg from_ex_cs_wr_en;
    reg [2:0] from_wb_mmxwr_idx;
    reg [63:0] from_wb_mmxwr_data;
    reg from_wb_mmxwr_en;

    regunit dut (
        .clk(clk),
        .rst_n(rst_n),
        .from_rr_opcode(from_rr_opcode),
        .from_rr_modrm(from_rr_modrm),
        .from_rr_sib(from_rr_sib),
        .from_rr_has_sib(from_rr_has_sib),
        .from_rr_sig_gprd0_mux(from_rr_sig_gprd0_mux),
        .from_rr_sig_gprd2_mux(from_rr_sig_gprd2_mux),
        .from_rr_sig_srcregA_mux(from_rr_sig_srcregA_mux),
        .from_rr_sig_srcregB_mux(from_rr_sig_srcregB_mux),
        .from_rr_sig_ds(from_rr_sig_ds),
        .to_rr_srcregA(to_rr_srcregA),
        .to_rr_srcregB(to_rr_srcregB),
        .to_rr_srcregC(to_rr_srcregC),
        .to_rr_basereg1(to_rr_basereg1),
        .to_rr_indexreg1(to_rr_indexreg1),
        .to_rr_basereg2(to_rr_basereg2),
        .to_dep_srcregA_idx(to_dep_srcregA_idx),
        .to_dep_srcregB_idx(to_dep_srcregB_idx),
        .to_dep_srcregC_idx(to_dep_srcregC_idx),
        .to_dep_basereg1_idx(to_dep_basereg1_idx),
        .to_dep_indexreg1_idx(to_dep_indexreg1_idx),
        .to_dep_basereg2_idx(to_dep_basereg2_idx),
        .from_rr_sig_srcsreg_mux(from_rr_sig_srcsreg_mux),
        .from_rr_seg_prefix(from_rr_seg_prefix),
        .from_rr_sig_segrd0_mux(from_rr_sig_segrd0_mux),
        .from_rr_sig_segrd1_mux(from_rr_sig_segrd1_mux),
        .to_rr_srcSREG(to_rr_srcSREG),
        .to_rr_SREG1(to_rr_SREG1),
        .to_rr_SREG2(to_rr_SREG2),
        .to_rr_SLIM1(to_rr_SLIM1),
        .to_rr_SLIM2(to_rr_SLIM2),
        .CS(CS),
        .CS_LIMIT(CS_LIMIT),
        .to_dep_srcSREG_idx(to_dep_srcSREG_idx),
        .to_dep_SREG1_idx(to_dep_SREG1_idx),
        .to_dep_SREG2_idx(to_dep_SREG2_idx),
        .to_rr_MMA(to_rr_MMA),
        .to_rr_MMB(to_rr_MMB),
        .to_dep_MMA_idx(to_dep_MMA_idx),
        .to_dep_MMB_idx(to_dep_MMB_idx),
        .from_wb_gpwr0_idx(from_wb_gpwr0_idx),
        .from_wb_gpwr0_data(from_wb_gpwr0_data),
        .from_wb_gpwr0_size(from_wb_gpwr0_size),
        .from_wb_gpwr0_en(from_wb_gpwr0_en),
        .from_wb_gpwr1_idx(from_wb_gpwr1_idx),
        .from_wb_gpwr1_data(from_wb_gpwr1_data),
        .from_wb_gpwr1_size(from_wb_gpwr1_size),
        .from_wb_gpwr1_en(from_wb_gpwr1_en),
        .from_wb_segwr_idx(from_wb_segwr_idx),
        .from_wb_segwr_data(from_wb_segwr_data),
        .from_wb_segwr_en(from_wb_segwr_en),
        .from_ex_cs_wr_data(from_ex_cs_wr_data),
        .from_ex_cs_wr_en(from_ex_cs_wr_en),
        .from_wb_mmxwr_idx(from_wb_mmxwr_idx),
        .from_wb_mmxwr_data(from_wb_mmxwr_data),
        .from_wb_mmxwr_en(from_wb_mmxwr_en)
    );

    always #5 clk = ~clk;

    task clear_inputs;
    begin
            from_rr_opcode = 8'd0;
            from_rr_modrm = 6'd0;
            from_rr_sib = 6'd0;
            from_rr_has_sib = 1'b0;
            from_rr_sig_gprd0_mux = 3'd0;
            from_rr_sig_gprd2_mux = 2'd0;
            from_rr_sig_srcregA_mux = 1'b0;
            from_rr_sig_srcregB_mux = 1'b0;
            from_rr_sig_ds = 2'd0;
            from_rr_sig_srcsreg_mux = 1'b0;
            from_rr_seg_prefix = 3'd0;
            from_rr_sig_segrd0_mux = 1'b0;
            from_rr_sig_segrd1_mux = 1'b0;
            from_wb_gpwr0_idx = 3'd0;
            from_wb_gpwr0_data = 32'd0;
            from_wb_gpwr0_size = 2'd0;
            from_wb_gpwr0_en = 1'b0;
            from_wb_gpwr1_idx = 3'd0;
            from_wb_gpwr1_data = 32'd0;
            from_wb_gpwr1_size = 2'd0;
            from_wb_gpwr1_en = 1'b0;
            from_wb_segwr_idx = 3'd0;
            from_wb_segwr_data = 16'd0;
            from_wb_segwr_en = 1'b0;
            from_ex_cs_wr_data = 16'd0;
            from_ex_cs_wr_en = 1'b0;
            from_wb_mmxwr_idx = 3'd0;
            from_wb_mmxwr_data = 64'd0;
            from_wb_mmxwr_en = 1'b0;
    end
    endtask

    task apply_rr_inputs;
        input [7:0] opcode;
        input [5:0] modrm;
        input [5:0] sib;
        input has_sib;
        input [2:0] sig_gprd0_mux;
        input [1:0] sig_gprd2_mux;
        input sig_srcregA_mux;
        input sig_srcregB_mux;
        input [1:0] sig_ds;
        input sig_srcsreg_mux;
        input [2:0] seg_prefix;
    begin 
        from_rr_opcode = opcode;
        from_rr_modrm = modrm;
        from_rr_sib = sib;
        from_rr_has_sib = has_sib;
        from_rr_sig_gprd0_mux = sig_gprd0_mux;
        from_rr_sig_gprd2_mux = sig_gprd2_mux;
        from_rr_sig_srcregA_mux = sig_srcregA_mux;
        from_rr_sig_srcregB_mux = sig_srcregB_mux;
        from_rr_sig_ds = sig_ds;
        from_rr_sig_srcsreg_mux = sig_srcsreg_mux;
        from_rr_seg_prefix = seg_prefix;
    end
    endtask

    task apply_exwb_inputs;
        input [2:0] gpwr0_idx;
        input [31:0] gpwr0_data;
        input [1:0] gpwr0_size;
        input gpwr0_en;
        input [2:0] gpwr1_idx;
        input [31:0] gpwr1_data;
        input [1:0] gpwr1_size;
        input gpwr1_en;
        input [2:0] segwr_idx;
        input [15:0] segwr_data;
        input segwr_en;
        input [15:0] cs_wr_data;
        input cs_wr_en;
        input [2:0] mmxwr_idx;
        input [63:0] mmxwr_data;
        input mmxwr_en;
    begin 
        from_wb_gpwr0_idx   = gpwr0_idx; 
        from_wb_gpwr0_data  = gpwr0_data;
        from_wb_gpwr0_size  = gpwr0_size;
        from_wb_gpwr0_en    = gpwr0_en;  
        from_wb_gpwr1_idx   = gpwr1_idx; 
        from_wb_gpwr1_data  = gpwr1_data;
        from_wb_gpwr1_size  = gpwr1_size;
        from_wb_gpwr1_en    = gpwr1_en;  
        from_wb_segwr_idx   = segwr_idx; 
        from_wb_segwr_data  = segwr_data;
        from_wb_segwr_en    = segwr_en;  
        from_ex_cs_wr_data  = cs_wr_data;
        from_ex_cs_wr_en    = cs_wr_en;  
        from_wb_mmxwr_idx   = mmxwr_idx; 
        from_wb_mmxwr_data  = mmxwr_data;
        from_wb_mmxwr_en    = mmxwr_en;  
    end
    endtask

    task print_all_outputs;
    begin
        $display("srcregA=(%0d)%08h, srcregB=(%0d)%08h, srcregC=(%0d)%08h", to_dep_srcregA_idx, to_rr_srcregA, to_dep_srcregB_idx, to_rr_srcregB, to_dep_srcregC_idx, to_rr_srcregC);
        $display("basereg1=(%0d)%08h, indexreg1=(%0d)%08h, basereg2=(%0d)%08h", to_dep_basereg1_idx, to_rr_basereg1, to_dep_indexreg1_idx, to_rr_indexreg1, to_dep_basereg2_idx, to_rr_basereg2);
        $display("srcSREG=(%0d)%04h, SREG1:SLIM1=(%0d)%04h : %05h, SREG2:SLIM2=(%0d)%04h : %05h, CS=%04h", to_dep_srcSREG_idx, to_rr_srcSREG, to_dep_SREG1_idx, to_rr_SREG1, to_rr_SLIM1, to_dep_SREG2_idx, to_rr_SREG2, to_rr_SLIM2, CS);
        $display("MMA=(%0d)%0h, MMB=(%0d)%0h", to_dep_MMA_idx, to_rr_MMA, to_dep_MMB_idx, to_rr_MMB);
    end
    endtask
    integer i;

    initial begin 
        clk = 1'b0;
        rst_n = 1'b0;
        clear_inputs();
        @(posedge clk);
        @(posedge clk);
        rst_n = 1'b1;

        @(negedge clk);
        apply_exwb_inputs(3'd0, 32'h0000_0000, 2'b10, 1'b1, 3'd0, 32'b0, 2'b10, 1'b0, 3'd0, 16'h0000, 1'b1, 16'h1111, 1'b1, 3'd0, 64'h0000_0000_0000_0000, 1'b1);
        @(negedge clk);
        apply_exwb_inputs(3'd1, 32'h1111_1111, 2'b10, 1'b1, 3'd0, 32'b0, 2'b10, 1'b0, 3'd1, 16'h1111, 1'b0, 16'b0, 1'b0, 3'd1, 64'h1111_1111_1111_1111, 1'b1);
        @(negedge clk);
        apply_exwb_inputs(3'd2, 32'h2222_2222, 2'b10, 1'b1, 3'd0, 32'b0, 2'b10, 1'b0, 3'd2, 16'h2222, 1'b1, 16'b0, 1'b0, 3'd2, 64'h2222_2222_2222_2222, 1'b1);
        @(negedge clk);
        apply_exwb_inputs(3'd3, 32'h3333_3333, 2'b10, 1'b1, 3'd0, 32'b0, 2'b10, 1'b0, 3'd3, 16'h3333, 1'b1, 16'b0, 1'b0, 3'd3, 64'h3333_3333_3333_3333, 1'b1);
        @(negedge clk);
        apply_exwb_inputs(3'd4, 32'h4444_4444, 2'b10, 1'b1, 3'd0, 32'b0, 2'b10, 1'b0, 3'd4, 16'h4444, 1'b1, 16'b0, 1'b0, 3'd4, 64'h4444_4444_4444_4444, 1'b1);
        @(negedge clk);
        apply_exwb_inputs(3'd5, 32'h5555_5555, 2'b10, 1'b1, 3'd0, 32'b0, 2'b10, 1'b0, 3'd5, 16'h5555, 1'b1, 16'b0, 1'b0, 3'd5, 64'h5555_5555_5555_5555, 1'b1);
        @(negedge clk);
        apply_exwb_inputs(3'd6, 32'h6666_6666, 2'b10, 1'b1, 3'd0, 32'b0, 2'b10, 1'b0, 3'd6, 16'h6666, 1'b1, 16'b0, 1'b0, 3'd6, 64'h6666_6666_6666_6666, 1'b1);
        @(negedge clk);
        apply_exwb_inputs(3'd7, 32'h7777_7777, 2'b10, 1'b1, 3'd0, 32'b0, 2'b10, 1'b0, 3'd7, 16'h7777, 1'b1, 16'b0, 1'b0, 3'd7, 64'h7777_7777_7777_7777, 1'b1);

        @(negedge clk);

        
        $display("======================================");
        $display("General Purpose RegFile");
        $display("======================================");
        for(i = 0; i < 8; i = i + 1) begin
            $display("reg[%0d] = %h", i, dut.gprf.q[i]);
        end

        $display("======================================");
        $display("Segement RegFile");
        $display("======================================");
        for(i = 0; i < 8; i = i + 1) begin
            if(i==1) begin 
                $display("reg[%0d](CS) = %h", i, dut.segrf.cs_q);
            end else begin 
                $display("reg[%0d] = %h", i, dut.segrf.seg_rf.q[i]);
            end
        end

        $display("======================================");
        $display("MMX RegFile");
        $display("======================================");
        for(i = 0; i < 8; i = i + 1) begin
            $display("reg[%0d] = %h", i, dut.mmxrf.mmx_regs.q[i]);
        end
        
        $display("======================================");
        $display("TEST CASE1: ADD EAX, ECX");
        $display("======================================");
        // 01 C8=00000001 11001000
        apply_rr_inputs(8'h01, 6'b001000, 6'b0, 1'b0, 3'bx, 2'b00, 1'b1, 1'b1, 2'b10, 1'bx, 3'b0);
        #8
        print_all_outputs();

        $display("======================================");
        $display("TEST CASE2: ADD [EBX], CH");
        $display("======================================");
        // 00 2b=00000000 00101011
        apply_rr_inputs(8'h00, 6'b101011, 6'b0, 1'b0, 3'bx, 2'b10, 1'bx, 1'b1, 2'b00, 1'b1, 3'b011);
        #8
        print_all_outputs();

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        
        $finish;
    end
endmodule