// UART TX module

module uart_tx #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 115200,
    parameter DATA_BITS = 8,
    parameter STOP_BITS = 1,
    parameter PARITY    = 0
) (
    input  wire                 clk,
    input  wire                 n_rst,

    input  wire                 i_data_valid,
    input  wire [DATA_BITS-1:0] i_data,

    output wire                 o_busy,
    output logic                o_tx
);

    localparam SAMPLES_PER_BIT = int'(CLK_FREQ/BAUD_RATE + 0.5);
    localparam IDLE = 4'b0001, START = 4'b0010, SEND = 4'b0100, STOP = 4'b1000;

    reg [3:0] state;

    reg [$clog2(SAMPLES_PER_BIT)-1:0] sample_counter;
    reg [3:0] bits;

    reg [DATA_BITS-1:0] data_shift_out;

    wire bit_start_detect;
    wire bit_end_detect;
    wire busy;

    // Assert busy signal if sending data
    assign busy = (state != IDLE);
    assign o_busy = busy;

    // Assert when start and end point of bit is detected
    assign bit_start_detect = (sample_counter == 'b0);
    assign bit_end_detect = (sample_counter == SAMPLES_PER_BIT);

    // Send over TX
    always_comb begin
        case (state)
            IDLE:  o_tx <= 1'b1;
            START: o_tx <= 1'b0;
            SEND:  o_tx <= data_shift_out[0];
            STOP:  o_tx <= 1'b1;
        endcase
    end 

    // UART TX state machine
    always_ff @(posedge clk, negedge n_rst) begin : UART_TX_FSM
        if (~n_rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE:  state <= (i_data_valid) ? START : IDLE;
                START: state <= (bit_end_detect) ? SEND : START;
                SEND:  state <= (bits == (DATA_BITS + 1)) ? STOP : SEND; 
                STOP:  state <= (bits == (DATA_BITS + STOP_BITS + 1)) ? IDLE : STOP;
            endcase
        end
    end

    // Count 50 MHz samples
    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            sample_counter <= 'b0;
        end else if ((state != IDLE) && ~bit_end_detect) begin
            sample_counter <= sample_counter + 1'b1;
        end else begin
            sample_counter <= 'b0;
        end
    end

    // Sent bit counter
    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            bits <= 'b0;
        end else if ((state == SEND) || (state == STOP)) begin
            bits <= (bit_start_detect) ? bits + 1'b1 : bits;
        end else begin
            bits <= 'b0;
        end
    end

    // Clock in the data shift out register
    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            data_shift_out <= 'b0;
        end else if (state == IDLE && i_data_valid) begin
            data_shift_out <= i_data;
        end else if (state == SEND && bit_end_detect) begin
            data_shift_out <= {1'b1, data_shift_out[DATA_BITS-1:1]}; 
        end
    end

endmodule
