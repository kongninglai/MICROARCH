`timescale 1ns/1ps

module ex_shf_tb;

initial begin
  // $vcdplusfile("ex_shf_tb.dump.vpd");
  // $vcdpluson(0, ex_shf_tb); 
end

    reg         shf_op;
    reg  [1:0]  ds;
    reg  [31:0] shf_data;
    reg  [7:0]  shf_amt;

    wire [31:0] shf_out;
    wire [31:0] shf_eflags;
    wire [31:0] shf_eflags_mask;

    ex_shf dut (
        .shf_op(shf_op),
        .ds(ds),
        .shf_data(shf_data),
        .shf_amt(shf_amt),
        .shf_out(shf_out),
        .shf_eflags(shf_eflags),
        .shf_eflags_mask(shf_eflags_mask)
    );

    localparam OP_SAL = 1'b0;
    localparam OP_SAR = 1'b1;

    integer FAILURES  = 0;
    integer SUCCESSES = 0;
    integer i;

    function integer get_width;
        input [1:0] ds_i;
        begin
            case (ds_i)
                2'b00: get_width = 8;
                2'b01: get_width = 16;
                2'b10: get_width = 32;
                default: get_width = 32;
            endcase
        end
    endfunction

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

    function exp_pf;
        input [7:0] x;
        begin
            exp_pf = ~^x;
        end
    endfunction

    function [31:0] ref_out;
        input       op_i;
        input [1:0] ds_i;
        input [31:0] data_i;
        input [7:0] amt_i;
        reg [4:0] cnt;
        reg [31:0] mask;
        reg signed [31:0] sar_in;
        begin
            cnt  = amt_i[4:0];
            mask = width_mask(ds_i);

            if (ds_i == 2'b11) begin
                ref_out = 32'b0;
            end else if (op_i == OP_SAL) begin
                case (ds_i)
                    2'b00: ref_out = (((data_i & 32'h000000FF) << cnt) & 32'h000000FF);
                    2'b01: ref_out = (((data_i & 32'h0000FFFF) << cnt) & 32'h0000FFFF);
                    default: ref_out = (data_i << cnt);
                endcase
            end else begin
                case (ds_i)
                    2'b00: begin
                        sar_in  = $signed({{24{data_i[7]}}, data_i[7:0]});
                        ref_out = sar_in >>> cnt;
                        ref_out = ref_out & 32'h000000FF;
                    end
                    2'b01: begin
                        sar_in  = $signed({{16{data_i[15]}}, data_i[15:0]});
                        ref_out = sar_in >>> cnt;
                        ref_out = ref_out & 32'h0000FFFF;
                    end
                    default: begin
                        sar_in  = $signed(data_i);
                        ref_out = sar_in >>> cnt;
                    end
                endcase
            end
        end
    endfunction

    function [31:0] ref_flags;
        input       op_i;
        input [1:0] ds_i;
        input [31:0] data_i;
        input [7:0] amt_i;
        input [31:0] out_i;
        integer width;
        reg [4:0] cnt;
        reg cf, pf, zf, sf, of;
        begin
            ref_flags = 32'b0;
            width = get_width(ds_i);
            cnt   = amt_i[4:0];

            cf = 1'b0;
            pf = 1'b0;
            zf = 1'b0;
            sf = 1'b0;
            of = 1'b0;

            if ((ds_i == 2'b11) || (cnt == 0)) begin
                ref_flags = 32'b0;
            end else begin
                // SF/ZF/PF
                case (ds_i)
                    2'b00: begin
                        sf = out_i[7];
                        zf = (out_i[7:0] == 8'h00);
                    end
                    2'b01: begin
                        sf = out_i[15];
                        zf = (out_i[15:0] == 16'h0000);
                    end
                    default: begin
                        sf = out_i[31];
                        zf = (out_i == 32'h00000000);
                    end
                endcase
                pf = exp_pf(out_i[7:0]);

                // CF
                if (op_i == OP_SAL) begin
                    if (cnt < width) begin
                        cf = data_i[width - cnt];
                    end
                end else begin
                    if (cnt < width) begin
                        cf = data_i[cnt - 1];
                    end else begin
                        cf = data_i[width - 1];
                    end
                end

                // OF
                if (cnt == 1) begin
                    if (op_i == OP_SAL) begin
                        case (ds_i)
                            2'b00: of = out_i[7]  ^ cf;
                            2'b01: of = out_i[15] ^ cf;
                            default: of = out_i[31] ^ cf;
                        endcase
                    end else begin
                        of = 1'b0;
                    end
                end

                ref_flags[0]  = cf;
                ref_flags[2]  = pf;
                ref_flags[6]  = zf;
                ref_flags[7]  = sf;
                ref_flags[11] = of;
            end
        end
    endfunction

    function [31:0] ref_mask;
        input       op_i;
        input [1:0] ds_i;
        input [7:0] amt_i;
        integer width;
        reg [4:0] cnt;
        begin
            ref_mask = 32'b0;
            width = get_width(ds_i);
            cnt   = amt_i[4:0];

            if ((ds_i == 2'b11) || (cnt == 0)) begin
                ref_mask = 32'b0;
            end else begin
                // SF/ZF/PF valid
                ref_mask[7] = 1'b1;
                ref_mask[6] = 1'b1;
                ref_mask[2] = 1'b1;
                // CF
                if (op_i == OP_SAR) begin
                    ref_mask[0] = 1'b1;
                end else begin
                    if (cnt < width)
                        ref_mask[0] = 1'b1;
                end

                // OF
                if (cnt == 1)
                    ref_mask[11] = 1'b1;
            end
        end
    endfunction

    task run_test;
        input [255:0] name;
        input         t_op;
        input [1:0]   t_ds;
        input [31:0]  t_data;
        input [7:0]   t_amt;
        reg   [31:0]  exp_out_v;
        reg   [31:0]  exp_flags_v;
        reg   [31:0]  exp_mask_v;
        begin
            shf_op   = t_op;
            ds       = t_ds;
            shf_data = t_data;
            shf_amt  = t_amt;

            #5;

            exp_out_v   = ref_out(t_op, t_ds, t_data, t_amt);
            exp_flags_v = ref_flags(t_op, t_ds, t_data, t_amt, exp_out_v);
            exp_mask_v  = ref_mask(t_op, t_ds, t_amt);

            if (((shf_out & width_mask(t_ds)) === (exp_out_v & width_mask(t_ds))) &&
                ((shf_eflags & exp_mask_v) === (exp_flags_v & exp_mask_v))) begin
                SUCCESSES = SUCCESSES + 1;
            end else begin
                FAILURES = FAILURES + 1;
                $display("--------------------------------------------------");
                $display("FAIL: %0s", name);
                $display("op=%0d ds=%b data=0x%08h amt=%0d", t_op, t_ds, t_data, t_amt);
                $display("out  = 0x%08h, expected = 0x%08h, masked_out = 0x%08h, masked_exp = 0x%08h",
                        shf_out, exp_out_v, (shf_out & width_mask(t_ds)), (exp_out_v & width_mask(t_ds)));
                $display("flag = 0x%08h, expected = 0x%08h", shf_eflags, exp_flags_v);
                $display("mask = 0x%08h, expected = 0x%08h", shf_eflags_mask, exp_mask_v);
            end
        end
    endtask

    task run_random_tests;
        input integer n;
        reg rand_op;
        reg [1:0] rand_ds;
        reg [31:0] rand_data;
        reg [7:0] rand_amt;
        begin
            for (i = 0; i < n; i = i + 1) begin
                rand_op   = $random;
                case ($random % 3)
                    0: rand_ds = 2'b00;
                    1: rand_ds = 2'b01;
                    default: rand_ds = 2'b10;
                endcase
                rand_data = $random;
                rand_amt  = $random;
                run_test("random", rand_op, rand_ds, rand_data, rand_amt);
            end
        end
    endtask

    initial begin

        // Directed tests
        run_test("SAL8 basic",        OP_SAL, 2'b00, 32'h00000012, 8'd1);
        run_test("SAL8 count0",       OP_SAL, 2'b00, 32'h00000012, 8'd0);
        run_test("SAL8 count7",       OP_SAL, 2'b00, 32'h00000081, 8'd7);
        run_test("SAL8 count8",       OP_SAL, 2'b00, 32'h00000081, 8'd8);
        run_test("SAL16 count1",      OP_SAL, 2'b01, 32'h00008001, 8'd1);
        run_test("SAL32 count1",      OP_SAL, 2'b10, 32'h80000001, 8'd1);

        run_test("SAR8 basic",        OP_SAR, 2'b00, 32'h00000080, 8'd1);
        run_test("SAR8 count0",       OP_SAR, 2'b00, 32'h00000080, 8'd0);
        run_test("SAR8 count7",       OP_SAR, 2'b00, 32'h00000081, 8'd7);
        run_test("SAR8 count8",       OP_SAR, 2'b00, 32'h00000081, 8'd8);
        run_test("SAR16 count1",      OP_SAR, 2'b01, 32'h00008001, 8'd1);
        run_test("SAR32 count31",     OP_SAR, 2'b10, 32'h80000001, 8'd31);

        // Random
        run_random_tests(500);

        $display("==============================================");

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        
        if (FAILURES == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        
        $finish;
    end

endmodule