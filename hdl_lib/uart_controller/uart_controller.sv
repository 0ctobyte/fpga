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
    input  logic clk,
    input  logic n_rst,

    // Bus interface
    bus_if       bus,

    // UART interface
    input  logic i_rx,
    output logic o_tx
);

    // BIU interface
    biu_slave_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) biu ();

    // RX FIFO interface
    fifo_if #(
        .DATA_WIDTH(DATA_BITS)
    ) if_rx_fifo ();

    // TX FIFO interface
    fifo_if #(
        .DATA_WIDTH(DATA_BITS)
    ) if_tx_fifo ();

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
    logic uart_rsr;

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
    logic [4:0] uart_fsr;

    // UART RX interface
    logic [DATA_BITS-1:0]  uart_rx_data;
    logic                  uart_rx_data_valid;

    // Receiver errors
    logic                  overrun_error;

    // UART TX interface
    logic [DATA_BITS-1:0]  uart_tx_data;
    logic                  uart_tx_data_valid;
    logic                  uart_tx_busy;

    // Overrun errors occurs when the receiver has received a character but the RX FIFO is full
    // Also keep the overrun error signal asserted as long as the UART_RSR register has not been cleared
    assign overrun_error = (if_rx_fifo.full && uart_rx_data_valid) | uart_rsr;

    // On read requests, pop data out of the RX FIFO 
    assign if_rx_fifo.rd_en =  biu.en && biu.rnw && (biu.address == UART_DR_ADDR);

    // Push data from the UART receiver on to the RX FIFO
    assign if_rx_fifo.wr_en   = uart_rx_data_valid;
    assign if_rx_fifo.data_in = uart_rx_data;

    // On write requests, push data on to the TX FIFO
    assign if_tx_fifo.wr_en   = biu.en && ~biu.rnw && (biu.address == UART_DR_ADDR);
    assign if_tx_fifo.data_in = biu.data_in[DATA_BITS-1:0];

    // Pop data out of the TX FIFO to the UART transmitter if the transmitter is not busy
    assign if_tx_fifo.rd_en = ~uart_tx_busy;

    // Only assert data valid to the UART transmitter if the TX FIFO is not empty
    assign uart_tx_data_valid = ~if_tx_fifo.empty;
    assign uart_tx_data       = if_tx_fifo.data_out;

    // Determine the BIU Slave inputs
    assign biu.data_valid = biu.en && biu.rnw;
    always_comb begin
        case (biu.address)
            UART_DR_ADDR:  biu.data_out = {{(DATA_WIDTH-$bits(if_rx_fifo.data_out)){1'b0}}, if_rx_fifo.data_out};
            UART_RSR_ADDR: biu.data_out = {{(DATA_WIDTH-$bits(uart_rsr)){1'b0}}, uart_rsr};
            UART_FSR_ADDR: biu.data_out = {{(DATA_WIDTH-$bits(uart_fsr)){1'b0}}, uart_fsr};
            default:       biu.data_out = 'b0;
        endcase
    end

    // Update UART_RSR register
    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            uart_rsr <= 'b0;
        end else if (biu.en && ~biu.rnw && (biu.address == UART_RSR_ADDR)) begin
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
            uart_fsr <= {uart_tx_busy, if_tx_fifo.empty, if_rx_fifo.full, if_tx_fifo.full, if_rx_fifo.empty}; 
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
        .bus(bus),
        .biu(biu)
    );

    sync_fifo #(
        .DATA_WIDTH(DATA_BITS),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) rx_sync_fifo (
        .clk(clk),
        .n_rst(n_rst),
        .if_fifo(if_rx_fifo)
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
        .if_fifo(if_tx_fifo)
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
