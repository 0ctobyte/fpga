// 7 Segment Controller
// Memory mapped interface to the 7 segment displays over the system bus

module seg7_controller #(
    parameter ADDR_WIDTH    = 32,
    parameter DATA_WIDTH    = 32,
    parameter BASE_ADDR     = 32'hc0001000,
    parameter NUM_7SEGMENTS = 8          // Should be between 0 and 8
) (
    input  logic       clk,
    input  logic       n_rst,

    // Bus interface
    bus_if             bus,

    // Seven segment display output
    output logic [6:0] o_hex [0:NUM_7SEGMENTS-1]
);

    // BIU slave interface
    biu_slave_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) biu ();

    logic [DATA_WIDTH-1:0] hex_q;

    assign biu.data_out   = hex_q;
    assign biu.data_valid = (biu.en && biu.rnw);

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            hex_q <= 'b0;
        end else if (biu.en && ~biu.rnw) begin
            hex_q <= biu.data_in;
        end
    end

    biu_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BASE_ADDR(BASE_ADDR),
        .ADDR_SPAN(4),
        .ALIGNED(1)
    ) biu_slave_inst (
        .clk(clk),
        .n_rst(n_rst),
        .bus(bus),
        .biu(biu)
    );

    // Generate seven segment modules, each module uses 4-bits from the 32-bit hex_q register
    genvar i;
    generate
    for (i = 0; i < NUM_7SEGMENTS; i++) begin : GENERATE_SEG7_DECODERS
        seg7_decoder seg7_decoder_inst (
            .n_rst(n_rst),
            .i_hex(hex_q[i*4+3:i*4]),
            .o_hex(o_hex[i])
        );
    end
    endgenerate

endmodule

