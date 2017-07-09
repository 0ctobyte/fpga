`define CLK_FREQ  50000000
`define BAUD_RATE 115200
`define DATA_BITS 8
`define STOP_BITS 1
`define PARITY    0

module uart_test (
    input  wire                    CLOCK_50,
    input  wire [17:17]            SW,

    input  wire                    UART_RXD,
    output wire                    UART_TXD,
    output wire [6:0]              HEX0,
    output wire [6:0]              HEX1
);

    reg [`DATA_BITS-1:0]  recv_data;

    wire [`DATA_BITS-1:0] uart_rx_data;
    wire                  uart_rx_data_valid;

    wire [`DATA_BITS-1:0] uart_tx_data;
    wire                  uart_tx_data_valid;
    wire                  uart_tx_busy;

    assign uart_tx_data_valid = uart_rx_data_valid;
    assign uart_tx_data       = uart_rx_data;

    always_ff @(posedge CLOCK_50, negedge SW[17]) begin
        if (~SW[17]) begin
            recv_data <= 'b0;
        end else if (uart_rx_data_valid) begin
            recv_data <= uart_rx_data;
        end
    end

    uart_rx #(
        .CLK_FREQ(`CLK_FREQ),
        .BAUD_RATE(`BAUD_RATE),
        .DATA_BITS(`DATA_BITS),
        .STOP_BITS(`STOP_BITS),
        .PARITY(`PARITY)
    ) uart_rx_inst (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .i_rx(UART_RXD),
        .o_data_valid(uart_rx_data_valid),
        .o_data(uart_rx_data)
    );

    uart_tx #(
        .CLK_FREQ(`CLK_FREQ),
        .BAUD_RATE(`BAUD_RATE),
        .DATA_BITS(`DATA_BITS),
        .STOP_BITS(`STOP_BITS),
        .PARITY(`PARITY)
    ) uart_tx_inst (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .i_data_valid(uart_tx_data_valid),
        .i_data(uart_tx_data),
        .o_busy(uart_tx_busy),
        .o_tx(UART_TXD)
    );

    seg7_decoder hex0 (
        .n_rst(SW[17]),
        .i_hex(recv_data[3:0]),
        .o_hex(HEX0)
    );

    seg7_decoder hex1 (
        .n_rst(SW[17]),
        .i_hex(recv_data[7:4]),
        .o_hex(HEX1)
    );

endmodule
