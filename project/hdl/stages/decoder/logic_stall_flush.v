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

        //Protection Exception Logic
        input wire [31:0] i_eip,
        input wire [19:0] cs_limit,

        //Instr Valid Logic
        input wire [3:0] tail_ptr,
        input wire [3:0] incr_amt,

        //Other Inputs
        input wire flush_ex, //comes from execute stage
        input wire ld_cs_ex, //comes from execute stage
        input wire stall_rr, //comes from register read stage

        output wire ld_pr_rr, //to load register read pipeline registers signal
        output wire instr_valid,
        output wire exptn_prot
);

    seg_limit_cmp EXCPTN_PROT( //Exception if EIP > CS Limit
        .in(i_eip),
        .seg_limit(cs_limit),
        .exception(exptn_prot)
    );	

    wire instr_invalid, instr_valid_w;
    cmp_gen_20b INSTR_VALID( //Instruction is crossing cache line boundary if incr_amt > tail_ptr
        .in0({16'b0, incr_amt}), .in1({16'b0, tail_ptr}),
        .lt(), .eq(), .gt(instr_invalid)
    );	
    inv1$ INV_INSTR_VALID(instr_valid_w, instr_invalid);


    wire ld_pr_rr_bar; //load register read pipeline registers signal
    wire any_flush_condition; 
    wire no_flush;
    wire ld_pr_rr_w;
    assign ld_pr_rr_bar = stall_rr; //stall if register read stage is stalled (we don't want to load new instruction into register read stage if it's stalled)
    inv1$ INV_LD_PR_RR(ld_pr_rr, ld_pr_rr_bar);
    
    or2$ OR_FLUSHES(any_flush_condition, flush_ex, ld_cs_ex);
    inv1$ INV_FLUSH(no_flush, any_flush_condition);

    and2$ AND_VALID(instr_valid,  no_flush, instr_valid_w);
endmodule