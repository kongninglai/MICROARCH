module FA_8b_behav(s, cout, in0, in1, cin);
	
	input		      [7:0]	in0, in1;
  input               cin;
	output	reg   [7:0]	s, cout;

  integer i;

  always @(*) begin
      cout[0] = (in0[0] & in1[0]) | ((in0[0] ^ in1[0]) & cin);
      s[0]    = in0[0] ^ in1[0] ^ cin;

      for (i = 1; i < 8; i = i + 1) begin
          s[i]    = in0[i] ^ in1[i] ^ cout[i-1];
          cout[i] = (in0[i] & in1[i]) | ((in0[i] ^ in1[i]) & cout[i-1]);
      end
  end


endmodule