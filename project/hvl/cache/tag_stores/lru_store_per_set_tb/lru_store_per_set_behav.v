module lru_store_per_set_behav (
    input rst, clk, valid,
    input T1, T0,
    output reg V1, V0
);

reg [4:0] state, next_state;

always @(*) begin
  if (valid) begin
    case (state)
        5'b00000: case ({T1,T0})
            2'b00: next_state = 5'b01011; 2'b01: next_state = 5'b00011;
            2'b10: next_state = 5'b00001; 2'b11: next_state = 5'b00000;
        endcase
        5'b00001: case ({T1,T0})
            2'b00: next_state = 5'b01101; 2'b01: next_state = 5'b00101;
            2'b10: next_state = 5'b00001; 2'b11: next_state = 5'b00000;
        endcase
        5'b00010: case ({T1,T0})
            2'b00: next_state = 5'b10011; 2'b01: next_state = 5'b00011;
            2'b10: next_state = 5'b00001; 2'b11: next_state = 5'b00010;
        endcase
        5'b00011: case ({T1,T0})
            2'b00: next_state = 5'b10101; 2'b01: next_state = 5'b00011;
            2'b10: next_state = 5'b00100; 2'b11: next_state = 5'b00010;
        endcase
        5'b00100: case ({T1,T0})
            2'b00: next_state = 5'b11011; 2'b01: next_state = 5'b00101;
            2'b10: next_state = 5'b00100; 2'b11: next_state = 5'b00000;
        endcase
        5'b00101: case ({T1,T0})
            2'b00: next_state = 5'b11101; 2'b01: next_state = 5'b00101;
            2'b10: next_state = 5'b00100; 2'b11: next_state = 5'b00010;
        endcase
        5'b01000: case ({T1,T0})
            2'b00: next_state = 5'b01011; 2'b01: next_state = 5'b00011;
            2'b10: next_state = 5'b01001; 2'b11: next_state = 5'b01000;
        endcase
        5'b01001: case ({T1,T0})
            2'b00: next_state = 5'b01101; 2'b01: next_state = 5'b00101;
            2'b10: next_state = 5'b01001; 2'b11: next_state = 5'b01000;
        endcase
        5'b01010: case ({T1,T0})
            2'b00: next_state = 5'b01011; 2'b01: next_state = 5'b10001;
            2'b10: next_state = 5'b01001; 2'b11: next_state = 5'b01010;
        endcase
        5'b01011: case ({T1,T0})
            2'b00: next_state = 5'b01011; 2'b01: next_state = 5'b10100;
            2'b10: next_state = 5'b01100; 2'b11: next_state = 5'b01010;
        endcase
        5'b01100: case ({T1,T0})
            2'b00: next_state = 5'b01101; 2'b01: next_state = 5'b11001;
            2'b10: next_state = 5'b01100; 2'b11: next_state = 5'b01000;
        endcase
        5'b01101: case ({T1,T0})
            2'b00: next_state = 5'b01101; 2'b01: next_state = 5'b11100;
            2'b10: next_state = 5'b01100; 2'b11: next_state = 5'b01010;
        endcase
        5'b10000: case ({T1,T0})
            2'b00: next_state = 5'b10011; 2'b01: next_state = 5'b10001;
            2'b10: next_state = 5'b00001; 2'b11: next_state = 5'b10000;
        endcase
        5'b10001: case ({T1,T0})
            2'b00: next_state = 5'b10101; 2'b01: next_state = 5'b10001;
            2'b10: next_state = 5'b00100; 2'b11: next_state = 5'b10000;
        endcase
        5'b10010: case ({T1,T0})
            2'b00: next_state = 5'b10011; 2'b01: next_state = 5'b10001;
            2'b10: next_state = 5'b01001; 2'b11: next_state = 5'b10010;
        endcase
        5'b10011: case ({T1,T0})
            2'b00: next_state = 5'b10011; 2'b01: next_state = 5'b10100;
            2'b10: next_state = 5'b01100; 2'b11: next_state = 5'b10010;
        endcase
        5'b10100: case ({T1,T0})
            2'b00: next_state = 5'b10101; 2'b01: next_state = 5'b10100;
            2'b10: next_state = 5'b11000; 2'b11: next_state = 5'b10000;
        endcase
        5'b10101: case ({T1,T0})
            2'b00: next_state = 5'b10101; 2'b01: next_state = 5'b10100;
            2'b10: next_state = 5'b11010; 2'b11: next_state = 5'b10010;
        endcase
        5'b11000: case ({T1,T0})
            2'b00: next_state = 5'b11011; 2'b01: next_state = 5'b11001;
            2'b10: next_state = 5'b11000; 2'b11: next_state = 5'b00000;
        endcase
        5'b11001: case ({T1,T0})
            2'b00: next_state = 5'b11101; 2'b01: next_state = 5'b11001;
            2'b10: next_state = 5'b11000; 2'b11: next_state = 5'b00010;
        endcase
        5'b11010: case ({T1,T0})
            2'b00: next_state = 5'b11011; 2'b01: next_state = 5'b11001;
            2'b10: next_state = 5'b11010; 2'b11: next_state = 5'b01000;
        endcase
        5'b11011: case ({T1,T0})
            2'b00: next_state = 5'b11011; 2'b01: next_state = 5'b11100;
            2'b10: next_state = 5'b11010; 2'b11: next_state = 5'b01010;
        endcase
        5'b11100: case ({T1,T0})
            2'b00: next_state = 5'b11101; 2'b01: next_state = 5'b11100;
            2'b10: next_state = 5'b11000; 2'b11: next_state = 5'b10000;
        endcase
        5'b11101: case ({T1,T0})
            2'b00: next_state = 5'b11101; 2'b01: next_state = 5'b11100;
            2'b10: next_state = 5'b11010; 2'b11: next_state = 5'b10010;
        endcase
        default: next_state = 5'b00000;
    endcase
  end else begin
    next_state <= state;
  end
end

always @(posedge clk or negedge rst) begin
    if (!rst) state <= 5'b00000;
    else state <= next_state;
end

always @(*) begin
    V1 = state[4];
    V0 = state[3];
end

endmodule