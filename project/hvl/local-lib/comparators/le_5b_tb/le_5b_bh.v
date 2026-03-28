module le_5b_bh(
	output LE,
	input [4:0] A,
	input [4:0] B
);

    assign LE= (A <= B);
endmodule