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

    wire instr_invalid;
    mag_comp8$ INSTR_VALID( 
        .A({4'b0, incr_amt}), 
        .B({3'b0, tail_ptr}),
        .AGB(instr_invalid), 
        .BGA() 
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