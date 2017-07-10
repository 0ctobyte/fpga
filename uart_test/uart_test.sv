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
    input  wire                  clk,
    input  wire                  n_rst,

    // Bus interface
    inout  wire [ADDR_WIDTH-1:0] bus_address,
    inout  wire [DATA_WIDTH-1:0] bus_data,
    inout  wire [1:0]            bus_control
);

    localparam IDLE = 6'b000001, RXFE = 6'b000010, RXRD = 6'b000100, S7WR = 6'b001000, TXFF = 6'b010000, TXWR = 6'b100000;

    reg [5:0] state;
    reg [`DATA_BITS-1:0] rx_data;
    reg rxfe, txff;

    // Interconnect between biu_test_master and biu_master
    logic [ADDR_WIDTH-1:0] biu_master_address;
    logic [DATA_WIDTH-1:0] biu_master_data_out;
    logic                  biu_master_rnw;
    logic                  biu_master_en;
    wire  [DATA_WIDTH-1:0] biu_master_data_in;
    wire                   biu_master_data_valid;
    wire                   biu_master_busy;

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            rx_data <= 'b0;
        end else if (state == RXRD && biu_master_data_valid) begin
            rx_data <= biu_master_data_in[`DATA_BITS-1:0];
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            rxfe <= 'b1;
        end else if (state == RXFE && biu_master_data_valid) begin
            rxfe <= biu_master_data_in[0];
        end else begin
            rxfe <= 'b1;
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            txff <= 'b1;
        end else if (state == TXFF && biu_master_data_valid) begin
            txff <= biu_master_data_in[1];
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
                RXRD: state <= (biu_master_data_valid) ? S7WR : RXRD;
                S7WR: state <= TXFF;
                TXFF: state <= (~txff) ? TXWR : TXFF;
                TXWR: state <= IDLE;
            endcase
        end 
    end

    always_comb begin
        case (state)
            IDLE: begin
                biu_master_address  <= 'b0;
                biu_master_data_out <= 'b0;
                biu_master_rnw      <= 'b0;
                biu_master_en       <= 'b0;
            end
            RXFE: begin
                biu_master_address  <= `UART_SLAVE_ADDR + 8;
                biu_master_data_out <= 'b0;
                biu_master_rnw      <= 'b1;
                biu_master_en       <= rxfe && ~biu_master_busy;
            end
            RXRD: begin
                biu_master_address  <= `UART_SLAVE_ADDR;
                biu_master_data_out <= 'b0;
                biu_master_rnw      <= 'b1;
                biu_master_en       <= ~biu_master_busy;
            end
            S7WR: begin
                biu_master_address  <= `SEG7_SLAVE_ADDR;
                biu_master_data_out <= rx_data;
                biu_master_rnw      <= 'b0;
                biu_master_en       <= ~biu_master_busy;
            end
            TXFF: begin
                biu_master_address  <= `UART_SLAVE_ADDR + 8;
                biu_master_data_out <= 'b0;
                biu_master_rnw      <= 'b1;
                biu_master_en       <= txff && ~biu_master_busy;
            end
            TXWR: begin
                biu_master_address  <= `UART_SLAVE_ADDR;
                biu_master_data_out <= rx_data;
                biu_master_rnw      <= 'b0;
                biu_master_en       <= ~biu_master_busy;
            end
        endcase
    end

    biu_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) biu_master0 (
        .clk(clk),
        .n_rst(n_rst),
        .bus_address(bus_address),
        .bus_data(bus_data),
        .bus_control(bus_control),
        .i_address(biu_master_address),
        .i_data_out(biu_master_data_out),
        .i_rnw(biu_master_rnw),
        .i_en(biu_master_en),
        .o_data_in(biu_master_data_in),
        .o_data_valid(biu_master_data_valid),
        .o_busy(biu_master_busy)
    );

endmodule

module uart_test (
    input  wire                    CLOCK_50,
    input  wire [17:17]            SW,

    input  wire                    UART_RXD,
    output wire                    UART_TXD,
    output wire [6:0]              HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7
);

    // Shared bus
    tri [`ADDR_WIDTH-1:0] bus_address;
    tri [`DATA_WIDTH-1:0] bus_data;
    tri [1:0]             bus_control;

    uart_test_master #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH)
    ) uart_test_master_inst (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .bus_address(bus_address),
        .bus_data(bus_data),
        .bus_control(bus_control)
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
        .bus_address(bus_address),
        .bus_data(bus_data),
        .bus_control(bus_control),
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
        .bus_address(bus_address),
        .bus_data(bus_data),
        .bus_control(bus_control),
        .o_hex({HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7})
    );

endmodule
