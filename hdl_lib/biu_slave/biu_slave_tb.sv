module biu_slave_tb;

    wire clk;
    wire n_rst;

    bus_if #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) bus ();

    biu_slave_if #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) biu ();

    biu_slave #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .BASE_ADDR(32'h80000000),
        .ADDR_SPAN(4),
        .ALIGNED(1)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .bus(bus),
        .biu(biu)
    );

endmodule
