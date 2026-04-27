module sat_cntr_behav(
    input wire CurState1, 
    input wire CurState0, 
    input wire Incr_or_Decr, 
	output reg NextState1, 
    output reg NextState0
);

    always @(*) begin
        case ({CurState1, CurState0, Incr_or_Decr})
            3'b000: {NextState1, NextState0} = 2'b00;
            3'b001: {NextState1, NextState0} = 2'b01;
            3'b010: {NextState1, NextState0} = 2'b00;
            3'b011: {NextState1, NextState0} = 2'b10;
            3'b100: {NextState1, NextState0} = 2'b01;
            3'b101: {NextState1, NextState0} = 2'b11;
            3'b110: {NextState1, NextState0} = 2'b10;
            3'b111: {NextState1, NextState0} = 2'b11;
            default: {NextState1, NextState0} = 2'b01;
        endcase
    end

endmodule