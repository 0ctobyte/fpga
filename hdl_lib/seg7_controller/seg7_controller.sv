// 7 Segment Controller
// Memory mapped interface to the 7 segment displays over the system bus

module seg7_controller #(
    parameter ADDR_WIDTH    = 32,
    parameter DATA_WIDTH    = 32,
    parameter BASE_ADDR     = 32'hc0001000,
    parameter NUM_7SEGMENTS = 8          // Should be between 0 and 8
) (
    input  wire                  clk,
    input  wire                  n_rst,

    // Bus interface
    inout  wire [ADDR_WIDTH-1:0] bus_address,
    inout  wire [DATA_WIDTH-1:0] bus_data,
    inout  wire [1:0]            bus_control,

    // Seven segment display output
    output wire [6:0]            o_hex [0:NUM_7SEGMENTS-1]
);

    reg [DATA_WIDTH-1:0] hex_q;

    // BIU slave interface
    wire [ADDR_WIDTH-1:0] biu_slave_address;
    wire [DATA_WIDTH-1:0] biu_slave_data_in;
    wire                  biu_slave_rnw;
    wire                  biu_slave_en;
    wire [DATA_WIDTH-1:0] biu_slave_data_out;
    wire                  biu_slave_data_valid;

    assign biu_slave_data_out   = hex_q;
    assign biu_slave_data_valid = (biu_slave_en && biu_slave_rnw);

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            hex_q <= 'b0;
        end else if (biu_slave_en && ~biu_slave_rnw) begin
            hex_q <= biu_slave_data_in;
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
        .bus_address(bus_address),
        .bus_data(bus_data),
        .bus_control(bus_control),
        .o_address(biu_slave_address),
        .o_data_in(biu_slave_data_in),
        .o_rnw(biu_slave_rnw),
        .o_en(biu_slave_en),
        .i_data_out(biu_slave_data_out),
        .i_data_valid(biu_slave_data_valid)
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

