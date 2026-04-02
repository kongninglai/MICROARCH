module check_dep_tb;
    initial begin
        $vcdplusfile("check_dep_tb.dump.vpd");
        $vcdpluson(0, check_dep_tb); 
    end

    reg [2:0] src_id;
    reg [2:0] dst_id;
    reg       ld_dst;
    reg       ld_src;
    wire      dep;
    reg       golden_dep;
    check_dep DUT(
        .src_id(src_id),
        .dst_id(dst_id),
        .ld_dst(ld_dst),
        .ld_src(ld_src),
        .dep(dep)
    );

    function golden_dep_output;
        input [2:0] src_id_in;
        input [2:0] dst_id_in;
        input       ld_dst_in;
        input       ld_src_in;

        golden_dep_output = (src_id_in == dst_id_in) & ld_dst_in & ld_src_in;
    endfunction
    
    integer FAILURES  = 0;
    integer SUCCESSES = 0;

    task check;
        input out, out_exp;
        if (out !== out_exp) begin
            FAILURES = FAILURES + 1;
            $display("FAILURE AT TIME %t. out_exp = %h, out = %h\n", 
                    $time, out_exp, out);
        end else begin
            SUCCESSES = SUCCESSES + 1;
            // $display("SUCCESS AT TIME %t. out_exp = %h, out = %h\n", 
            //           $time, out_exp, out);
        end
    endtask

    initial begin 
        src_id=3'b0;
        dst_id=3'b0;
        ld_dst=1'b0;
        ld_src=1'b0;

        repeat (1 << 8) begin
            #5;
            golden_dep = golden_dep_output(src_id, dst_id, ld_dst, ld_src);
            check(dep, golden_dep);
            src_id  = $random;
            dst_id  = $random;
            ld_dst  = $random;
            ld_src  = $random;
        end

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end
endmodule