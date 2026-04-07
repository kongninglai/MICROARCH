module ucode_fsm_tb;
    initial begin
        $vcdplusfile("ucode_fsm_tb.dump.vpd");
        $vcdpluson(0, ucode_fsm_tb); 
    end

    reg         clk;
    reg         rst_n;

    reg         to_rr_valid;
    reg         rep;
    reg         from_ag_stall;
    reg         interrupt;
    reg         exception;
    reg         movs;
    reg         cmps;
    reg         iret;
    reg         cmps_found;

    reg  [7:0]  opcode;
    reg         ext_opcode;
    reg  [1:0]  modrm;
    reg         has_modrm;

    reg  [31:0] reg_ecx;

    wire        cmps0;
    wire        cmps1;
    wire        ucode_stall;
    wire        ucode_valid;
    wire [95:0] ucode_sig;
    
    // DUT
    ucode_fsm dut (
        .clk(clk),
        .rst_n(rst_n),
        .to_rr_valid(to_rr_valid),
        .rep(rep),
        .from_ag_stall(from_ag_stall),
        .interrupt(interrupt),
        .exception(exception),
        .movs(movs),
        .cmps(cmps),
        .iret(iret),
        .cmps_found(cmps_found),
        .opcode(opcode),
        .ext_opcode(ext_opcode),
        .modrm(modrm),
        .has_modrm(has_modrm),
        .reg_ecx(reg_ecx),
        .cmps0(cmps0),
        .cmps1(cmps1),
        .ucode_stall(ucode_stall),
        .ucode_valid(ucode_valid),
        .ucode_sig(ucode_sig)
    );

    wire [1:0] ldAB, dstidB_mux, gprd0_mux, gprd2_mux, shf_srcb_mux, cs_mux, mm_dst_mux, rw, ds, mem_ds, imm_mux, addr_mux;
    wire [2:0] dstidA_mux, ldREGS, eflags_mux, eip_mux, gp_dstb_mux;
    wire gprd1_mux, srcregA_mux, srcregB_mux, ldEFLAGS, alu_srcb_mux, ldEIP, ldCS, seg_dst_mux, srcsreg_mux, segrd0_mux, segrd1_mux, rm;
    wire [10:0] needREGS;
    wire [3:0] gp_dsta_mux, store_data_mux;

    rr_sig rr_sig_dut(
    .ucode_sig(ucode_sig), .ldAB(ldAB), .dstidA_mux(dstidA_mux), .dstidB_mux(dstidB_mux),
    .srcregA_mux(srcregA_mux), .srcregB_mux(srcregB_mux), .gprd0_mux(gprd0_mux), .gprd1_mux(gprd1_mux), .gprd2_mux(gprd2_mux), .srcsreg_mux(srcsreg_mux), .segrd0_mux(segrd0_mux), .segrd1_mux(segrd1_mux),
    .ldREGS(ldREGS), .needREGS(needREGS), .ldEFLAGS(ldEFLAGS),
    .alu_srcb_mux(alu_srcb_mux), .shf_srcb_mux(shf_srcb_mux),
    .ldEIP(ldEIP), .ldCS(ldCS), .eflags_mux(eflags_mux), .eip_mux(eip_mux), .cs_mux(cs_mux),
    .gp_dsta_mux(gp_dsta_mux), .gp_dstb_mux(gp_dstb_mux), .seg_dst_mux(seg_dst_mux), .mm_dst_mux(mm_dst_mux),
    .store_data_mux(store_data_mux), .rw(rw), .ds(ds), .mem_ds(mem_ds), .imm_mux(imm_mux), .addr_mux(addr_mux), .rm(rm)
    );

    // ---------------- clock ----------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    task print_to_rr_sigs;
    begin 
        $display("----------------------------------------------------------------");
        $display("ldAB=%02b, dstidA_mux=%03b, dstidB_mux=%02b", ldAB, dstidA_mux, dstidB_mux);
        $display("gprd0_mux=%02b, gprd1_mux=%0b, gprd2_mux=%-2b", gprd0_mux, gprd1_mux, gprd2_mux);
        $display("ldREGS=%03b, ldEFLAGS=%0b, ldEIP=%0b, ldCS=%0b", ldREGS, ldEFLAGS, ldEIP, ldCS);
        $display("alu_srcb_mux=%0b, shf_srcb_mux=%02b", alu_srcb_mux, shf_srcb_mux);
        $display("eflags_mux=%03b, eip_mux=%03b, cs_mux=%02b", eflags_mux, eip_mux, cs_mux);
        $display("gp_dsta_mux=%04b, gp_dstb_mux=%03b, seg_dst_mux=%0b, mm_dst_mux=%02b", gp_dsta_mux, gp_dstb_mux, seg_dst_mux, mm_dst_mux);
        $display("store_data_mux=%04b", store_data_mux);
        $display("rw=%02b, ds=%02b", rw, ds);
        $display("mem_ds=%02b, imm_mux=%02b, addr_mux=%02b", mem_ds, imm_mux, addr_mux);
        $display("rm=%0b", rm);
        $display("----------------------------------------------------------------");
    end
    endtask

    // ---------------- helpers ----------------
    task clear_inputs;
    begin
        to_rr_valid    = 1'b0;
        rep            = 1'b0;
        from_ag_stall  = 1'b0;
        interrupt      = 1'b0;
        exception      = 1'b0;
        movs           = 1'b0;
        cmps           = 1'b0;
        iret           = 1'b0;
        cmps_found     = 1'b0;
        opcode         = 8'h00;
        ext_opcode     = 1'b0;
        modrm          = 2'b11;
        has_modrm      = 1'b0;
        reg_ecx        = 32'd0;
    end
    endtask

    task reset_dut;
    begin
        clear_inputs();
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
    end
    endtask

    task show_status;
    begin
        $display("time=%0t state=%0d next=%0d stall=%0b valid=%0b counter=%0d opcode=%0d",
                 $time,
                 dut.state,
                 dut.next_state,
                 ucode_stall,
                 ucode_valid,
                 dut.ecx_counter_inst.counter,
                 dut.ucode_opcode);
        print_to_rr_sigs();
    end
    endtask

    task step;
        input integer n;
        integer i;
    begin
        show_status();
        for (i = 0; i < n; i = i + 1) begin
            @(posedge clk);
            #1;
            show_status();
        end
    end
    endtask

    task send_normal_instr;
        input [7:0] opc;
    begin
        @(posedge clk);
        to_rr_valid = 1'b1;
        opcode      = opc;
        rep         = 1'b0;
        movs        = 1'b0;
        cmps        = 1'b0;
        iret        = 1'b0;
    end
    endtask

    // rep movs
    task send_rep_movs;
        input [7:0] opc;
        input [31:0] ecx_init;
    begin
        @(posedge clk);
        to_rr_valid = 1'b1;
        opcode      = opc;
        rep         = 1'b1;
        movs        = 1'b1;
        cmps        = 1'b0;
        iret        = 1'b0;
        reg_ecx     = ecx_init;
    end
    endtask

    // rep cmps
    task send_rep_cmps;
        input [7:0] opc;
        input [31:0] ecx_init;
    begin
        @(posedge clk);
        to_rr_valid = 1'b1;
        opcode      = opc;
        rep         = 1'b1;
        movs        = 1'b0;
        cmps        = 1'b1;
        iret        = 1'b0;
        reg_ecx     = ecx_init;
    end
    endtask

    task send_iret;
    begin
        @(posedge clk);
        to_rr_valid = 1'b1;
        rep         = 1'b0;
        movs        = 1'b0;
        cmps        = 1'b0;
        iret        = 1'b1;
    end
    endtask

    task raise_interrupt;
    begin
        @(posedge clk);
        interrupt = 1'b1;
    end
    endtask

    task raise_exception;
    begin
        @(posedge clk);
        exception = 1'b1;
    end
    endtask

    task pulse_cmps_found;
    begin
        @(posedge clk);
        cmps_found = 1'b1;
        @(posedge clk);
        cmps_found = 1'b0;
    end
    endtask

    task hold_ag_stall;
        input integer n;
        integer i;
    begin
        @(posedge clk);
        from_ag_stall = 1'b1;
        for (i = 0; i < n; i = i + 1)
            @(posedge clk);
        @(posedge clk);
        from_ag_stall = 1'b0;
    end
    endtask

    // ---------------- test sequence ----------------
    initial begin
        reset_dut();

        // $display("\n==== TEST 1: idle with normal instruction ====");
        // send_normal_instr(8'h90);
        // step(3);

        // $display("\n==== TEST 2: rep movs, ecx=3 ====");
        // reset_dut();
        // send_rep_movs(8'hA4, 32'd3);
        // step(8);

        $display("\n==== TEST 3: rep cmps, ecx=3 ====");
        reset_dut();
        send_rep_cmps(8'hA6, 32'd3);
        step(10);

        // $display("\n==== TEST 4: rep cmps interrupted by cmps_found ====");
        // reset_dut();
        // send_rep_cmps(8'hA6, 32'd5);
        // step(2);
        // pulse_cmps_found();
        // step(4);

        // $display("\n==== TEST 5: interrupt from IDLE ====");
        // reset_dut();
        // raise_interrupt();
        // step(4);

        // $display("\n==== TEST 6: exception during rep movs ====");
        // reset_dut();
        // send_rep_movs(8'hA4, 32'd4);
        // step(2);
        // raise_exception();
        // step(5);

        // $display("\n==== TEST 7: iret ====");
        // reset_dut();
        // send_iret();
        // step(5);

        // $display("\n==== TEST 8: from_ag_stall holds FSM ====");
        // reset_dut();
        // send_rep_movs(8'hA4, 32'd3);
        // step(1);
        // hold_ag_stall(3);
        // step(5);

        // $display("\n==== DONE ====");
        $finish;
    end

endmodule