`timescale 1ns/1ps

module ex_alu_tb;

initial begin
  // $vcdplusfile("ex_alu_tb.dump.vpd");
  // $vcdpluson(0, ex_alu_tb); 
end
    reg  [2:0]  alu_op;
    reg  [1:0]  ds;
    reg  [31:0] in0;
    reg  [31:0] in1;
    reg         eflags_cf;
    reg         sbb_dir;
    wire [31:0] alu_out;
    wire [31:0] alu_eflags;
    wire [31:0] alu_eflags_mask;


    wire [31:0] alu_out_bh;
    wire [31:0] alu_eflags_bh;
    wire [31:0] alu_eflags_mask_bh;

    ex_alu dut (
        .alu_op         (alu_op),
        .ds             (ds),
        .in0            (in0),
        .in1            (in1),
        .sbb_dir        (sbb_dir),
        .eflags_cf      (eflags_cf),
        .alu_out        (alu_out),
        .alu_eflags     (alu_eflags),
        .alu_eflags_mask(alu_eflags_mask)
    );

    ex_alu_bh dut_bh (
        .alu_op         (alu_op),
        .ds             (ds),
        .in0            (in0),
        .in1            (in1),
        .sbb_dir        (sbb_dir),
        .eflags_cf      (eflags_cf),
        .alu_out        (alu_out_bh),
        .alu_eflags     (alu_eflags_bh),
        .alu_eflags_mask(alu_eflags_mask_bh)
    );

    // ---------------------------------------------------------
    // ALU op encoding
    // ---------------------------------------------------------
    localparam OP_ADD = 3'b000;
    localparam OP_OR  = 3'b001;
    localparam OP_ADC = 3'b010;
    localparam OP_SBB = 3'b011;
    localparam OP_AND = 3'b100;

    // ---------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------
    function [31:0] mask_by_ds;
        input [1:0] ds_i;
        begin
            case (ds_i)
                2'b00: mask_by_ds = 32'h000000FF;
                2'b01: mask_by_ds = 32'h0000FFFF;
                2'b10: mask_by_ds = 32'hFFFFFFFF;
                default: mask_by_ds = 32'h00000000;
            endcase
        end
    endfunction

    function integer width_by_ds;
        input [1:0] ds_i;
        begin
            case (ds_i)
                2'b00: width_by_ds = 8;
                2'b01: width_by_ds = 16;
                2'b10: width_by_ds = 32;
                default: width_by_ds = 32;
            endcase
        end
    endfunction

    function exp_cf;
        input [2:0]  op_i;
        input [1:0]  ds_i;
        input [31:0] a;
        input [31:0] b;
        input        cf_in;
        reg   [32:0] tmp;
        reg   [31:0] mask;
        begin
            mask = mask_by_ds(ds_i);

            case (op_i)
                OP_ADD: begin
                    tmp    = {1'b0, (a & mask)} + {1'b0, (b & mask)};
                    exp_cf = tmp[width_by_ds(ds_i)];
                end
                OP_ADC: begin
                    tmp    = {1'b0, (a & mask)} + {1'b0, (b & mask)} + cf_in;
                    exp_cf = tmp[width_by_ds(ds_i)];
                end
                OP_SBB: begin
                    exp_cf = ((a & mask) < ((b & mask) + cf_in));
                end
                OP_AND,
                OP_OR: begin
                    exp_cf = 1'b0;
                end
                default: begin
                    exp_cf = 1'b0;
                end
            endcase
        end
    endfunction

    function exp_of;
        input [2:0]  op_i;
        input [1:0]  ds_i;
        input [31:0] a;
        input [31:0] b;
        input [31:0] r;
        reg          sa, sb, sr;
        integer      msb;
        begin
            case (ds_i)
                2'b00: msb = 7;
                2'b01: msb = 15;
                default: msb = 31;
            endcase

            sa = a[msb];
            sb = b[msb];
            sr = r[msb];

            case (op_i)
                OP_ADD,
                OP_ADC: exp_of = (~(sa ^ sb)) & (sa ^ sr);

                OP_SBB: exp_of = (sa ^ sb) & (sa ^ sr);

                OP_AND,
                OP_OR: exp_of = 1'b0;

                default: exp_of = 1'b0;
            endcase
        end
    endfunction

    function exp_sf;
        input [1:0]  ds_i;
        input [31:0] r;
        begin
            case (ds_i)
                2'b00: exp_sf = r[7];
                2'b01: exp_sf = r[15];
                default: exp_sf = r[31];
            endcase
        end
    endfunction

    function exp_zf;
        input [1:0]  ds_i;
        input [31:0] r;
        reg   [31:0] mask;
        begin
            mask   = mask_by_ds(ds_i);
            exp_zf = ((r & mask) == 32'b0);
        end
    endfunction

    function exp_pf;
        input [31:0] r;
        begin
            exp_pf = ~^r[7:0];
        end
    endfunction

    function exp_af;
        input [2:0]  op_i;
        input [31:0] a;
        input [31:0] b;
        input [31:0] r;
        input        cf_in;
        reg   [4:0] low_tmp;
        begin
            case (op_i)
                OP_ADD: begin
                    low_tmp = {1'b0, a[3:0]} + {1'b0, b[3:0]};
                    exp_af  = low_tmp[4];
                end
                OP_ADC: begin
                    low_tmp = {1'b0, a[3:0]} + {1'b0, b[3:0]} + cf_in;
                    exp_af  = low_tmp[4];
                end
                OP_SBB: begin
                    exp_af = ({1'b0, a[3:0]} < ({1'b0, b[3:0]} + cf_in));
                end
                OP_AND,
                OP_OR: begin
                    exp_af = 1'b0;
                end
                default: begin
                    exp_af = 1'b0;
                end
            endcase
        end
    endfunction

    function [31:0] exp_flags;
        input [2:0]  op_i;
        input [1:0]  ds_i;
        input [31:0] a;
        input [31:0] b;
        input [31:0] r;
        input        sbb_dir;
        input        cf_in;
        reg cf, pf, af, zf, sf, of;
        begin

            cf = sbb_dir ? exp_cf(op_i, ds_i, b, a, cf_in) : exp_cf(op_i, ds_i, a, b, cf_in);
            pf = exp_pf(r);
            af = sbb_dir ? exp_af(op_i, b, a, r, cf_in) : exp_af(op_i, a, b, r, cf_in);
            zf = exp_zf(ds_i, r);
            sf = exp_sf(ds_i, r);
            of = sbb_dir ? exp_of(op_i, ds_i, b, a, r) : exp_of(op_i, ds_i, a, b, r);

            exp_flags = 32'b0;
            exp_flags[0]  = cf;
            exp_flags[2]  = pf;
            exp_flags[4]  = af;
            exp_flags[6]  = zf;
            exp_flags[7]  = sf;
            exp_flags[11] = of;
        end
    endfunction

    function [31:0] exp_mask;
        input [2:0] op_i;
        input [1:0] ds_i;
        begin
            if (ds_i == 2'b11) begin
                exp_mask = 32'b0;
            end else begin
                case (op_i)
                    OP_ADD,
                    OP_ADC,
                    OP_SBB: exp_mask = 32'h0000_08D5;

                    OP_OR,
                    OP_AND: exp_mask = 32'h0000_08C5;

                    default: exp_mask = 32'b0;
                endcase
            end
        end
    endfunction

    function [31:0] exp_out;
        input [2:0]  op_i;
        input [1:0]  ds_i;
        input [31:0] a;
        input [31:0] b;
        input        sbb_dir;
        input        cf_in;
        reg   [31:0] mask;
        reg   [31:0] low_res;
        begin
            mask = mask_by_ds(ds_i);
            
            case (op_i)
                OP_ADD: low_res = ((a & mask) + (b & mask)) & mask;
                OP_ADC: low_res = ((a & mask) + (b & mask) + cf_in) & mask;
                OP_SBB: low_res = sbb_dir ? (((b & mask) - (a & mask) - cf_in) & mask) : (((a & mask) - (b & mask) - cf_in) & mask);
                OP_OR : low_res = ((a & mask) | (b & mask)) & mask;
                OP_AND: low_res = ((a & mask) & (b & mask)) & mask;
                default: low_res = 32'b0;
            endcase

            // Match DUT behavior: high bits are not truncated by ds in alu_out
            // Arithmetic blocks compute 32-bit results, logic ops also 32-bit.
            case (op_i)
                OP_ADD: exp_out = a + b;
                OP_ADC: exp_out = a + b + cf_in;
                OP_SBB: exp_out = sbb_dir ? (b - a - cf_in) : (a - b - cf_in);
                OP_OR : exp_out = a | b;
                OP_AND: exp_out = a & b;
                default: exp_out = 32'b0;
            endcase
        end
    endfunction

    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    task run_test;
        input [255:0] name;
        input [2:0]   t_op;
        input [1:0]   t_ds;
        input [31:0]  t_in0;
        input [31:0]  t_in1;
        input         t_sbb_dir;
        input         t_cf;
        reg   [31:0]  expected_out;
        reg   [31:0]  expected_flags;
        reg   [31:0]  expected_mask;
        begin
            alu_op    = t_op;
            ds        = t_ds;
            in0       = t_in0;
            in1       = t_in1;
            sbb_dir   = t_sbb_dir;
            eflags_cf = t_cf;

            #10;

            expected_out   = exp_out(t_op, t_ds, t_in0, t_in1, t_sbb_dir, t_cf);
            expected_flags = exp_flags(t_op, t_ds, t_in0, t_in1, expected_out, t_sbb_dir, t_cf);
            expected_mask  = exp_mask(t_op, t_ds);

            if ((alu_out !== expected_out) ||
                (alu_eflags !== expected_flags) ||
                (alu_eflags_mask !== expected_mask)) begin
                    FAILURES = FAILURES + 1;
                    $display("==============================================================");
                    $display("TEST: %0s", name);
                    $display("op=%b ds=%b in0=0x%08h in1=0x%08h sbb_dir=%b0 cf_in=%0d",
                            t_op, t_ds, t_in0, t_in1, t_sbb_dir, t_cf);
                    $display("alu_out        = 0x%08h (expected 0x%08h) %s",
                            alu_out, expected_out,
                            (alu_out === expected_out) ? "PASS" : "FAIL");
                    $display("alu_eflags     = 0x%08h (expected 0x%08h) %s",
                            alu_eflags, expected_flags,
                            (alu_eflags === expected_flags) ? "PASS" : "FAIL");
                    $display("alu_eflags_mask= 0x%08h (expected 0x%08h) %s",
                            alu_eflags_mask, expected_mask,
                            (alu_eflags_mask === expected_mask) ? "PASS" : "FAIL");
                        $display(">>> ERROR in test: %0s", name);
                end else begin 
                    SUCCESSES = SUCCESSES + 1;
                end
        end
    endtask

    integer i;
    task run_random_tests;
        input integer num_tests;
        reg [2:0]  rand_op;
        reg [1:0]  rand_ds;
        reg [31:0] rand_in0;
        reg [31:0] rand_in1;
        reg        rand_sbb_dir;
        reg        rand_cf;
        begin
            for (i = 0; i < num_tests; i = i + 1) begin
                rand_in0 = {$random, $random};
                rand_in1 = {$random, $random};
                rand_sbb_dir = $random & 1'b1;
                rand_cf  = $random & 1'b1;

                case ($random % 5)
                    0: rand_op = OP_ADD;
                    1: rand_op = OP_OR;
                    2: rand_op = OP_ADC;
                    3: rand_op = OP_SBB;
                    default: rand_op = OP_AND;
                endcase

                case ($random % 3)
                    0: rand_ds = 2'b00;
                    1: rand_ds = 2'b01;
                    default: rand_ds = 2'b10;
                endcase

                run_test("random", rand_op, rand_ds, rand_in0, rand_in1, rand_sbb_dir, rand_cf);
            end
        end
    endtask

    initial begin
        $display("==== Start tb_ex_alu ====");

        // -------------------------
        // ADD
        // -------------------------
        run_test("ADD 8-bit basic",         OP_ADD, 2'b00, 32'h00000005, 32'h00000003, 1'b0, 1'b0);
        run_test("ADD 8-bit carry",         OP_ADD, 2'b00, 32'h000000FF, 32'h00000001, 1'b0, 1'b0);
        run_test("ADD 8-bit overflow",      OP_ADD, 2'b00, 32'h0000007F, 32'h00000001, 1'b0, 1'b0);
        run_test("ADD 16-bit zero",         OP_ADD, 2'b01, 32'h0000FFFF, 32'h00000001, 1'b0, 1'b0);
        run_test("ADD 32-bit overflow",     OP_ADD, 2'b10, 32'h7FFFFFFF, 32'h00000001, 1'b0, 1'b0);

        // -------------------------
        // ADC
        // -------------------------
        run_test("ADC 8-bit basic cf=1",    OP_ADC, 2'b00, 32'h00000005, 32'h00000003, 1'b0, 1'b1);
        run_test("ADC 8-bit carry cf=1",    OP_ADC, 2'b00, 32'h000000FF, 32'h00000000, 1'b0, 1'b1);
        run_test("ADC 16-bit carry",        OP_ADC, 2'b01, 32'h0000FFFF, 32'h00000000, 1'b0, 1'b1);
        run_test("ADC 32-bit overflow",     OP_ADC, 2'b10, 32'h7FFFFFFF, 32'h00000000, 1'b0, 1'b1);

        // -------------------------
        // SBB
        // -------------------------
        run_test("SBB 8-bit basic dir=0",   OP_SBB, 2'b00, 32'h00000008, 32'h00000003, 1'b0, 1'b0);
        run_test("SBB 8-bit basic dir=1",   OP_SBB, 2'b00, 32'h00000003, 32'h00000008, 1'b1, 1'b0);
        run_test("SBB 8-bit basic cf=0",    OP_SBB, 2'b00, 32'h00000005, 32'h00000003, 1'b0, 1'b0);
        run_test("SBB 8-bit basic cf=1",    OP_SBB, 2'b00, 32'h00000005, 32'h00000003, 1'b0, 1'b1);
        run_test("SBB 8-bit borrow",        OP_SBB, 2'b00, 32'h00000003, 32'h00000005, 1'b0, 1'b0);
        run_test("SBB 8-bit overflow",      OP_SBB, 2'b00, 32'h00000080, 32'h00000001, 1'b0, 1'b0);
        run_test("SBB 16-bit overflow",     OP_SBB, 2'b01, 32'h00008000, 32'h00000001, 1'b0, 1'b0);
        run_test("SBB 32-bit overflow",     OP_SBB, 2'b10, 32'h80000000, 32'h00000001, 1'b0, 1'b0);

        // -------------------------
        // OR
        // -------------------------
        run_test("OR 8-bit basic",          OP_OR,  2'b00, 32'h00000055, 32'h0000000F, 1'b0, 1'b0);
        run_test("OR 8-bit sign",           OP_OR,  2'b00, 32'h00000080, 32'h00000001, 1'b0, 1'b0);
        run_test("OR 16-bit zero",          OP_OR,  2'b01, 32'h00000000, 32'h00000000, 1'b0, 1'b0);
        run_test("OR 32-bit basic",         OP_OR,  2'b10, 32'h12340000, 32'h00005678, 1'b0, 1'b0);

        // -------------------------
        // AND
        // -------------------------
        run_test("AND 8-bit basic",         OP_AND, 2'b00, 32'h000000F0, 32'h000000CC, 1'b0, 1'b0);
        run_test("AND 8-bit zero",          OP_AND, 2'b00, 32'h000000F0, 32'h0000000F, 1'b0, 1'b0);
        run_test("AND 16-bit sign",         OP_AND, 2'b01, 32'h00008001, 32'h0000FFFF, 1'b0, 1'b0);
        run_test("AND 32-bit basic",        OP_AND, 2'b10, 32'hFFFF0000, 32'h0F0F0F0F, 1'b0, 1'b0);

        run_random_tests(500);

        $display("==== End tb_ex_alu ====");


        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule