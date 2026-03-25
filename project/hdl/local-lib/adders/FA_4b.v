    /*
    Delay 1.9ns
    */

    module FA_4b (
        input  [3:0] in0, in1,
        input        cin,
        output [3:0] s
    );
        // Layer 0: 0.35ns
        wire [3:-1] Gi_i, Pi_i;
        assign Gi_i[-1] = cin;
        assign Pi_i[-1] = 1'b0;

        gen_prop gen_prop_init[3:0](Gi_i[3:0], Pi_i[3:0], in0[3:0], in1[3:0]);

        // Layer 1: 0.6ns
        wire [3:0] G1, P1;
        gen_prop_2 st1_0(G1[0], P1[0], Pi_i[0], Pi_i[-1], Gi_i[0], Gi_i[-1]); // 0:-1
        gen_prop_2 st1_1(G1[1], P1[1], Pi_i[1], Pi_i[0],  Gi_i[1], Gi_i[0]);  // 1:0
        gen_prop_2 st1_2(G1[2], P1[2], Pi_i[2], Pi_i[1],  Gi_i[2], Gi_i[1]);  // 2:1
        gen_prop_2 st1_3(G1[3], P1[3], Pi_i[3], Pi_i[2],  Gi_i[3], Gi_i[2]);  // 3:2

        // Layer 2: 0.6ns
        wire [3:1] G2, P2;
        gen_prop_2 st2_1(G2[1], P2[1], P1[1], Pi_i[-1], G1[1], Gi_i[-1]); // 1:-1
        gen_prop_2 st2_2(G2[2], P2[2], P1[2], P1[0],    G1[2], G1[0]);    // 2:0
        gen_prop_2 st2_3(G2[3], P2[3], P1[3], P1[1],    G1[3], G1[1]);    // 3:1
        
        // Layer 4 (Summation): 0.35ns
        xor3LL sum0(s[0], Gi_i[-1], in0[0], in1[0]); 
        xor3LL sum1(s[1], G1[0],    in0[1], in1[1]); 
        xor3LL sum2(s[2], G2[1],    in0[2], in1[2]); 
        xor3LL sum3(s[3], G2[2],    in0[3], in1[3]); 

    endmodule