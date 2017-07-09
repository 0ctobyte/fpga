// Clock divider

module clk_div #(
    parameter  CLK_FREQ = 50000000,
    parameter  TGT_FREQ = 25000000
) (
    input  wire clk,
    input  wire n_rst,

    input  wire i_en,
    output wire o_clk
);

    localparam CLK_DIV  = int'(CLK_FREQ/TGT_FREQ + 0.5);

    reg [$clog2(CLK_DIV)-1:0] counter;

    assign o_clk = (counter < (CLK_DIV/2));

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            counter <= 'b0;
        end else if (i_en && counter != CLK_DIV) begin
            counter <= counter + 1'b1;
        end else begin
            counter <= 'b0;
        end
    end

endmodule
