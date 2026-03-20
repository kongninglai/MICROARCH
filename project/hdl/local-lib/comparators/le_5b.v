module le_5b(
    output LE,
    input  [4:0] A,
    input  [4:0] B
);

    /* I/Os */
    wire A4, A3, A2, A1, A0;
    wire B4, B3, B2, B1, B0;
    assign {A4, A3, A2, A1, A0} = A;
    assign {B4, B3, B2, B1, B0} = B;

    /* Inverters for A */
    wire A4_bar, A3_bar, A2_bar, A1_bar, A0_bar;
    inv1$ inv_a4(A4_bar, A4);
    inv1$ inv_a3(A3_bar, A3);
    inv1$ inv_a2(A2_bar, A2);
    inv1$ inv_a1(A1_bar, A1);
    inv1$ inv_a0(A0_bar, A0);

    /* Per-bit equality: eqi = ~(Ai ^ Bi) */
    wire xor4_out, xor3_out, xor2_out, xor1_out, xor0_out;
    wire eq4, eq3, eq2, eq1, eq0;

    xor2$ xor_4(xor4_out, A4, B4);
    xor2$ xor_3(xor3_out, A3, B3);
    xor2$ xor_2(xor2_out, A2, B2);
    xor2$ xor_1(xor1_out, A1, B1);
    xor2$ xor_0(xor0_out, A0, B0);

    inv1$ inv_eq4(eq4, xor4_out);
    inv1$ inv_eq3(eq3, xor3_out);
    inv1$ inv_eq2(eq2, xor2_out);
    inv1$ inv_eq1(eq1, xor1_out);
    inv1$ inv_eq0(eq0, xor0_out);

    /* Prefix equalities */
    wire eq43, eq432, eq4321, EQ;
    and2$ and_eq43  (eq43,   eq4,   eq3);
    and2$ and_eq432 (eq432,  eq43,  eq2);
    and2$ and_eq4321(eq4321, eq432, eq1);
    and2$ and_EQ    (EQ,     eq4321, eq0);

    /* Less-than product terms */
    wire lt4, lt3, lt2, lt1, lt0;

    /* lt4 = ~A4 & B4 */
    and2$ and_lt4(lt4, A4_bar, B4);

    /* lt3 = eq4 & ~A3 & B3 */
    wire lt3_pre;
    and2$ and_lt3_pre(lt3_pre, eq4, A3_bar);
    and2$ and_lt3    (lt3, lt3_pre, B3);

    /* lt2 = eq4 & eq3 & ~A2 & B2 = eq43 & ~A2 & B2 */
    wire lt2_pre;
    and2$ and_lt2_pre(lt2_pre, eq43, A2_bar);
    and2$ and_lt2    (lt2, lt2_pre, B2);

    /* lt1 = eq4 & eq3 & eq2 & ~A1 & B1 = eq432 & ~A1 & B1 */
    wire lt1_pre;
    and2$ and_lt1_pre(lt1_pre, eq432, A1_bar);
    and2$ and_lt1    (lt1, lt1_pre, B1);

    /* lt0 = eq4 & eq3 & eq2 & eq1 & ~A0 & B0 = eq4321 & ~A0 & B0 */
    wire lt0_pre;
    and2$ and_lt0_pre(lt0_pre, eq4321, A0_bar);
    and2$ and_lt0    (lt0, lt0_pre, B0);

    /* LT = lt4 | lt3 | lt2 | lt1 | lt0 */
    wire lt43, lt432, LT;
    or2$ or_lt43 (lt43,  lt4,   lt3);
    or2$ or_lt432(lt432, lt43,  lt2);
    or2$ or_lt1  (LT,    lt432 | lt1, lt0); // <- replace if your library disallows expressions

    /* LE = LT | EQ */
    or2$ or_le(LE, LT, EQ);

endmodule
