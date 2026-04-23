/*
Branch Predictor is hardwired to 0 (not taken). Also, current bp design 
results in using a stale value of the GHR because updates only happen in 
execute and we don't wait. So, as a later optmization, can potentially 
add a speculative ghr later on. 
*/

module bp(
    input wire clk,
    input wire rst_bar,

    input wire [7:0] opcode,
    input wire [47:0] imm,
    input wire op_size_overload,
    input wire prefix_ext,

    input wire is_branch, //predict current instruction in decode (if branch)
    input wire [31:0] o_eip, 
    input wire [31:0] i_eip, //predict current instruction in decode (if branch)
    input wire br_t_nt_ex_d, //comes from execute stage (taken not taken signal)
    input wire br_valid_ex_d, //comes from execute stage (branch valid signal)
    input wire [3:0] ext_pht_idx, //comes from execute stage: branch counter TO UPDATE

    output wire [31:0] bp_eip_target, //to decode stage for current instruction if bp says taken
    output wire hit, //to decode stage to indicate if we have a bp target or not (currently hardcoded to 0)

    output wire cur_instr_prediction, //to decode stage 
    output wire [3:0] pht_idx,
    output wire [7:0] ghr_out
);

    //Update GHR based on execute stage branch OR read GHR for current instruction in decode stage
    wire [7:0] ghr_in;
    mux2_8$ GHR_IN_MUX(.Y(ghr_in), .IN0(ghr_out), .IN1({ghr_out[6:0], cur_instr_prediction}), .S0(is_branch));
    ghr GHR(
        .clk(clk), 
        .rst_bar(rst_bar),
        .ghr_in(ghr_in),
        .ghr_out(ghr_out)
    );
    
    wire [3:0] hash_out;
    hash HASH_FUNCTION(
        .eip(o_eip[3:0]),
        .ghr(ghr_out),
        .hash_out(hash_out)
    );

    assign pht_idx = hash_out;

    predictor PREDICTOR(
        .clk(clk),
        .rst_bar(rst_bar),
        .br_t_nt_in(br_t_nt_ex_d), //to update pht for instr in execute stage
        .ext_pht_idx(ext_pht_idx), //to update pht for instr in execute stage
        .from_ex_br_valid(br_valid_ex_d), //to update pht for instr in execute stage
        .b_pht_idx(hash_out), //to predict cur instruction in decode stage
        .from_de_br_valid(is_branch), //to predict cur instruction in decode stage
        .br_t_nt_out(cur_instr_prediction)
    );

    br_target BR_TARGET(
        .i_eip (i_eip),
        .opcode (opcode),
        .imm(imm),
        .op_size_overload(op_size_overload),
        .prefix_ext(prefix_ext),
        .hit(hit), //currently not used since we're hardcoding to not hit
        .bp_eip_target (bp_eip_target)
    );
    
endmodule

