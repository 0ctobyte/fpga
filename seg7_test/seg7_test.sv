module seg7_test (
    input  wire         CLOCK_50,

    input  wire [17:0]  SW,
    output wire [6:0]   HEX0
);

    wire [3:0] syncd_sw;

    synchronizer #(
        .DATA_WIDTH(4),
        .SYNC_DEPTH(2)
    ) synchronize_switches (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .i_async_data(SW[3:0]),
        .o_sync_data(syncd_sw)
    );
 
    seg7_decoder hex0 (
        .n_rst(SW[17]), 
        .i_hex(syncd_sw),
        .o_hex(HEX0)
    );
 
endmodule

