// Bus Interface Unit - Master 
// FIXME: Need to add some sort of timeout & bus error interrupt while in WAIT_RSP state
// otherwise the FSM will be stuck if the request address is invalid!

module biu_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input  wire                  clk,
    input  wire                  n_rst,

    // Bus interface
    inout  wire [ADDR_WIDTH-1:0] bus_address,
    inout  wire [DATA_WIDTH-1:0] bus_data,
    inout  wire [1:0]            bus_control,

    // Master interface
    input  wire [ADDR_WIDTH-1:0] i_address,
    input  wire [DATA_WIDTH-1:0] i_data_out,
    input  wire                  i_rnw,
    input  wire                  i_en,
    output wire [DATA_WIDTH-1:0] o_data_in,
    output wire                  o_data_valid,
    output wire                  o_busy
);

    // FSM state encodings
    localparam STATE_BITS = 4;
    localparam IDLE       = 4'b0001;
    localparam SEND_REQ   = 4'b0010;
    localparam WAIT_RSP   = 4'b0100;
    localparam WAIT_REQ   = 4'b1000;

    // Internal registers for Master interface inputs
    reg [ADDR_WIDTH-1:0] address_q;
    reg [DATA_WIDTH-1:0] data_q;
    reg rnw_q;

    // state register
    reg [STATE_BITS-1:0] state;

    // Bus control signals
    wire bus_rnw;
    wire bus_data_valid;

    // Fan out the bus control signals
    assign bus_rnw        = bus_control[1];
    assign bus_data_valid = bus_control[0];

    // Assign the Master interface outputs
    assign o_data_in      = (o_data_valid) ? bus_data : 'b0;
    assign o_data_valid   = (state == WAIT_RSP && bus_data_valid);
    assign o_busy         = (state != IDLE);

    // Bus driving combinational logic, depends on current state
    // This will only work assuming only one master on the bus. The single biu_master
    // will drive the bus signals LOW when in IDLE (so the slave modules have valid signals that drive the combinational chip select logic)
    // To make this more flexible (and allow multiple masters) a bus arbitration unit
    // shall assume the role of driving the bus signals LOW when IDLE and assert grant signals
    // to the masters. I suspect an additional state (WAIT_GNT) is needed to enable this.
    assign {bus_address, bus_data, bus_control} = (state == IDLE)     ? 'b0 :
                                                  (state == SEND_REQ) ? {address_q, data_q, rnw_q, 1'b1} :
                                                  (state == WAIT_RSP) ? 'bz : 
                                                  (state == WAIT_REQ) ? 'bz : 'bz;

    // FSM logic
    // Start off in IDLE, when Master signals i_en, go to SEND_REQ state and drive the bus with the provided address, data & control signals
    // from Master interface (these are registered)
    // If rnw_q == 1 then no need to wait for response but go to WAIT_REQ state for one cycle before going to IDLE
    // This is to prevent the Slave and Master driving the bus at the same time
    // If rnw_q == 0 then go to WAIT_RSP state
    // Go back to idle once bus_data_valid is asserted. FIXME: Need timeout in this state in case address is invalid!
    always_ff @(posedge clk, negedge n_rst) begin : BIU_MASTER_FSM 
        if (~n_rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE:     state <= (i_en) ? SEND_REQ : IDLE;
                SEND_REQ: state <= (rnw_q) ? WAIT_RSP : WAIT_REQ;
                WAIT_RSP: state <= (bus_data_valid) ? IDLE : WAIT_RSP;
                WAIT_REQ: state <= IDLE;
            endcase
        end
    end

    // Clock in the master interface signals
    always_ff @(posedge clk, negedge n_rst) begin : BIU_MASTER_INTERFACE_Q
        if (~n_rst) begin
            address_q <= 'b0;
            data_q    <= 'b0;
            rnw_q     <= 'b0;
        end else if (i_en && state == IDLE) begin
            address_q <= i_address;
            data_q    <= i_data_out;
            rnw_q     <= i_rnw; 
        end
    end

endmodule 
