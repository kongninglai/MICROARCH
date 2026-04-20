/*
This module determines the STALL and FLUSH logic. 

Note: 
- We won't be invalidating the instruction if it is an
exception causing instructiom. We want to wait until wb to 
do that, otherwise we won't be able to know whether or not 
the instruction is actually an exception causing instruction
or just randomly got set to be invalid because of something 
else in the pipeline. 
- We won't be invalidating instructions after the exception 
causing instruction because it acts like a prefetcher. Only 
invalidate once exception is handled in wb. 

*/

module logic_stall_flush(
        input wire clk,
        input wire rst_bar,

        //Protection Exception Logic
        input wire [31:0] i_eip,

        //Instr Valid Logic
        input wire [4:0] tail_ptr,
        input wire [3:0] incr_amt,

        //Other Inputs
        input wire flush_ex, //comes from execute stage
        input wire flush_wb, //comes from writeback stage
        input wire stall_rr, //comes from register read stage

        output wire ld_pr_rr, //to load register read pipeline registers signal
        output wire instr_valid
);

    wire [15:0] invalids, invalids_final;

    lshf_var_16b lshf_var_16b_invalids (
      .in({16{1'b1}}),
      .shf_amt(tail_ptr[3:0]),
      .out(invalids)
    );

    mux2_8$   mux2_8$_invalids_final_low
    (
      invalids_final[7:0],
      invalids[7:0],
      8'd0,
      tail_ptr[4]
    );

    mux2_8$   mux2_8$_invalids_final_high
    (
      invalids_final[15:8],
      invalids[15:8],
      8'd0,
      tail_ptr[4]
    );

    mux16 mux16_instr_invalid
    (
      instr_invalid,
      1'b1,
      invalids_final[0],
      invalids_final[1],
      invalids_final[2],
      invalids_final[3],
      invalids_final[4],
      invalids_final[5],
      invalids_final[6],
      invalids_final[7],
      invalids_final[8],
      invalids_final[9],
      invalids_final[10],
      invalids_final[11],
      invalids_final[12],
      invalids_final[13],
      invalids_final[14],
      incr_amt[0],
      incr_amt[1],
      incr_amt[2],
      incr_amt[3]
    );

    wire any_flush_condition; 
    wire no_flush;
    wire ld_pr_rr_w, ld_pr_rr_without_flush;

    inv1$ INV_FLUSH(no_flush, flush_ex);
    nand2$ nand_ld_pr_rr(ld_pr_rr, stall_rr, no_flush); //also stall if we need to flush because of execute stage
    
    wire pending_intex;
    wire either_flush;
    or2$    or2$_either_flush(either_flush, flush_ex, flush_wb);

    // Start out not pending (rst --> 1'b0)
    // any flush_ex will remain not pending
    // if flush_wb, then becomes pending
    // the next flush_ex will clear pending
    reg_n #(
      .WIDTH(1)
    ) reg_n_Q_CC_DATA_WR_MASK_OUT_10 (
      .clk(clk), .rst(rst_bar),
      .en(either_flush), .d(flush_wb),
      .q(pending_intex)
    );

    nor3$ AND_VALID(instr_valid,  flush_ex, instr_invalid, pending_intex);
endmodule