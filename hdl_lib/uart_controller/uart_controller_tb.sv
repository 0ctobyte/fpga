module uart_controller_tb;

    wire clk;
    wire n_rst;

    wire i_rx;
    wire o_tx;

    bus_if #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) bus ();

    uart_controller #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .BASE_ADDR(32'hc0000000),
        .FIFO_DEPTH(8),
        .CLK_FREQ(50000000),
        .BAUD_RATE(115200),
        .DATA_BITS(8),
        .STOP_BITS(1),
        .PARITY(0)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .bus(bus),
        .i_rx(i_rx),
        .o_tx(o_tx)
    );

endmodule
