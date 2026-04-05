module SUB_32b (
    input		[31:0]	  in0, in1,
    input                 cin,
	output	    [31:0]	  s, cout
);
    // in0 - in1 = in0 + (~in1) + 1
    wire [31:0] inv_in1;
    inv1$ inv_in1_inst[31:0](inv_in1, in1);

    wire inv_cin;
    inv1$ inv_cin_inst(inv_cin, cin);
    FA_32b FA32_SBB(.in0(in0), .in1(inv_in1), .cin(inv_cin), .s(s), .cout(cout));

endmodule