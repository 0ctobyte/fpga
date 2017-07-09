`define ADDR_WIDTH 32
`define DATA_WIDTH 32
`define SLAVE_ADDR 32'hc0000000
`define ADDR_SPAN  32'h4
`define ALIGNED    1'b1 

module biu_test_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) ( 
    input  wire                  clk,
    input  wire                  n_rst,

    // Switch input
    input  wire [15:0]            sw_input,

    // BIU Master interface
    output wire [ADDR_WIDTH-1:0] o_address,
    output wire [DATA_WIDTH-1:0] o_data_out,
    output wire                  o_rnw,
    output wire                  o_en,
    input  wire [DATA_WIDTH-1:0] i_data_in,
    input  wire                  i_data_valid,
    input  wire                  i_busy 
);

    wire [15:0] syncd_sw;
    reg  [15:0] syncd_sw_q [0:2];

    assign o_address  = `SLAVE_ADDR;
    assign o_data_out = {syncd_sw, syncd_sw};
    assign o_rnw      = 1'b0;
    assign o_en       = (syncd_sw_q[2] != syncd_sw && syncd_sw_q[2] != syncd_sw_q[0] && syncd_sw_q[2] != syncd_sw_q[1] && ~i_busy);
    
    synchronizer #(
        .DATA_WIDTH(16),
        .SYNC_DEPTH(2)
    ) switch_synchronizer (
        .clk(clk),
        .n_rst(n_rst),
        .i_async_data(sw_input),
        .o_sync_data(syncd_sw)
    );

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            syncd_sw_q[0] <= 'b0;
            syncd_sw_q[1] <= 'b0;
            syncd_sw_q[2] <= 'b0;
        end else begin
            syncd_sw_q[0] <= syncd_sw;
            syncd_sw_q[1] <= syncd_sw_q[0];
            syncd_sw_q[2] <= syncd_sw_q[1];
        end
    end 

endmodule

module biu_test (
    input  wire         CLOCK_50,

    input  wire [17:0]  SW,
    output wire [6:0]   HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7
);

    // Shared bus
    tri [`ADDR_WIDTH-1:0] bus_address;
    tri [`DATA_WIDTH-1:0] bus_data;
    tri [1:0]             bus_control;

    // Interconnect between biu_test_master and biu_master
    wire [`ADDR_WIDTH-1:0] biu_master_address;
    wire [`DATA_WIDTH-1:0] biu_master_data_out;
    wire                   biu_master_rnw;
    wire                   biu_master_en;
    wire [`DATA_WIDTH-1:0] biu_master_data_in;
    wire                   biu_master_data_valid;
    wire                   biu_master_busy;

    // wire clk;

    // clk_div #(
    //     .CLK_FREQ(50),
    //     .LOG2_DIVISOR(1)
    // ) clk_div_inst (
    //     .clk(CLOCK_50),
    //     .n_rst(SW[17]),
    //     .o_div_clk(clk)
    // );

    biu_test_master #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH)
    ) biu_test_master_inst (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .sw_input(SW[15:0]),
        .o_address(biu_master_address),
        .o_data_out(biu_master_data_out),
        .o_rnw(biu_master_rnw),
        .o_en(biu_master_en),
        .i_data_in(biu_master_data_in),
        .i_data_valid(biu_master_data_valid),
        .i_busy(biu_master_busy)
    );

    biu_master #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH)
    ) biu_master0 (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .bus_address(bus_address),
        .bus_data(bus_data),
        .bus_control(bus_control),
        .i_address(biu_master_address),
        .i_data_out(biu_master_data_out),
        .i_rnw(biu_master_rnw),
        .i_en(biu_master_en),
        .o_data_in(biu_master_data_in),
        .o_data_valid(biu_master_data_valid),
        .o_busy(biu_master_busy)
    );

    seg7_controller #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH),
        .BASE_ADDR(`SLAVE_ADDR),
        .NUM_7SEGMENTS(8)
    ) seg7_controller_inst (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .bus_address(bus_address),
        .bus_data(bus_data),
        .bus_control(bus_control),
        .o_hex('{HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7})
    );

endmodule
