module ucode_fsm_tb;

    // initial begin
    //     // $vcdplusfile("ucode_fsm_tb.dump.vpd");
    //     // $vcdpluson(0, ucode_fsm_tb); 
    // end
    // ----------------------------
    // inputs
    // ----------------------------
    reg         clk;
    reg         rst_n;

    reg         to_rr_valid;
    reg         rep;
    reg         stall;
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

    // ----------------------------
    // outputs: behavioral
    // ----------------------------
    wire        bh_cmps0;
    wire        bh_cmps1;
    wire        bh_cmps2;
    wire        bh_iret0;
    wire        bh_clear_int;
    wire        bh_intex;
    wire        bh_handling_intex;
    wire        bh_ucode_stall_bar;
    wire        bh_ucode_valid;
    wire [95:0] bh_ucode_sig;

    // ----------------------------
    // outputs: structural
    // ----------------------------
    wire        st_cmps0;
    wire        st_cmps1;
    wire        st_cmps2;
    wire        st_iret0;
    wire        st_clear_int;
    wire        st_intex;
    wire        st_handling_intex;
    wire        st_ucode_stall_bar;
    wire        st_ucode_valid;
    wire [95:0] st_ucode_sig;

    integer FAILURES;
    integer SUCCESSES;

    // ----------------------------
    // behavioral golden
    // ----------------------------
    ucode_fsm_bh DUT_BH (
        .clk(clk),
        .rst_n(rst_n),
        .to_rr_valid(to_rr_valid),
        .rep(rep),
        .stall(stall),
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
        .cmps0(bh_cmps0),
        .cmps1(bh_cmps1),
        .cmps2(bh_cmps2),
        .iret0(bh_iret0),
        .clear_int(bh_clear_int),
        .intex(bh_intex),
        .handling_intex(bh_handling_intex),
        .ucode_stall_bar(bh_ucode_stall_bar),
        .ucode_valid(bh_ucode_valid),
        .ucode_sig(bh_ucode_sig)
    );

    // ----------------------------
    // structural DUT
    // replace port list if needed
    // ----------------------------
    ucode_fsm DUT_ST (
        .clk(clk),
        .rst_n(rst_n),
        .to_rr_valid(to_rr_valid),
        .rep(rep),
        .stall(stall),
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
        .cmps0(st_cmps0),
        .cmps1(st_cmps1),
        .cmps2(st_cmps2),
        .iret0(st_iret0),
        .clear_int(st_clear_int),
        .intex(st_intex),
        .handling_intex(st_handling_intex),
        .not_intex_or_iret(),
        .ucode_stall_bar(st_ucode_stall_bar),
        .ucode_valid(st_ucode_valid),
        .ucode_sig(st_ucode_sig)
    );

    // ----------------------------
    // clock
    // ----------------------------
    initial clk = 1'b0;
    always #10 clk = ~clk;

    // ----------------------------
    // helpers
    // ----------------------------
    task clear_inputs;
    begin
        to_rr_valid  = 1'b0;
        rep          = 1'b0;
        stall        = 1'b0;
        interrupt    = 1'b0;
        exception    = 1'b0;
        movs         = 1'b0;
        cmps         = 1'b0;
        iret         = 1'b0;
        cmps_found   = 1'b0;
        opcode       = 8'h90;
        ext_opcode   = 1'b0;
        modrm        = 2'b11;
        has_modrm    = 1'b0;
        reg_ecx      = 32'd0;
    end
    endtask

    task reset_dut;
    begin
        clear_inputs();
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        check_outputs("after reset");
    end
    endtask

    task check_outputs;
        input [255:0] tag;
    begin
        #8;

        if (bh_cmps0           !== st_cmps0 ||
            bh_cmps1           !== st_cmps1 ||
            bh_cmps2           !== st_cmps2 ||
            bh_iret0           !== st_iret0 ||
            bh_clear_int       !== st_clear_int ||
            bh_intex           !== st_intex ||
            bh_handling_intex  !== st_handling_intex ||
            bh_ucode_stall_bar     !== st_ucode_stall_bar ||
            bh_ucode_valid     !== st_ucode_valid ||
            bh_ucode_sig       !== st_ucode_sig) begin

            // $display("====================================================");
            // $display("[FAIL] %0s at time=%0t", tag, $time);
            // $display("inputs: valid=%0b rep=%0b stall=%0b intr=%0b exc=%0b movs=%0b cmps=%0b iret=%0b cmps_found=%0b reg_ecx=%0d opcode=%0h ext=%0b modrm=%0b has_modrm=%0b",
            //          to_rr_valid, rep, stall, interrupt, exception, movs, cmps, iret, cmps_found,
            //          reg_ecx, opcode, ext_opcode, modrm, has_modrm);

            // $display("BH : cmps0=%0b cmps1=%0b cmps2=%0b iret0=%0b clear_int=%0b intex=%0b handling_intex=%0b stall=%0b valid=%0b sig=%h",
            //          bh_cmps0, bh_cmps1, bh_cmps2, bh_iret0, bh_clear_int, bh_intex,
            //          bh_handling_intex, bh_ucode_stall_bar, bh_ucode_valid, bh_ucode_sig);

            // $display("ST : cmps0=%0b cmps1=%0b cmps2=%0b iret0=%0b clear_int=%0b intex=%0b handling_intex=%0b stall=%0b valid=%0b sig=%h",
            //          st_cmps0, st_cmps1, st_cmps2, st_iret0, st_clear_int, st_intex,
            //          st_handling_intex, st_ucode_stall_bar, st_ucode_valid, st_ucode_sig);

            // // internal state compare if visible
            // $display("BH state=%0d next=%0d | ST state=%0d next=%0d",
            //          DUT_BH.state, DUT_BH.next_state, DUT_ST.state, DUT_ST.next_state);

            FAILURES = FAILURES + 1;
        end else begin
            // $display("====================================================");
            // $display("[PASS] %0s at time=%0t", tag, $time);
            // $display("inputs: valid=%0b rep=%0b stall=%0b intr=%0b exc=%0b movs=%0b cmps=%0b iret=%0b cmps_found=%0b reg_ecx=%0d opcode=%0h ext=%0b modrm=%0b has_modrm=%0b",
            //          to_rr_valid, rep, stall, interrupt, exception, movs, cmps, iret, cmps_found,
            //          reg_ecx, opcode, ext_opcode, modrm, has_modrm);

            // $display("BH : cmps0=%0b cmps1=%0b cmps2=%0b iret0=%0b clear_int=%0b intex=%0b handling_intex=%0b stall=%0b valid=%0b sig=%h",
            //          bh_cmps0, bh_cmps1, bh_cmps2, bh_iret0, bh_clear_int, bh_intex,
            //          bh_handling_intex, bh_ucode_stall_bar, bh_ucode_valid, bh_ucode_sig);

            // $display("ST : cmps0=%0b cmps1=%0b cmps2=%0b iret0=%0b clear_int=%0b intex=%0b handling_intex=%0b stall=%0b valid=%0b sig=%h",
            //          st_cmps0, st_cmps1, st_cmps2, st_iret0, st_clear_int, st_intex,
            //          st_handling_intex, st_ucode_stall_bar, st_ucode_valid, st_ucode_sig);

            // // internal state compare if visible
            // $display("BH state=%0d next=%0d | ST state=%0d next=%0d",
            //          DUT_BH.state, DUT_BH.next_state, DUT_ST.state, DUT_ST.next_state);

            SUCCESSES = SUCCESSES + 1;
        end
    end
    endtask

    task step_and_check;
        input [255:0] tag;
    begin
        @(posedge clk);
        check_outputs(tag);
    end
    endtask

    task pulse_interrupt;
    begin
        @(negedge clk);
        interrupt = 1'b1;
        @(negedge clk);
        interrupt = 1'b0;
    end
    endtask

    task pulse_exception;
    begin
        @(negedge clk);
        exception = 1'b1;
        @(negedge clk);
        exception = 1'b0;
    end
    endtask

    task pulse_valid_normal;
        input [7:0] opc;
        input       ext;
        input [1:0] rm;
        input       has_rm;
    begin
        @(negedge clk);
        to_rr_valid = 1'b1;
        opcode      = opc;
        ext_opcode  = ext;
        modrm       = rm;
        has_modrm   = has_rm;
        rep         = 1'b0;
        movs        = 1'b0;
        cmps        = 1'b0;
        iret        = 1'b0;
        reg_ecx     = 32'd0;

        @(negedge clk);
        to_rr_valid = 1'b0;
    end
    endtask

    task pulse_rep_movs;
        input [7:0] opc;
        input [31:0] ecx_init;
    begin
        @(negedge clk);
        to_rr_valid = 1'b1;
        rep         = 1'b1;
        movs        = 1'b1;
        cmps        = 1'b0;
        iret        = 1'b0;
        opcode      = opc;
        reg_ecx     = ecx_init;

        @(negedge clk);
        to_rr_valid = 1'b0;
        rep         = 1'b0;
        movs        = 1'b0;
    end
    endtask

    task pulse_rep_cmps;
        input [7:0] opc;
        input [31:0] ecx_init;
    begin
        @(negedge clk);
        to_rr_valid = 1'b1;
        rep         = 1'b1;
        movs        = 1'b0;
        cmps        = 1'b1;
        iret        = 1'b0;
        opcode      = opc;
        reg_ecx     = ecx_init;

        @(negedge clk);
        to_rr_valid = 1'b0;
        rep         = 1'b0;
        cmps        = 1'b0;
    end
    endtask

    task pulse_iret;
    begin
        @(negedge clk);
        to_rr_valid = 1'b1;
        iret        = 1'b1;

        @(negedge clk);
        to_rr_valid = 1'b0;
        iret        = 1'b0;
    end
    endtask

    // ----------------------------
    // directed tests
    // ----------------------------
    initial begin
        FAILURES = 0;
        SUCCESSES = 0;

        reset_dut();

        // --------------------------------
        // 1. IDLE stays IDLE on normal non-special instruction
        // --------------------------------
        pulse_valid_normal(8'h90, 1'b0, 2'b11, 1'b0);
        step_and_check("idle normal instr");
        step_and_check("idle normal instr settle");

        // --------------------------------
        // 2. IDLE -> INTEX_INIT0 on interrupt
        // --------------------------------
        reset_dut();
        pulse_interrupt();
        step_and_check("idle to intex_init0 by interrupt");
        step_and_check("intex_init0 to intex_init1");
        step_and_check("intex_init1 to idle");

        // --------------------------------
        // 3. IDLE -> INTEX_INIT0 on exception
        // --------------------------------
        reset_dut();
        pulse_exception();
        step_and_check("idle to intex_init0 by exception");
        step_and_check("intex_init0 to intex_init1 by exception path");
        step_and_check("intex_init1 to idle by exception path");

        // --------------------------------
        // 4. IDLE -> IRET0 -> IRET1 -> IDLE
        // --------------------------------
        reset_dut();
        pulse_iret();
        step_and_check("idle to iret0");
        step_and_check("iret0 to iret1");
        step_and_check("iret1 to idle");

        // --------------------------------
        // 5. IDLE -> REP_MOVS0 with ecx != 0
        // --------------------------------
        reset_dut();
        pulse_rep_movs(8'hA5, 32'd3);
        step_and_check("idle to rep_movs0");
        step_and_check("rep_movs0 to rep_movs1");
        step_and_check("rep_movs1 loops or exits");

        // --------------------------------
        // 6. REP_MOVS should not start if ecx == 0
        // --------------------------------
        reset_dut();
        pulse_rep_movs(8'hA5, 32'd0);
        step_and_check("rep_movs ecx=0 stays idle");
        step_and_check("rep_movs ecx=0 settle");

        // --------------------------------
        // 7. REP_CMPS path with ecx != 0
        // --------------------------------
        reset_dut();
        pulse_rep_cmps(8'hA7, 32'd3);
        step_and_check("idle to rep_cmps0");
        step_and_check("rep_cmps0 to rep_cmps1");
        step_and_check("rep_cmps1 to rep_cmps2");
        step_and_check("rep_cmps2 loops or exits");

        // --------------------------------
        // 8. REP_CMPS exits early on cmps_found in CMPS0
        // --------------------------------
        reset_dut();
        pulse_rep_cmps(8'hA7, 32'd5);
        step_and_check("rep_cmps0 entered");

        @(negedge clk);
        cmps_found = 1'b1;
        step_and_check("rep_cmps0 with cmps_found exits");
        @(negedge clk);
        cmps_found = 1'b0;
        step_and_check("back to idle after cmps_found");

        // --------------------------------
        // 9. REP_CMPS exits early on cmps_found in CMPS1
        // --------------------------------
        reset_dut();
        pulse_rep_cmps(8'hA7, 32'd5);
        step_and_check("rep_cmps0 entered again");
        step_and_check("rep_cmps1 entered");

        @(negedge clk);
        cmps_found = 1'b1;
        step_and_check("rep_cmps1 with cmps_found exits");
        @(negedge clk);
        cmps_found = 1'b0;
        step_and_check("back to idle from cmps1");

        // --------------------------------
        // 10. REP_CMPS exits on cmps_found in CMPS2
        // --------------------------------
        reset_dut();
        pulse_rep_cmps(8'hA7, 32'd5);
        step_and_check("rep_cmps0 entered third time");
        step_and_check("rep_cmps1 entered third time");
        step_and_check("rep_cmps2 entered");

        @(negedge clk);
        cmps_found = 1'b1;
        step_and_check("rep_cmps2 with cmps_found exits");
        @(negedge clk);
        cmps_found = 1'b0;
        step_and_check("back to idle from cmps2");

        // --------------------------------
        // 11. exception during REP_MOVS0
        // --------------------------------
        reset_dut();
        pulse_rep_movs(8'hA5, 32'd4);
        step_and_check("rep_movs0 entered for exception test");

        @(negedge clk);
        exception = 1'b1;
        step_and_check("rep_movs0 exception -> intex_init0");
        @(negedge clk);
        exception = 1'b0;
        step_and_check("intex_init0 -> intex_init1");
        step_and_check("intex_init1 -> idle");

        // --------------------------------
        // 12. interrupt during REP_MOVS1
        // --------------------------------
        reset_dut();
        pulse_rep_movs(8'hA5, 32'd4);
        step_and_check("rep_movs0 entered for interrupt test");
        step_and_check("rep_movs1 entered for interrupt test");

        @(negedge clk);
        interrupt = 1'b1;
        step_and_check("rep_movs1 interrupt -> intex_init0");
        @(negedge clk);
        interrupt = 1'b0;
        step_and_check("intex_init0 -> intex_init1 after movs interrupt");
        step_and_check("intex_init1 -> idle after movs interrupt");

        // --------------------------------
        // 13. exception during REP_CMPS0
        // --------------------------------
        reset_dut();
        pulse_rep_cmps(8'hA7, 32'd4);
        step_and_check("rep_cmps0 entered for exception test");

        @(negedge clk);
        exception = 1'b1;
        step_and_check("rep_cmps0 exception -> intex_init0");
        @(negedge clk);
        exception = 1'b0;
        step_and_check("intex init1 back to idle after cmps0 exception");
        step_and_check("idle settle after cmps0 exception");

        // --------------------------------
        // 14. exception during REP_CMPS1
        // --------------------------------
        reset_dut();
        pulse_rep_cmps(8'hA7, 32'd4);
        step_and_check("rep_cmps0 entered for cmps1 exception test");
        step_and_check("rep_cmps1 entered for cmps1 exception test");

        @(negedge clk);
        exception = 1'b1;
        step_and_check("rep_cmps1 exception -> intex_init0");
        @(negedge clk);
        exception = 1'b0;
        step_and_check("intex path after cmps1 exception");
        step_and_check("idle after cmps1 exception");

        // --------------------------------
        // 15. interrupt during REP_CMPS2
        // --------------------------------
        reset_dut();
        pulse_rep_cmps(8'hA7, 32'd4);
        step_and_check("rep_cmps0 for cmps2 interrupt");
        step_and_check("rep_cmps1 for cmps2 interrupt");
        step_and_check("rep_cmps2 for cmps2 interrupt");

        @(negedge clk);
        interrupt = 1'b1;
        step_and_check("rep_cmps2 interrupt -> intex_init0");
        @(negedge clk);
        interrupt = 1'b0;
        step_and_check("intex path after cmps2 interrupt");
        step_and_check("idle after cmps2 interrupt");

        // --------------------------------
        // 16. stall holds state when exception=0
        // --------------------------------
        reset_dut();
        pulse_rep_movs(8'hA5, 32'd3);
        step_and_check("enter rep_movs0 before stall hold");

        @(negedge clk);
        stall = 1'b1;
        step_and_check("stall holds rep_movs0");
        step_and_check("stall still holds rep_movs0");

        @(posedge clk);
        #2
        stall = 1'b0;
        step_and_check("release stall allows rep_movs0 -> rep_movs1");

        // --------------------------------
        // 17. exception overrides stall in state update
        // --------------------------------
        reset_dut();
        pulse_rep_movs(8'hA5, 32'd3);
        step_and_check("enter rep_movs0 before stall+exception");

        @(negedge clk);
        stall     = 1'b1;
        exception = 1'b1;
        step_and_check("stall=1 exception=1 still updates to intex_init0");

        @(negedge clk);
        stall     = 1'b0;
        exception = 1'b0;
        step_and_check("continue intex path after stall+exception");
        step_and_check("back to idle after stall+exception");

        // --------------------------------
        // 18. random smoke test
        // --------------------------------
        // repeat (100) begin
        //     @(negedge clk);
        //     to_rr_valid = $random;
        //     rep         = $random;
        //     stall       = $random;
        //     interrupt   = $random;
        //     exception   = $random;
        //     movs        = $random;
        //     cmps        = $random;
        //     iret        = $random;
        //     cmps_found  = $random;
        //     opcode      = $random;
        //     ext_opcode  = $random;
        //     modrm       = $random;
        //     has_modrm   = $random;
        //     reg_ecx     = $random;
        //     step_and_check("random smoke");
        // end

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule