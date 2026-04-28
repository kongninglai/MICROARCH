module stack_bh #(
    parameter WIDTH = 32,
    parameter DEPTH = 4,
    parameter PTR_WIDTH = 2
)(
    input clk,
    input rst_n,

    input push,
    input pop,
    input flush,
    input [WIDTH-1:0] push_data,

    output [WIDTH-1:0] pop_data,
    output [WIDTH-1:0] top_data,
    output [PTR_WIDTH:0] count,
    output empty,
    output full
); 

    localparam [PTR_WIDTH:0] DEPTH_VALUE = DEPTH;
    localparam [PTR_WIDTH:0] ZERO = {(PTR_WIDTH+1){1'b0}};
    localparam [PTR_WIDTH:0] ONE = {{PTR_WIDTH{1'b0}}, 1'b1};

    reg [WIDTH-1:0] stack [0:DEPTH-1];
    reg [PTR_WIDTH:0] sp;

    wire push_ok;
    wire pop_ok;
    wire push_only;
    wire pop_only;
    wire push_pop;
    wire [PTR_WIDTH:0] top_idx;

    assign empty = (sp == ZERO);
    assign full = (sp == DEPTH_VALUE);
    assign count = sp;

    assign push_ok = push && (!full || pop);
    assign pop_ok = pop && !empty;
    assign push_only = push_ok && !pop_ok;
    assign pop_only = pop_ok && !push_ok;
    assign push_pop = push_ok && pop_ok;

    assign top_idx = sp - ONE;
    assign top_data = empty ? {WIDTH{1'b0}} : stack[top_idx[PTR_WIDTH-1:0]];
    assign pop_data = top_data;

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sp <= ZERO;
            for (i = 0; i < DEPTH; i = i + 1) begin
                stack[i] <= {WIDTH{1'b0}};
            end
        end else begin
            if (flush) begin
                sp <= ZERO;
            end else if (push_pop) begin
                stack[top_idx[PTR_WIDTH-1:0]] <= push_data;
            end else if (push_only) begin
                stack[sp[PTR_WIDTH-1:0]] <= push_data;
                sp <= sp + ONE;
            end else if (pop_only) begin
                sp <= sp - ONE;
            end
        end
    end

endmodule
