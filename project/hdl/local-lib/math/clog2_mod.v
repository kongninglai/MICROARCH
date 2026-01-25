module clog2_mod;

  function integer clog2;
    input integer inp;
    integer i;
    begin
      clog2 = 0;
      if (inp <= 1) begin
        clog2 = 1;
      end else begin
        inp = inp - 1;
        for (i = 0; inp > 0; i = i + 1) begin
          inp = inp >> 1;
        end
        clog2 = i;
      end
    end
  endfunction

endmodule