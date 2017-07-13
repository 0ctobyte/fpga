`define ADDR_WIDTH 32
`define DATA_WIDTH 32
`define SLAVE_ADDR 32'hc0000000
`define ADDR_SPAN  32'h4
`define ALIGNED    1'b1 

module biu_test_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) ( 
    input  logic        clk,
    input  logic        n_rst,

    // Switch input
    input  logic [15:0] sw_input,

    // Bus interface
    bus_if              bus 
);

    // BIU master interface
    biu_master_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) biu ();

    logic [15:0] syncd_sw;
    logic [15:0] syncd_sw_q [0:2];

    assign biu.address  = `SLAVE_ADDR;
    assign biu.data_out = {syncd_sw, syncd_sw};
    assign biu.rnw      = 1'b0;
    assign biu.en       = (syncd_sw_q[2] != syncd_sw && syncd_sw_q[2] != syncd_sw_q[0] && syncd_sw_q[2] != syncd_sw_q[1] && ~biu.busy);

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

    biu_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) biu_master_inst (
        .clk(clk),
        .n_rst(n_rst),
        .bus(bus),
        .biu(biu)
    );
    
    synchronizer #(
        .DATA_WIDTH(16),
        .SYNC_DEPTH(2)
    ) switch_synchronizer (
        .clk(clk),
        .n_rst(n_rst),
        .i_async_data(sw_input),
        .o_sync_data(syncd_sw)
    );

endmodule

module biu_test (
    input  logic         CLOCK_50,

    input  logic [17:0]  SW,
    output logic [6:0]   HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7
);

    // Bus interface
    bus_if #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH)
    ) bus ();

    biu_test_master #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH)
    ) biu_test_master_inst (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .sw_input(SW[15:0]),
        .bus(bus)
    );

    seg7_controller #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH),
        .BASE_ADDR(`SLAVE_ADDR),
        .NUM_7SEGMENTS(8)
    ) seg7_controller_inst (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .bus(bus),
        .o_hex('{HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7})
    );

endmodule
