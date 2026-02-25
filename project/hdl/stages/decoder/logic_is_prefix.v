/*
Module that determines given the input byte from the shift register, whether 
or not that byte is a prefix. It also outputs a signal that signfies if there 
is any prefix. 

Critical Path of Module: through is_any_prefix signal
Delay: 1.49ns delay
0.24ns + 0.8ns + 0.25ns + 0.2ns 
*/

module logic_is_prefix(
    input wire [7:0] candidate_prefix,
    output wire is_rep,
    output wire is_operand_size_override,
    output wire is_ext_opcode,
    output wire is_es,
    output wire is_cs,
    output wire is_ss,
    output wire is_ds,
    output wire is_fs,
    output wire is_gs,
    output wire is_any_prefix
);
    wire [7:0] REP = 8'hF3;
    wire [7:0] OP_SI_OV = 8'h66;
    wire [7:0] EXT_OP = 8'h0F;
    wire [7:0] ES = 8'h26;
    wire [7:0] CS = 8'h2E;
    wire [7:0] SS = 8'h36;
    wire [7:0] DS = 8'h3E;
    wire [7:0] FS = 8'h64;
    wire [7:0] GS = 8'h65;
    
    //Level 1: 0.24ns
    buffer8$ candidate_prefix_wire_buf(candidate_prefix_buf, candidate_prefix);

    //Level 2: 0.8ns delay 
    //Compare Opcode to all Prefixes in Parallel
    big_eq #(.WIDTH(8)) REP_compare ( 
        .in0(REP), 
        .in1(candidate_prefix_buf), 
        .eq(is_rep)
    );

    big_eq #(.WIDTH(8)) OP_SI_OV_compare ( 
        .in0(OP_SI_OV), 
        .in1(candidate_prefix_buf), 
        .eq(is_operand_size_override)
    );

    big_eq #(.WIDTH(8)) EXT_OP_compare ( 
        .in0(EXT_OP), 
        .in1(candidate_prefix_buf), 
        .eq(is_ext_opcode)
    );

    big_eq #(.WIDTH(8)) ES_compare ( 
        .in0(ES), 
        .in1(candidate_prefix_buf), 
        .eq(is_es)
    );

    big_eq #(.WIDTH(8)) CS_compare ( 
        .in0(CS), 
        .in1(candidate_prefix_buf), 
        .eq(is_cs)
    );

    big_eq #(.WIDTH(8)) SS_compare ( 
        .in0(SS), 
        .in1(candidate_prefix_buf), 
        .eq(is_ss)
    );

    big_eq #(.WIDTH(8)) DS_compare ( 
        .in0(DS), 
        .in1(candidate_prefix_buf), 
        .eq(is_ds)
    );

    big_eq #(.WIDTH(8)) FS_compare ( 
        .in0(FS), 
        .in1(candidate_prefix_buf), 
        .eq(is_fs)
    );

    big_eq #(.WIDTH(8)) GS_compare ( 
        .in0(GS), 
        .in1(candidate_prefix_buf), 
        .eq(is_gs)
    );

    //Level 3: 0.25ns delay 
    //OR 3 prefix wires per or gate
    wire nor_grp0, nor_grp1, nor_grp2;
    nor3$ nor0(nor_grp0, is_rep, is_operand_size_override, is_ext_opcode);
    nor3$ nor1(nor_grp1, is_es, is_cs, is_ss);
    nor3$ nor2(nor_grp2, is_ds, is_fs, is_gs);

    // Level 4: 0.2ns delay
    //NAND output of wires for completing the OR
    nand3$ nine_input_or(is_any_prefix, nor_grp0, nor_grp1, nor_grp2);

endmodule