// UART RX/TX controller

module uart_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BASE_ADDR  = 32'hc0000000,
    parameter FIFO_DEPTH = 8,

    // UART parameters
    parameter CLK_FREQ   = 50000000,
    parameter BAUD_RATE  = 115200,
    parameter DATA_BITS  = 8,
    parameter STOP_BITS  = 1,
    parameter PARITY     = 0
) (
    input  wire                  clk,
    input  wire                  n_rst,

    // Bus interface
    inout  wire [ADDR_WIDTH-1:0] bus_address,
    inout  wire [DATA_WIDTH-1:0] bus_data,
    inout  wire [1:0]            bus_control,  

    // UART interface
    input  wire                  i_rx,
    output wire                  o_tx
);
    localparam UART_DR_ADDR = 'h0, UART_RSR_ADDR = 'h4, UART_FSR_ADDR = 'h8;

    // Three accessible registers: UART_DR, UART_FSR and UART_RSR
    // The UART_DR (slave address 0x0) is the R/W data register. Write to it and the data is added to the TX FIFO. Read from it and data is popped from the RX FIFO
    //    7      6      5      4      3      2      1      0
    // _________________________________________________________
    // |                         DATA                          |
    // ---------------------------------------------------------
    // |                          RW                           |
    // ---------------------------------------------------------

    // The UART_RSR (slave address 0x4) register holds error information on the UART receiver
    //    4      3      2      1      0
    // ____________________________________
    // |                           |  OE  |
    // ------------------------------------
    // |                           |  W1C |
    // ------------------------------------
    // OE  - Overrun Error (receive FIFO is full and new data from the receiver needs to be written into the FIFO)
    // W1C - Software can clear the error bit by writing any value to it
    reg uart_rsr;

    // The UART_FSR (slave address 0x8) register is for checking the status of the FIFOs:
    //    4      3      2      1      0
    // ____________________________________
    // | BUSY | TXFE | RXFF | TXFF | RXFE | 
    // ------------------------------------
    // |  RO  |  RO  |  RO  |  RO  |  RO  |
    // ------------------------------------
    // RXFE - RX FIFO empty
    // TXFF - TX FIFO full
    // RXFF - RX FIFO full
    // TXFE - TX FIFO empty
    // BUSY - Transmitter is busy sending a character. This should be asserted as long as the TX FIFO is not empty
    reg [4:0] uart_fsr;

    // BIU slave interface
    wire  [ADDR_WIDTH-1:0] biu_slave_address;
    wire  [DATA_WIDTH-1:0] biu_slave_data_in;
    wire                   biu_slave_rnw;
    wire                   biu_slave_en;
    logic [DATA_WIDTH-1:0] biu_slave_data_out;
    logic                  biu_slave_data_valid;

    // RX FIFO interface
    wire                   rx_fifo_wr_en;
    wire  [DATA_BITS-1:0]  rx_fifo_data_in;
    wire                   rx_fifo_full;
    wire                   rx_fifo_rd_en;
    wire  [DATA_BITS-1:0]  rx_fifo_data_out;
    wire                   rx_fifo_empty;

    // UART RX interface
    wire  [DATA_BITS-1:0]  uart_rx_data;
    wire                   uart_rx_data_valid;

    // Receiver errors
    wire                   overrun_error;

    // TX FIFO interface
    wire                   tx_fifo_wr_en;
    wire  [DATA_BITS-1:0]  tx_fifo_data_in;
    wire                   tx_fifo_full;
    wire                   tx_fifo_rd_en;
    wire  [DATA_BITS-1:0]  tx_fifo_data_out;
    wire                   tx_fifo_empty;

    // UART TX interface
    wire  [DATA_BITS-1:0]  uart_tx_data;
    wire                   uart_tx_data_valid;
    wire                   uart_tx_busy;

    // Overrun errors occurs when the receiver has received a character but the RX FIFO is full
    // Also keep the overrun error signal asserted as long as the UART_RSR register has not been cleared
    assign overrun_error = (rx_fifo_full && uart_rx_data_valid) | uart_rsr;

    // On read requests, pop data out of the RX FIFO 
    assign rx_fifo_rd_en =  biu_slave_en && biu_slave_rnw && (biu_slave_address == UART_DR_ADDR);

    // Push data from the UART receiver on to the RX FIFO
    assign rx_fifo_wr_en   = uart_rx_data_valid;
    assign rx_fifo_data_in = uart_rx_data;

    // On write requests, push data on to the TX FIFO
    assign tx_fifo_wr_en   = biu_slave_en && ~biu_slave_rnw && (biu_slave_address == UART_DR_ADDR);
    assign tx_fifo_data_in = biu_slave_data_in;

    // Pop data out of the TX FIFO to the UART transmitter if the transmitter is not busy
    assign tx_fifo_rd_en = ~uart_tx_busy;

    // Only assert data valid to the UART transmitter if the TX FIFO is not empty
    assign uart_tx_data_valid = ~tx_fifo_empty;
    assign uart_tx_data       = tx_fifo_data_out;

    // Determine the BIU Slave inputs
    assign biu_slave_data_valid = biu_slave_en && biu_slave_rnw;
    always_comb begin
        case (biu_slave_address)
            UART_DR_ADDR:  biu_slave_data_out = {{(DATA_WIDTH-$bits(rx_fifo_data_out)){1'b0}}, rx_fifo_data_out};
            UART_RSR_ADDR: biu_slave_data_out = {{(DATA_WIDTH-$bits(uart_rsr)){1'b0}}, uart_rsr};
            UART_FSR_ADDR: biu_slave_data_out = {{(DATA_WIDTH-$bits(uart_fsr)){1'b0}}, uart_fsr};
            default:       biu_slave_data_out = 'b0;
        endcase
    end

    // Update UART_RSR register
    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            uart_rsr <= 'b0;
        end else if (biu_slave_en && ~biu_slave_rnw && (biu_slave_address == UART_RSR_ADDR)) begin
            uart_rsr <= 'b0;
        end else begin
            uart_rsr <= overrun_error;
        end
    end

    // Update UART_FSR register
    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            uart_fsr <= 'b0;
        end else begin
            uart_fsr <= {uart_tx_busy, tx_fifo_empty, rx_fifo_full, tx_fifo_full, rx_fifo_empty}; 
        end
    end

    biu_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BASE_ADDR(BASE_ADDR),
        .ADDR_SPAN(12),
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

    sync_fifo #(
        .DATA_WIDTH(DATA_BITS),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) rx_sync_fifo (
        .clk(clk),
        .n_rst(n_rst),
        .i_wr_en(rx_fifo_wr_en),
        .i_data_in(rx_fifo_data_in),
        .o_fifo_full(rx_fifo_full),
        .i_rd_en(rx_fifo_rd_en),
        .o_data_out(rx_fifo_data_out),
        .o_fifo_empty(rx_fifo_empty)
    );

    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_BITS(DATA_BITS),
        .STOP_BITS(STOP_BITS),
        .PARITY(PARITY)
    ) uart_rx_inst (
        .clk(clk),
        .n_rst(n_rst),
        .i_rx(i_rx),
        .o_data_valid(uart_rx_data_valid),
        .o_data(uart_rx_data)
    );

    sync_fifo #(
        .DATA_WIDTH(DATA_BITS),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) tx_sync_fifo (
        .clk(clk),
        .n_rst(n_rst),
        .i_wr_en(tx_fifo_wr_en),
        .i_data_in(tx_fifo_data_in),
        .o_fifo_full(tx_fifo_full),
        .i_rd_en(tx_fifo_rd_en),
        .o_data_out(tx_fifo_data_out),
        .o_fifo_empty(tx_fifo_empty)
    );

    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_BITS(DATA_BITS),
        .STOP_BITS(STOP_BITS),
        .PARITY(PARITY)
    ) uart_tx_inst (
        .clk(clk),
        .n_rst(n_rst),
        .i_data_valid(uart_tx_data_valid),
        .i_data(uart_tx_data),
        .o_busy(uart_tx_busy),
        .o_tx(o_tx)
    );

endmodule
