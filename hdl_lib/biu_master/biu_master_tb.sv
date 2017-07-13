module biu_master_tb;

    logic clk;
    logic n_rst;

    bus_if #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) bus ();

    biu_master_if #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) biu ();

    biu_master #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .bus(bus),
        .biu(biu)
    );

endmodule
