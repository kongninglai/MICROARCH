`timescale 1ns/1ps

module ex_cmp_tb;

initial begin
  $vcdplusfile("ex_cmp_tb.dump.vpd");
  $vcdpluson(0, ex_cmp_tb); 
end

    reg  [1:0]  ds;
    reg  [31:0] in0;
    reg  [31:0]  in1;

    wire [31:0] cmp_eflags;
    wire [31:0] cmp_eflags_mask;

    ex_cmp dut (
        .ds(ds),
        .in0(in0),
        .in1(in1),
        .cmp_eflags(cmp_eflags),
        .cmp_eflags_mask(cmp_eflags_mask)
    );

    integer FAILURES  = 0;
    integer SUCCESSES = 0;
    integer i;

    function [31:0] width_mask;
        input [1:0] ds_i;
        begin
            case (ds_i)
                2'b00: width_mask = 32'h000000FF;
                2'b01: width_mask = 32'h0000FFFF;
                2'b10: width_mask = 32'hFFFFFFFF;
                default: width_mask = 32'h00000000;
            endcase
        end
    endfunction

    function integer msb_idx;
        input [1:0] ds_i;
        begin
            case (ds_i)
                2'b00: msb_idx = 7;
                2'b01: msb_idx = 15;
                2'b10: msb_idx = 31;
                default: msb_idx = 31;
            endcase
        end
    endfunction

    function exp_cf;
        input [1:0]  ds_i;
        input [31:0] a;
        input [31:0]  b8;
        reg   [31:0] a_masked;
        reg   [31:0] b_masked;
        begin
            a_masked = a & width_mask(ds_i);
            b_masked = {24'b0, b8} & width_mask(ds_i);
            exp_cf   = (a_masked < b_masked);
        end
    endfunction

    function exp_of;
        input [1:0]  ds_i;
        input [31:0] a;
        input [31:0]  b8;
        input [31:0] r;
        integer m;
        reg sa, sb, sr;
        reg [31:0] b_ext;
        begin
            m  = msb_idx(ds_i);
            sa = a[m];

            b_ext = {24'b0, b8};
            sb = b_ext[m];

            sr = r[m];

            exp_of = (sa ^ sb) & (sa ^ sr);
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
        begin
            exp_zf = ((r & width_mask(ds_i)) == 32'b0);
        end
    endfunction

    function exp_pf;
        input [31:0] r;
        begin
            exp_pf = ~^r[7:0];
        end
    endfunction

    function exp_af;
        input [31:0] a;
        input [31:0]  b8;
        input [31:0] r;
        begin
            exp_af = a[4] ^ b8[4] ^ r[4];
        end
    endfunction

    function [31:0] exp_result;
        input [1:0]  ds_i;
        input [31:0] a;
        input [31:0]  b8;
        reg   [31:0] a_masked;
        reg   [31:0] b_masked;
        begin
            a_masked   = a & width_mask(ds_i);
            b_masked   = ({24'b0, b8}) & width_mask(ds_i);
            exp_result = (a_masked - b_masked) & width_mask(ds_i);
        end
    endfunction

    function [31:0] exp_flags;
        input [1:0]  ds_i;
        input [31:0] a;
        input [31:0]  b8;
        reg   [31:0] r;
        reg cf, pf, af, zf, sf, of;
        begin
            r  = exp_result(ds_i, a, b8);
            cf = exp_cf(ds_i, a, b8);
            pf = exp_pf(r);
            af = exp_af(a, b8, r);
            zf = exp_zf(ds_i, r);
            sf = exp_sf(ds_i, r);
            of = exp_of(ds_i, a, b8, r);

            exp_flags = 32'b0;
            exp_flags[0]  = cf;
            exp_flags[2]  = pf;
            exp_flags[4]  = af;
            exp_flags[6]  = zf;
            exp_flags[7]  = sf;
            exp_flags[11] = of;
        end
    endfunction

    task run_test;
        input [255:0] name;
        input [1:0]   t_ds;
        input [31:0]  t_in0;
        input [31:0]   t_in1;
        reg   [31:0]  expected_flags;
        begin
            ds  = t_ds;
            in0 = t_in0;
            in1 = t_in1;

            #10;

            expected_flags = exp_flags(t_ds, t_in0, t_in1);

            if ((cmp_eflags === expected_flags) &&
                (cmp_eflags_mask === 32'h0000_08D5)) begin
                SUCCESSES = SUCCESSES + 1;
            end else begin
                FAILURES = FAILURES + 1;
                $display("--------------------------------------------------");
                $display("FAIL: %0s", name);
                $display("ds=%b in0=0x%08h in1=0x%02h", t_ds, t_in0, t_in1);
                $display("cmp_eflags      = 0x%08h", cmp_eflags);
                $display("expected_flags  = 0x%08h", expected_flags);
                $display("cmp_eflags_mask = 0x%08h", cmp_eflags_mask);
            end
        end
    endtask

    task run_random_tests;
        input integer n;
        reg [1:0]  rand_ds;
        reg [31:0] rand_in0;
        reg [31:0]  rand_in1;
        begin
            for (i = 0; i < n; i = i + 1) begin
                case ($random % 3)
                    0: rand_ds = 2'b00;
                    1: rand_ds = 2'b01;
                    default: rand_ds = 2'b10;
                endcase
                rand_in0 = $random;
                rand_in1 = $random;
                run_test("random", rand_ds, rand_in0, rand_in1);
            end
        end
    endtask

    initial begin

        // Directed tests
        run_test("CMP8 equal",          2'b00, 32'h00000012, 8'h12);
        run_test("CMP8 unsigned borrow",2'b00, 32'h00000003, 8'h05);
        run_test("CMP8 signed ovf",     2'b00, 32'h00000080, 8'h01); // 0x80 - 1 = 0x7F, OF=1
        run_test("CMP16 equal",         2'b01, 32'h00000034, 8'h34);
        run_test("CMP16 borrow",        2'b01, 32'h00000010, 8'h20);
        run_test("CMP32 equal",         2'b10, 32'h0000007F, 8'h7F);
        run_test("CMP32 borrow",        2'b10, 32'h00000001, 8'hFF);
        run_test("CMP32 mixed",         2'b10, 32'h80000000, 8'h01);

        // Random tests
        run_random_tests(500);

        $display("==============================================");

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);

        $finish;
    end

endmodule