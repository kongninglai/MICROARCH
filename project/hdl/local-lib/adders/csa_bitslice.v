/*
Delay: 1.2ns total
*/
module csa_bitslice(
    input  a, b, c,
    output sum, carry
);
    wire n1, n2, n3, n4, n5, n6, n7;

    //Layer 0: 0.6ns (A^B)
    nand2$ nd1 (n1, a, b);
    nand2$ nd2 (n2, a, n1); //0.2ns
    nand2$ nd3 (n3, b, n1); //0.2ns
    nand2$ nd4 (n4, n2, n3); //0.2ns - n4 is now (A ^ B)

    //Layer 2: 0.4ns
    nand2$ nd5 (n5, n4, c); //0.2ns
    nand2$ nd6 (n6, n4, n5); //0.2ns
    nand2$ nd7 (n7, c, n5);
    
    // Layer 3: 0.2ns
    nand2$ nd_sum   (sum, n6, n7);   // Sum = A ^ B ^ C
    nand2$ nd_carry (carry, n1, n5); // Carry = AB + C(A ^ B)
endmodule