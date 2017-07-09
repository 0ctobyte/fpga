// UART RX module

module uart_rx #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 115200,
    parameter DATA_BITS = 8,
    parameter STOP_BITS = 1,
    parameter PARITY    = 0
) (
    input  wire                 clk,
    input  wire                 n_rst,

    input  wire                 i_rx,

    output wire                 o_data_valid,
    output wire [DATA_BITS-1:0] o_data
);

    localparam SAMPLES_PER_BIT = int'(CLK_FREQ/BAUD_RATE + 0.5);
    localparam IDLE = 5'b00001, START = 5'b00010, RECV = 5'b00100, VALID = 5'b01000, STOP = 5'b10000;

    reg [4:0] state;

    // 50 MHz sample counter. If this reaches SAMPLES_PER_BIT/2 then we are near the middle of the bit
    reg [$clog2(SAMPLES_PER_BIT)-1:0] sample_counter; 

    // Bit counter
    reg [3:0] bits;

    // Data shift register
    reg [DATA_BITS-1:0] data_recv;

    // Pass i_rx through a 2ff synchronizer to limit metastability issues
    wire rx_syncd;

    // Assert when mid point of bit is detected
    // Assert when end point of bit is detected
    wire bit_mid_detect;
    wire bit_end_detect;

    assign bit_mid_detect = (sample_counter == (SAMPLES_PER_BIT/2));
    assign bit_end_detect = (sample_counter == SAMPLES_PER_BIT);

    // Assign outputs, data is only valid when in VALID state
    assign o_data_valid = (state == VALID);
    assign o_data       = data_recv;

    synchronizer #(
        .DATA_WIDTH(1), 
        .SYNC_DEPTH(2),
        .RESET_VAL(1)
    ) i_rx_synchronizer (
        .clk(clk), 
        .n_rst(n_rst),
        .i_async_data(i_rx),
        .o_sync_data(rx_syncd)
    );

    // RX state machine
    always_ff @(posedge clk, negedge n_rst) begin : UART_RX_FSM
        if (~n_rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE:  state <= ~rx_syncd ? START : IDLE;
                START: state <= bit_mid_detect ? RECV : START;
                RECV:  state <= (bits == DATA_BITS) ? VALID : RECV;
                VALID: state <= STOP; // Wait one cycle to assert o_data_valid
                STOP:  state <= rx_syncd ? IDLE: STOP; // Do we really need to wait for all the stop bits? just wait until the rx signal is high again
            endcase
        end
    end

    // Count 50 MHz samples when receiving bits to detect mid point of bit 
    always_ff @(posedge clk, negedge n_rst) begin : SAMPLE_COUNTER_Q
        if (~n_rst) begin
            sample_counter <= 'b0;
        end else if (((state == START) || (state == RECV)) && ~bit_end_detect) begin
            sample_counter <= sample_counter + 1'b1 ;
        end else begin
            sample_counter <= 'b0;
        end
    end

    // Received bit counter
    always_ff @(posedge clk, negedge n_rst) begin : BITS_BAUD_Q
        if (~n_rst) begin
            bits <= 'b0;
        end else if (state == RECV) begin
            bits <= (bit_mid_detect) ? bits + 1'b1 : bits;
        end else begin
            bits <= 'b0;
        end
    end

    // Data shift in register
    always_ff @(posedge clk, negedge n_rst) begin : DATA_RECV_SHIFT_Q
        if (~n_rst) begin
            data_recv <= 'b0;
        end else if (state == RECV && bit_mid_detect) begin
            data_recv <= {rx_syncd, data_recv[DATA_BITS-1:1]}; 
        end
    end
    
endmodule
