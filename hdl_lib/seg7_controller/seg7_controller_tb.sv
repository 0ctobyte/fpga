module seg7_controller_tb;

    logic clk;
    logic n_rst;

    logic [6:0] hex [0:7];

    bus_if #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) bus ();

    seg7_controller #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .BASE_ADDR(32'hc0001000),
        .NUM_7SEGMENTS(8)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .bus(bus),
        .o_hex(hex)
    );

endmodule
