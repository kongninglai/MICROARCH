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

        //Instr Valid Logic
        input wire [4:0] tail_ptr,
        input wire [3:0] incr_amt,

        //Other Inputs
        input wire flush_ex, //comes from execute stage
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


    wire ld_pr_rr_bar; //load register read pipeline registers signal
    wire any_flush_condition;
    wire ld_pr_rr_w;
    assign ld_pr_rr_bar = stall_rr; //stall if register read stage is stalled (we don't want to load new instruction into register read stage if it's stalled)
    inv1$ INV_LD_PR_RR(ld_pr_rr, ld_pr_rr_bar);
    

    nor2$ AND_VALID(instr_valid,  flush_ex, instr_invalid);
endmodule