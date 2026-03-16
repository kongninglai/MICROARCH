/*
Branch Predictor is hardwired to 0 (not taken). Also, current bp design 
results in using a stale value of the GHR because updates only happen in 
execute and we don't wait. So, as a later optmization, can potentially 
add a speculative ghr later on. 
*/

module bp(
    input wire clk,
    input wire rst_bar,
    input wire is_branch, //predict current instruction in decode (if branch)
    input wire [31:0] o_eip, //predict current instruction in decode (if branch)
    input wire br_t_nt_ex_d, //comes from execute stage (taken not taken signal)
    input wire br_valid_ex_d, //comes from execute stage (branch valid signal)
    input wire [3:0] ext_pht_idx, //comes from execute stage: branch counter TO UPDATE

    output wire cur_instr_prediction, //to decode stage 
    output wire [7:0] ghr_out
);

    //Update GHR based on execute stage branch OR read GHR for current instruction in decode stage
    wire [7:0] ghr_in;
    mux2_8$ GHR_IN_MUX(.Y(ghr_in), .IN0(ghr_out), .IN1({ghr_out[6:0], br_t_nt_ex_d}), .S0(br_valid_ex_d));
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

     predictor PREDICTOR(
        .clk(clk),
        .rst_bar(rst_bar),
        .br_t_nt_in(br_t_nt_ex_d), //to update pht for instr in execute stage
        .ext_pht_idx(ext_pht_idx), //to update pht for instr in execute stage
        .b_pht_idx(hash_out), //to predict cur instruction in decode stage
        .b_valid(is_branch), //to predict cur instruction in decode stage
        .br_t_nt_out(cur_instr_prediction)
    );

endmodule

