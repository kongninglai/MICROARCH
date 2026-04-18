module tb_block_decoder_more();

    // --------------------------------------------------------------------
    // PARAMETERS
    // --------------------------------------------------------------------
    localparam NUM_TESTS = 10217;

    // --------------------------------------------------------------------
    // INPUTS
    // --------------------------------------------------------------------
    reg [127:0] cache_line;

    // --------------------------------------------------------------------
    // OUTPUTS
    // --------------------------------------------------------------------
    wire        prefix_rep;
    wire        prefix_op_size;
    wire [2:0]  prefix_seg_ov_id;
    wire        prefix_ext;
    wire [7:0]  opcode;
    wire        modrm_v;
    wire [7:0]  modrm;
    wire [7:0]  sib;
    wire [1:0]  disp_size_mux;
    wire [31:0] disp;
    wire [2:0]  imm_size;
    wire [47:0] imm;
    wire [1:0]  addressing_mode;
    wire [3:0]  incr_amt;

    // --------------------------------------------------------------------
    // MEMORY FOR TEST VECTORS
    // --------------------------------------------------------------------
    reg [127:0] mem_in [0:NUM_TESTS-1];       // instructions
    reg [115:0] mem_exp [0:NUM_TESTS-1];      // expected outputs

    integer i;
    integer SUCCESSES = 0;
    integer FAILURES = 0;

    // --------------------------------------------------------------------
    // INSTANTIATE DUT
    // --------------------------------------------------------------------
    block_decoder uut (
        .cache_line(cache_line),
        .prefix_rep(prefix_rep),
        .prefix_op_size(prefix_op_size),
        .prefix_seg_ov_id(prefix_seg_ov_id),
        .prefix_seg(),
        .prefix_ext(prefix_ext),
        .opcode(opcode),
        .modrm_v(modrm_v),
        .modrm(modrm),
        .sib(sib),
        .disp_size_mux(disp_size_mux),
        .disp(disp),
        .imm_size(imm_size),
        .imm(imm),
        .addressing_mode(addressing_mode),
        .instr_length(incr_amt)
    );

    // --------------------------------------------------------------------
    // CONCATENATE OUTPUTS
    // --------------------------------------------------------------------
    wire [115:0] dut_concat;
    assign dut_concat = {2'b00, prefix_rep, prefix_op_size, prefix_seg_ov_id,
                         prefix_ext, opcode, modrm, sib,
                         disp, imm,
                         incr_amt};

    // --------------------------------------------------------------------
    // INITIAL BLOCK
    // --------------------------------------------------------------------
    initial begin
        // $vcdplusfile("block_decoder_more_tb.dump.vpd");
        // $vcdpluson(0, tb_block_decoder_more); 
        // $vcdpluson(0, tb_block_decoder_more.uut);
        // $vcdpluson(0, tb_block_decoder_more.mem_in);
        // $vcdpluson(0, tb_block_decoder_more.mem_exp);

        // Read input and expected output memories
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hvl/stages/decoder/block_decoder_more_tb/testcases.mem", mem_in);
        $readmemh("/home/ecelrc/students/aak3265/MICROARCH/project/hvl/stages/decoder/block_decoder_more_tb/decoder_mem.mem", mem_exp);

        // Iterate through all tests
        for (i = 0; i < NUM_TESTS; i = i + 1) begin
            cache_line = mem_in[i];
            #50; // allow DUT to settle

            if ((dut_concat != mem_exp[i] || ^dut_concat === 1'bX) && (opcode !== 8'h0F)) begin
                $display("❌ TEST %0d FAIL: DUT output mismatch at time %t, opcode = %h", i, $time, opcode);
                $display("  DUT:  %h", dut_concat);
                $display("  EXP:  %h", mem_exp[i]);
                FAILURES = FAILURES + 1;
            end else begin
                // $display("✅ TEST %0d PASS", i);
                SUCCESSES = SUCCESSES + 1;
            end
        end

        $display("---------------------------------------------------------");

        $display("FAILURES = %d out of %d\n", FAILURES, FAILURES + SUCCESSES);
        $display("SUCCESSES = %d out of %d\n", SUCCESSES, FAILURES + SUCCESSES);
        $finish;
    end

endmodule