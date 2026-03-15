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
    input wire mispredict_src_ex,
    input wire v_ld_cs_src_ex,

    input wire [31:0] bp_eip_target,
    input wire [31:0] ex_eip_target,
    input wire [1:0] branch_type,

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
    wire not_mispredict;
    wire not_ld_cs;
    wire nand_valid_ld;
    inv1$ INV_MISPRED(not_mispredict, mispredict_src_ex);
    inv1$ INV_LD_CS(not_ld_cs, v_ld_cs_src_ex);
    nand2$ NAND_VALID_LD(nand_valid_ld, instr_valid, ld_pr_rr);
    nand3$ NAND_FINAL(ld_eip, not_mispredict, not_ld_cs, nand_valid_ld);

    //Generating Signals for Mux Select
    wire [1:0] eip_sel; 
    wire flush, stall, is_branch;
    or2$ OR_FLUSH_STALL_BRANCH(flush, mispredict_src_ex, v_ld_cs_src_ex);
    inv1$ INV_STALL(stall, ld_pr_rr);
    or2$ AND_BRANCH(is_branch, branch_type[0], branch_type[1]);
    comb_choose_eip EIP_SELECT_GN(.P2(flush), .P1(stall), .P0(is_branch), .OUT1(eip_sel[1]), .OUT0(eip_sel[0]));
    
    mux4_32 MUX_CHOOSE_EIP(
        .IN0(i_eip), //Default EIP
        .IN1(bp_eip_target), //Incremented EIP
        .IN2(o_eip), //Prediction: Branch predictor target EIP
        .IN3(ex_eip_target), //Calculated: Execute target
        .S0(eip_sel[0]), //Select incremented EIP if we're loading RR pipeline registers
        .S1(eip_sel[1]), //Currently unused, can be used to select other EIP sources in the future
        .Y(eip_true) //Output EIP to be used in the rest of the decode logic
    );


endmodule