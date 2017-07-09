// Bus Interface Unit - Slave

module biu_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BASE_ADDR  = 32'h0,
    parameter ADDR_SPAN  = 32'h4,
    parameter ALIGNED    = 1'b1
) (
    input  wire                  clk,
    input  wire                  n_rst,

    // Bus interface
    inout  wire [ADDR_WIDTH-1:0] bus_address,
    inout  wire [DATA_WIDTH-1:0] bus_data,
    inout  wire [1:0]            bus_control,

    // Slave interface
    output wire [ADDR_WIDTH-1:0] o_address,
    output wire [DATA_WIDTH-1:0] o_data_in,
    output wire                  o_rnw,
    output wire                  o_en,
    input  wire [DATA_WIDTH-1:0] i_data_out,
    input  wire                  i_data_valid
);

    // FSM state encodings
    localparam STATE_BITS = 3;
    localparam IDLE       = 3'b001;
    localparam RECV_REQ   = 3'b010;
    localparam SEND_RSP   = 3'b100;

    // Internal registers for Slave interface outputs
    reg [ADDR_WIDTH-1:0] address_q;
    reg [DATA_WIDTH-1:0] data_in_q;
    reg [DATA_WIDTH-1:0] data_out_q;
    reg rnw_q;

    // State register
    reg [STATE_BITS-1:0] state;

    // Chip select
    wire cs;

    // Bus control signals
    wire bus_rnw;
    wire bus_data_valid;

    // Fan out the bus control signals
    assign bus_rnw        = bus_control[1];
    assign bus_data_valid = bus_control[0];

    // Assign the Slave interface outputs
    assign o_address = (address_q - BASE_ADDR);
    assign o_data_in = data_in_q;
    assign o_rnw     = rnw_q;
    assign o_en      = (state == RECV_REQ);

    // Bus driving combinational logic
    assign {bus_address, bus_data, bus_control} = (state == IDLE)     ? 'bz :
                                                  (state == RECV_REQ) ? {address_q, data_out_q, rnw_q, 1'b0} :
                                                  (state == SEND_RSP) ? {address_q, data_out_q, rnw_q, 1'b1} : 'bz;

    // Instantiate the chip select/address decoder module
    chip_select #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .BASE_ADDR(BASE_ADDR),
        .ADDR_SPAN(ADDR_SPAN),
        .ALIGNED(ALIGNED)
    ) biu_slave_chip_select (
        .i_address(bus_address),
        .i_data_valid(bus_data_valid),
        .o_cs(cs)
    );
 
    // FSM logic
    // Start off at IDLE, when chip select == 1 clock in the data on the bus and go to RECV_REQ state
    // If it was a write transaction then just go back to IDLE on the next cycle, otherwise wait for Slave to assert i_data_valid
    // If it was a read transaction and i_data_valid is asserted by the slave then go to SEND_RSP state
    always_ff @(posedge clk, negedge n_rst) begin : BIU_SLAVE_FSM 
        if (~n_rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE:     state <= (cs) ? RECV_REQ : IDLE;
                RECV_REQ: state <= (~rnw_q) ? IDLE : (i_data_valid) ? SEND_RSP : RECV_REQ;
                SEND_RSP: state <= IDLE;
            endcase
        end
    end

    // Clock in the bus interface signals
    always_ff @(posedge clk, negedge n_rst) begin : BIU_INTERFACE_Q
        if (~n_rst) begin
            address_q <= 'b0;
            data_in_q <= 'b0;
            rnw_q     <= 'b0;
        end else if (cs && state == IDLE) begin
            address_q <= bus_address;
            data_in_q <= bus_data;
            rnw_q     <= bus_rnw; 
        end
    end

    // Clock in the Slave interface signals
    always_ff @(posedge clk, negedge n_rst) begin : BIU_SLAVE_INTERFACE_Q
        if (~n_rst) begin
            data_out_q <= 'b0;
        end else if (i_data_valid && state == RECV_REQ) begin
            data_out_q <= i_data_out;
        end
    end

endmodule
