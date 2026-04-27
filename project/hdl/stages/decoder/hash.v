/*
Hash function for branch predictor. 
Uses history folding of GHR, and hashes (xor) folder history with eip.
*/
module hash(
    input wire [3:0] eip,
    input wire [7:0] ghr,
    output wire [3:0] hash_out
);  
    wire [3:0] folded_ghr, hash_out_prebuf;
    xor2$ FOLD_XOR [3:0] (.out(folded_ghr), .in0(ghr[7:4]), .in1(ghr[3:0]));
    xnor2$ HASH_XOR [3:0] (.out(hash_out), .in0(folded_ghr), .in1(eip));

    bufferHInv16$ bufferHInv16$_hash_out[3:0](hash_out, hash_out_prebuf);	   

endmodule
