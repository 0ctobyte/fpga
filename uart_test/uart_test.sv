`define ADDR_WIDTH 32
`define DATA_WIDTH 32
`define FIFO_DEPTH 8
`define UART_SLAVE_ADDR 32'hc0000000
`define SEG7_SLAVE_ADDR 32'hc0001000

`define CLK_FREQ  50000000
`define BAUD_RATE 115200
`define DATA_BITS 8
`define STOP_BITS 1
`define PARITY    0

module uart_test_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input  wire clk,
    input  wire n_rst,

    // Bus interface
    bus_if      bus
);

    // BIU master interface
    biu_master_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) biu ();
    
    typedef enum logic [5:0] {
        IDLE = 6'b000001,
        RXFE = 6'b000010,
        RXRD = 6'b000100,
        S7WR = 6'b001000,
        TXFF = 6'b010000,
        TXWR = 6'b100000
    } state_t;
    state_t state;

    reg [`DATA_BITS-1:0] rx_data;
    reg rxfe, txff;

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            rx_data <= 'b0;
        end else if (state == RXRD && biu.data_valid) begin
            rx_data <= biu.data_in[`DATA_BITS-1:0];
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            rxfe <= 'b1;
        end else if (state == RXFE && biu.data_valid) begin
            rxfe <= biu.data_in[0];
        end else begin
            rxfe <= 'b1;
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            txff <= 'b1;
        end else if (state == TXFF && biu.data_valid) begin
            txff <= biu.data_in[1];
        end else begin
            txff <= 'b1;
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: state <= RXFE;
                RXFE: state <= (~rxfe) ? RXRD : RXFE;
                RXRD: state <= (biu.data_valid) ? S7WR : RXRD;
                S7WR: state <= TXFF;
                TXFF: state <= (~txff) ? TXWR : TXFF;
                TXWR: state <= IDLE;
            endcase
        end 
    end

    always_comb begin
        case (state)
            IDLE: begin
                biu.address  <= 'b0;
                biu.data_out <= 'b0;
                biu.rnw      <= 'b0;
                biu.en       <= 'b0;
            end
            RXFE: begin
                biu.address  <= `UART_SLAVE_ADDR + 8;
                biu.data_out <= 'b0;
                biu.rnw      <= 'b1;
                biu.en       <= rxfe && ~biu.busy;
            end
            RXRD: begin
                biu.address  <= `UART_SLAVE_ADDR;
                biu.data_out <= 'b0;
                biu.rnw      <= 'b1;
                biu.en       <= ~biu.busy;
            end
            S7WR: begin
                biu.address  <= `SEG7_SLAVE_ADDR;
                biu.data_out <= rx_data;
                biu.rnw      <= 'b0;
                biu.en       <= ~biu.busy;
            end
            TXFF: begin
                biu.address  <= `UART_SLAVE_ADDR + 8;
                biu.data_out <= 'b0;
                biu.rnw      <= 'b1;
                biu.en       <= txff && ~biu.busy;
            end
            TXWR: begin
                biu.address  <= `UART_SLAVE_ADDR;
                biu.data_out <= rx_data;
                biu.rnw      <= 'b0;
                biu.en       <= ~biu.busy;
            end
        endcase
    end

    biu_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) biu_master0 (
        .clk(clk),
        .n_rst(n_rst),
        .bus(bus),
        .biu(biu)
    );

endmodule

module uart_test (
    input  wire                    CLOCK_50,
    input  wire [17:17]            SW,

    input  wire                    UART_RXD,
    output wire                    UART_TXD,
    output wire [6:0]              HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7
);

    // Bus interface
    bus_if #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH)
    ) bus ();

    uart_test_master #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH)
    ) uart_test_master_inst (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .bus(bus)
    );

    uart_controller #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH),
        .BASE_ADDR(`UART_SLAVE_ADDR),
        .FIFO_DEPTH(`FIFO_DEPTH),
        .CLK_FREQ(`CLK_FREQ),
        .BAUD_RATE(`BAUD_RATE),
        .DATA_BITS(`DATA_BITS),
        .STOP_BITS(`STOP_BITS),
        .PARITY(`PARITY)
    ) uart_controller_inst (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .bus(bus),
        .i_rx(UART_RXD),
        .o_tx(UART_TXD)
    );

    seg7_controller #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH),
        .BASE_ADDR(`SEG7_SLAVE_ADDR),
        .NUM_7SEGMENTS(8)
    ) seg7_controller_inst (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .bus(bus),
        .o_hex('{HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7})
    );

endmodule
