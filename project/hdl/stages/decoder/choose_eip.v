/*
Branch Type: 00 (not a branch), 01 (unconditional near), 10 (conditional near), 11(far)
*/

module choose_eip #(
    parameter BP_EN=1'b1
)(
    input wire clk,
    input wire rst_bar, 

    //eip incr logic
    input wire [2:0] sum_1_lower,
    input wire [3:0] instr_length,    

    input wire ld_pr_rr, //to load register read pipeline registers signal
    input wire instr_valid, 
    input wire cur_instr_prediction,

    input wire flush_ex,
    input wire [31:0] bp_eip_target,
    input wire [31:0] ex_eip_target, //both reloads the meip and eip
    input wire [1:0] branch_type,
    input wire hit, //from btb to indicate if we have a bp target or not (currently hardcoded to 0)

    output wire [31:0] i_eip_br,
    output wire [31:0] i_eip,
    output wire [31:0] o_eip,
    output wire ld_eip,
    output wire [31:0] eip_true,
    output wire take_branch

);  
    wire [31:0] i_eip_prebuf;

    eip_incr EIP_INCR_LOGIC(
        .incr_amt(instr_length),
        .eip(o_eip),
        .incr_eip(i_eip_prebuf)
    );

    bufferH16$  bufferH16$_i_eip[31:0](i_eip, i_eip_prebuf);

    eip_incr_br EIP_INCR_LOGIC_BR(
        .incr_amt(sum_1_lower),
        .eip(o_eip),
        .incr_eip(i_eip_br)
    );

    /*
    Load EIP if: 
    1. Instruction is valid AND not stalling (LD_RR is high)
    2. OR if there's a mispredict (update eip to corret value from ex)
    3. OR if we need to update new CS (update eip to correct value from ex)
    */
    wire not_flush;
    wire nand_valid_ld;
    wire ld_eip_prebuf;
    inv1$ INV_FLUSH(not_flush, flush_ex);
    nand2$ NAND_VALID_LD(nand_valid_ld, instr_valid, ld_pr_rr);
    nand2$ NAND_FINAL(ld_eip, not_flush, nand_valid_ld);

    //Generating Signals for Mux Select
    wire [1:0] eip_sel;
    wire bp_take_branch; 
    wire stall, is_branch, cond_take, uncond_take, branch_type_0_bar, take_branch_w;
    inv1$ INV_lower(branch_type_0_bar, branch_type[0]); //if branch type is not 00, then it's a branch
    nand3$ AND_COND_PRED(cond_take, cur_instr_prediction, ld_eip, branch_type[1]); //if branch can be resolved AND predictor says taken AND unconditional
    nand2$ AND_UNCOND_PRED(uncond_take, branch_type[0], ld_eip); //if unconditional branch AND resolvable
    nand2$ OR_TAKE_BRANCH(bp_take_branch, uncond_take, cond_take); //if unconditional branch OR (resolvable conditional branch AND predictor says taken)
    
    generate 
        if (BP_EN) begin 
            assign take_branch = bp_take_branch;
        end else begin 
            assign take_branch = 1'b0;
        end
    endgenerate

    mux4_32 MUX_CHOOSE_EIP(
        .in0(i_eip), 
        .in1(bp_eip_target), 
        .in2(ex_eip_target), 
        .in3(ex_eip_target), 
        .s0(take_branch), //Select incremented EIP if we're loading RR pipeline registers
        .s1(flush_ex), //Currently unused, can be used to select other EIP sources in the future
        .out(eip_true) //Output EIP to be used in the rest of the decode logic
    );

    wire [31:0] o_eip_prebuf;

    reg_n_16 #(.WIDTH(16), .USE_EN_BAR(1'b0), .RESET_TO_ONES(1'b0)) FEIP_REG_high (
        .clk(clk),
        .rst(rst_bar),
        .en(ld_eip),
        .d(eip_true[31:16]),
        .q(o_eip_prebuf[31:16])
    );

    reg_n_16 #(.WIDTH(16), .USE_EN_BAR(1'b0), .RESET_TO_ONES(1'b0)) FEIP_REG_low (
        .clk(clk),
        .rst(rst_bar),
        .en(ld_eip),
        .d(eip_true[15:0]),
        .q(o_eip_prebuf[15:0])
    );

    bufferH256$    bufferH256$_o_eip[31:0](o_eip, o_eip_prebuf);

endmodule