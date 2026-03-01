module PA_4b_behav(s, in0, in1);
	
	input		      [3:0]	in0, in1;
	output	reg   [3:0]	s;


  reg   [3:0] cout;
  integer i;

  always @(*) begin
      cout[0] = in0[0] & in1[0];
      s[0]    = in0[0] ^ in1[0];

      for (i = 1; i < 4; i = i + 1) begin
          s[i]    = in0[i] ^ in1[i] ^ cout[i-1];
          cout[i] = (in0[i] & in1[i]) | ((in0[i] ^ in1[i]) & cout[i-1]);
      end
  end


endmodule