module fact_mod;
  function integer fact;
    input integer inp;
    integer i;
    begin
      fact = 1;
      if (inp < 0) begin
          fact = 0;
      end else begin
        for (i = 1; i <= inp; i = i + 1) begin
          fact = fact * i;
        end
      end
    end
  endfunction
endmodule