module return_address_stack(
    input           clk,
    input           rst_n,

    input [7:0]     opcode,
    input [7:0]     modrm,
    input [31:0]    ieip,
    input           ld_pr_rr,
    input           instr_valid,
    input           flush_ex,

    output  [31:0]  target_eip,
    output          valid_ret              
); 

    // Return Address Stack for near Call:
    // we need to push the ieip into the stack when we see a call near (E8, FF/2)
    // And pop from the stack when we see a ret near (C2, C3)

    // flush: do nothing; 
    // stask is full: flush the stack;
    wire flush_ras;
    wire push, pop, empty, full;

    assign push = ((opcode==8'hE8) | ((opcode==8'hFF) & (modrm[5:3]==2'b10))) & (ld_pr_rr & instr_valid & ~flush_ex);
    assign pop = ((opcode==8'hC2) | (opcode==8'hC3)) & (ld_pr_rr & instr_valid & ~flush_ex);
    assign flush_ras = (full & push);
    assign valid_ret = pop & ~empty;
    
    stack_bh RAS(
        .clk(clk),
        .rst_n(rst_n),
        .push(push),
        .pop(pop),
        .flush(flush_ras),
        .push_data(ieip),
        .pop_data(target_eip),
        .top_data(),
        .count(),
        .empty(empty),
        .full(full)
    );


endmodule
