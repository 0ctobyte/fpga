`define DATA_WIDTH 32
`define ADDR_WIDTH 32
`define SRAM_ADDR_WIDTH 20
`define SRAM_DATA_WIDTH 16

module sram_controller_tb;

    logic clk;
    logic n_rst;

    logic [`SRAM_ADDR_WIDTH-1:0] o_sram_addr;
    wire  [`SRAM_DATA_WIDTH-1:0] io_sram_dq;
    logic                        o_sram_ce_n;
    logic                        o_sram_we_n;
    logic                        o_sram_oe_n;
    logic                        o_sram_ub_n;
    logic                        o_sram_lb_n;

    logic [(`SRAM_DATA_WIDTH/2)-1:0] sram_dq_lb;
    logic [(`SRAM_DATA_WIDTH/2)-1:0] sram_dq_ub;
    logic [`SRAM_DATA_WIDTH-1:0] sram [0:1048576];

    assign sram_dq_lb = (~o_sram_lb_n) ? io_sram_dq[(`SRAM_DATA_WIDTH/2)-1:0] : sram[o_sram_addr][(`SRAM_DATA_WIDTH/2)-1:0];
    assign sram_dq_ub = (~o_sram_ub_n) ? io_sram_dq[`SRAM_DATA_WIDTH-1:(`SRAM_DATA_WIDTH/2)] : sram[o_sram_addr][`SRAM_DATA_WIDTH-1:(`SRAM_DATA_WIDTH/2)];

    assign io_sram_dq[(`SRAM_DATA_WIDTH/2)-1:0] = (~o_sram_ce_n && ~o_sram_oe_n && o_sram_we_n) ? 
                                                  (~o_sram_lb_n) ? sram[o_sram_addr][(`SRAM_DATA_WIDTH/2)-1:0] :
                                                  'bz : 'bz;

    assign io_sram_dq[`SRAM_DATA_WIDTH-1:(`SRAM_DATA_WIDTH/2)] = (~o_sram_ce_n && ~o_sram_oe_n && o_sram_we_n) ? 
                                                                 (~o_sram_ub_n) ? sram[o_sram_addr][`SRAM_DATA_WIDTH-1:(`SRAM_DATA_WIDTH/2)] :
                                                                 'bz : 'bz;

    always_ff @(posedge clk) begin
        if (~o_sram_ce_n && ~o_sram_we_n) begin
            sram[o_sram_addr] <= {sram_dq_ub, sram_dq_lb};
        end
    end

    bus_if #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH)
    ) bus ();

    sram_controller #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH),
        .BASE_ADDR(32'h80000000)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .bus(bus),
        .o_sram_addr(o_sram_addr),
        .io_sram_dq(io_sram_dq),
        .o_sram_ce_n(o_sram_ce_n),
        .o_sram_we_n(o_sram_we_n),
        .o_sram_oe_n(o_sram_oe_n),
        .o_sram_ub_n(o_sram_ub_n),
        .o_sram_lb_n(o_sram_lb_n)
    );

endmodule
