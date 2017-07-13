module sync_fifo_tb;

    logic clk;
    logic n_rst;

    fifo_if #(
        .DATA_WIDTH(8)
    ) if_fifo ();

    sync_fifo #(
        .DATA_WIDTH(8),
        .FIFO_DEPTH(8)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .if_fifo(if_fifo)
    );

endmodule
