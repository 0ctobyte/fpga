// Bus Interface Unit - Master 
// FIXME: Need to add some sort of timeout & bus error interrupt while in WAIT_RSP state
// otherwise the FSM will be stuck if the request address is invalid!

module biu_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input  wire       clk,
    input  wire       n_rst,

    // Bus interface
    bus_if            bus,

    // Master interface
    biu_master_if.biu biu
);

    // FSM state encodings
    typedef enum reg [3:0] {
        IDLE     = 4'b0001,
        SEND_REQ = 4'b0010,
        WAIT_RSP = 4'b0100,
        WAIT_REQ = 4'b1000
    } state_t;
    state_t state;

    // Internal registers for Master interface inputs
    reg [ADDR_WIDTH-1:0] address_q;
    reg [DATA_WIDTH-1:0] data_q;
    reg rnw_q;

    // Bus control signals
    wire bus_rnw;
    wire bus_data_valid;

    // Fan out the bus control signals
    assign bus_rnw        = bus.control[1];
    assign bus_data_valid = bus.control[0];

    // Assign the Master interface outputs
    assign biu.data_in      = (biu.data_valid) ? bus.data : 'b0;
    assign biu.data_valid   = (state == WAIT_RSP && bus_data_valid);
    assign biu.busy         = (state != IDLE);

    // Bus driving combinational logic, depends on current state
    // This will only work assuming only one master on the bus. The single biu_master
    // will drive the bus signals LOW when in IDLE (so the slave modules have valid signals that drive the combinational chip select logic)
    // To make this more flexible (and allow multiple masters) a bus arbitration unit
    // shall assume the role of driving the bus signals LOW when IDLE and assert grant signals
    // to the masters. I suspect an additional state (WAIT_GNT) is needed to enable this.
    assign {bus.address, bus.data, bus.control} = (state == IDLE)     ? 'bz :
                                                  (state == SEND_REQ) ? {address_q, data_q, rnw_q, 1'b1} :
                                                  (state == WAIT_RSP) ? 'bz :
                                                  (state == WAIT_REQ) ? 'bz : 'bz;

    // FSM logic
    // Start off in IDLE, when Master signals biu.en, go to SEND_REQ state and drive the bus with the provided address, data & control signals
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
                IDLE:     state <= (biu.en) ? SEND_REQ : IDLE;
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
        end else if (biu.en && state == IDLE) begin
            address_q <= biu.address;
            data_q    <= biu.data_out;
            rnw_q     <= biu.rnw; 
        end
    end

endmodule 
