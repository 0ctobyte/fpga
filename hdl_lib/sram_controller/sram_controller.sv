// SRAM controller
// Interfaces with the IS61WV102416BLL SRAM chip

module sram_controller #(
    parameter DATA_WIDTH       = 32,
    parameter ADDR_WIDTH       = 32,
    parameter BASE_ADDR        = 32'h80000000,

    localparam SRAM_ADDR_WIDTH = 20,
    localparam SRAM_DATA_WIDTH = 16
) (
    input  logic clk,
    input  logic n_rst,

    bus_if       bus,

    // SRAM interface
    output logic [SRAM_ADDR_WIDTH-1:0] o_sram_addr,
    inout   wire [SRAM_DATA_WIDTH-1:0] io_sram_dq,
    output logic                       o_sram_ce_n,
    output logic                       o_sram_we_n,
    output logic                       o_sram_oe_n,
    output logic                       o_sram_lb_n,
    output logic                       o_sram_ub_n
);

    localparam DATA_HALF_WIDTH      = DATA_WIDTH/2;
    localparam SRAM_DATA_HALF_WIDTH = SRAM_DATA_WIDTH/2;
    localparam SRAM_ADDR_SPAN       = 2097152; // 2M bytes, or 1M 2-byte words

    // Need two cycles to transfer lower and upper 16-bits to/from SRAM
    // For write requests:
    // While in the SRAMLW state, if the controller sees the biu.en asserted then the low word address/data
    // is written to the SRAM. The high word address/data will be registered internally and sent on the next cycle
    // when the controller will be in the SRAMUW state
    // For read requests:
    // The controller will wait for biu.en while in the SRAMLW state and then send the low word address to the SRAM
    // The response from the SRAM will be registered internally. On the next cycle, the controller will transition to
    // the SRAMUW state at which point the high word address will be sent to the SRAM. The SRAM's response and the
    // low word registered in the previous cycle will be combined to form the 32-bit data out to the BIU 
    typedef enum logic [1:0] {
        SRAMLW = 2'b01,
        SRAMUW = 2'b10
    } state_t;
    state_t state;

    logic [SRAM_ADDR_WIDTH-1:0] addr_q;
    logic [SRAM_DATA_WIDTH-1:0] data_in_q;
    logic [SRAM_DATA_WIDTH-1:0] data_out_q;
    logic                       rnw_q;

    logic [SRAM_ADDR_WIDTH-1:0] sram_addr;
    
    // BIU interface
    biu_slave_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) biu ();

    // SRAM addresses are 20 bits wide for 1M 16-bit addressable words
    assign sram_addr = biu.address[SRAM_ADDR_WIDTH:1];

    assign biu.data_valid = (state == SRAMUW);
    assign biu.data_out   = {io_sram_dq, data_out_q};

    // Always assert these wires
    // The SRAM can be put in standby mode if o_sram_ce_n is pulled high
    assign o_sram_ce_n = 'b0;
    assign o_sram_oe_n = 'b0;
    assign o_sram_lb_n = 'b0;
    assign o_sram_ub_n = 'b0;

    // Send data out for writes
    assign io_sram_dq = (state == SRAMLW && biu.en) ? (biu.rnw ? 'bz : biu.data_in[DATA_HALF_WIDTH-1:0]) :
                        (state == SRAMUW) ? (rnw_q ? 'bz : data_in_q) : 'bz;

    // Assign SRAM WE high for reads, low for writes
    always_comb begin
        case (state)
            SRAMLW:  o_sram_we_n = (~biu.en || biu.rnw);
            SRAMUW:  o_sram_we_n = rnw_q;
            default: o_sram_we_n = 'b1;
        endcase
    end

    // Assign output address
    always_comb begin
        case (state)
            SRAMLW:  o_sram_addr = sram_addr;
            SRAMUW:  o_sram_addr = addr_q;
            default: o_sram_addr = 'b0;
        endcase
    end

    // Read data
    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            data_out_q <= 'b0;
        end else if (biu.en && biu.rnw && state == SRAMLW) begin
            data_out_q <= io_sram_dq;
        end
    end

    // Capture the high 16-bit word to send on the next cycle
    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            addr_q    <= 'b0;
            data_in_q <= 'b0;
            rnw_q     <= 'b0;
        end else if (biu.en && state == SRAMLW) begin
            addr_q    <= sram_addr + 1'b1;
            data_in_q <= biu.data_in[DATA_WIDTH-1:DATA_HALF_WIDTH];
            rnw_q     <= biu.rnw;
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            state <= SRAMLW;
        end else begin
            case (state)
                SRAMLW: state <= (biu.en) ? SRAMUW : SRAMLW;
                SRAMUW: state <= SRAMLW;
            endcase
        end
    end

    biu_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BASE_ADDR(BASE_ADDR),
        .ADDR_SPAN(SRAM_ADDR_SPAN),
        .ALIGNED(1)
    ) biu_slave_inst (
        .clk(clk),
        .n_rst(n_rst),
        .bus(bus),
        .biu(biu)
    );

endmodule
