/*
Branch Type: 00 (not a branch), 01 (unconditional near), 10 (conditional near), 11(far)
*/

module choose_eip(
    //eip incr logic
    input wire [3:0] instr_length,
    input wire [31:0] o_eip,
    output wire [31:0] i_eip,

    input wire ld_pr_rr, //to load register read pipeline registers signal
    input wire instr_valid, 
    input wire cur_instr_prediction,

    input wire ld_cs_ex,
    input wire flush_ex,
    input wire [31:0] bp_eip_target,
    input wire [31:0] ex_eip_target, //both reloads the meip and eip
    input wire [1:0] branch_type,
    input wire hit, //from btb to indicate if we have a bp target or not (currently hardcoded to 0)

    output wire ld_eip,
    output wire [31:0] eip_true


);  

    eip_incr EIP_INCR_LOGIC(
        .incr_amt(instr_length),
        .eip(o_eip),
        .incr_eip(i_eip)
    );

    /*
    Load EIP if: 
    1. Instruction is valid AND not stalling (LD_RR is high)
    2. OR if there's a mispredict (update eip to corret value from ex)
    3. OR if we need to update new CS (update eip to correct value from ex)
    */
    wire not_flush;
    wire not_ld_cs;
    wire nand_valid_ld;
    inv1$ INV_LD_CS(not_ld_cs, ld_cs_ex);
    inv1$ INV_FLUSH(not_flush, flush_ex);
    nand2$ NAND_VALID_LD(nand_valid_ld, instr_valid, ld_pr_rr);
    nand3$ NAND_FINAL(ld_eip, not_flush, not_ld_cs, nand_valid_ld);

    //Generating Signals for Mux Select
    wire [1:0] eip_sel; 
    wire stall, flush, is_branch, cond_take, uncond_take, take_branch, branch_type_0_bar;
    inv1$ INV_STALL(stall, ld_pr_rr); //stall if we're not loading new instruction into register read stage (same signal used for stalling in logic_stall_flush)
    or2$ OR_FLUSH(flush, flush_ex, ld_cs_ex); //flush if we're loading new CS or if there's a mispredict/exception in execute
    inv1$ INV_lower(branch_type_0_bar, branch_type[0]); //if branch type is not 00, then it's a branch
    and4$ AND_COND_PRED(cond_take, cur_instr_prediction, hit, branch_type[1], branch_type_0_bar); //if branch can be resolved AND predictor says taken AND unconditional
    and2$ AND_UNCOND_PRED(uncond_take, branch_type[0], hit); //if unconditional branch AND resolvable
    or2$ OR_TAKE_BRANCH(take_branch, uncond_take, cond_take); //if unconditional branch OR (resolvable conditional branch AND predictor says taken)
    comb_choose_eip EIP_SELECT_GN(.P2(flush), .P1(stall), .P0(take_branch), .OUT1(eip_sel[1]), .OUT0(eip_sel[0]));
    
    mux4_32 MUX_CHOOSE_EIP(
        .in0(i_eip), 
        .in1(bp_eip_target), 
        .in2(o_eip), 
        .in3(ex_eip_target), 
        .s0(eip_sel[0]), //Select incremented EIP if we're loading RR pipeline registers
        .s1(eip_sel[1]), //Currently unused, can be used to select other EIP sources in the future
        .out(eip_true) //Output EIP to be used in the rest of the decode logic
    );


endmodule