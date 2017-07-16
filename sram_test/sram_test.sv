`define ADDR_WIDTH 32
`define DATA_WIDTH 32
`define SEG7_SLAVE_ADDR 32'hc0001000
`define SRAM_SLAVE_ADDR 32'h80000000


`define SRAM_ADDR_WIDTH 20
`define SRAM_DATA_WIDTH 16

module sram_test_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input logic clk,
    input logic n_rst,

    input logic i_key,

    bus_if      bus
);

    biu_master_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) biu ();

    typedef enum logic [3:0] {
        IDLE   = 4'b0001,
        SRAMWR = 4'b0010,
        SRAMRD = 4'b0100,
        SEG7WR = 4'b1000
    } state_t;
    state_t state;

    logic [$clog2(16)-1:0] rom_rd_addr;
    logic [DATA_WIDTH-1:0] rom_data;

    logic [DATA_WIDTH-1:0] sram_data;

    logic n_key;
    logic key_pressed;

    assign n_key = ~i_key;

    assign biu.address  = (state == SEG7WR) ? `SEG7_SLAVE_ADDR : (`SRAM_SLAVE_ADDR + rom_rd_addr);
    assign biu.data_out = (state == SEG7WR) ? sram_data : rom_data; 
    assign biu.rnw      = ~(state == SEG7WR || state == SRAMWR);
    assign biu.en       = (state != IDLE && ~biu.busy);

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE:   state <= key_pressed ? SRAMWR : IDLE;
                SRAMWR: state <= ~biu.busy ? SRAMRD : SRAMWR;
                SRAMRD: state <= biu.data_valid ? SEG7WR : SRAMRD;
                SEG7WR: state <= ~biu.busy ? IDLE : SEG7WR;
            endcase
        end
    end 

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            sram_data <= 'b0;
        end else if (biu.data_valid) begin
            sram_data <= biu.data_in;
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            rom_rd_addr <= 'b0;
        end else if (state == SRAMRD && biu.data_valid) begin
            rom_rd_addr <= rom_rd_addr + 1'b1;
        end
    end

    edge_detector edge_detector_inst (
        .clk(clk),
        .n_rst(n_rst),
        .i_async(n_key),
        .o_pulse(key_pressed)
    );

    rom #(
        .DATA_WIDTH(DATA_WIDTH),
        .ROM_DEPTH(16),
        .BASE_ADDR(0),
        .ROM_FILE("rom_init.txt")
    ) rom_inst (
        .clk(clk),
        .n_rst(n_rst),
        .i_rd_addr(rom_rd_addr),
        .o_data_out(rom_data)
    );

    biu_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) biu_master_inst (
        .clk(clk),
        .n_rst(n_rst),
        .bus(bus),
        .biu(biu)
    );

endmodule

module sram_model #(
    parameter SRAM_ADDR_WIDTH,
    parameter SRAM_DATA_WIDTH
) (
    input logic clk,
    input logic n_rst,

    input logic [SRAM_ADDR_WIDTH-1:0] i_sram_addr,
    inout wire  [SRAM_DATA_WIDTH-1:0] io_sram_dq,
    input logic                       i_sram_ce_n,
    input logic                       i_sram_we_n,
    input logic                       i_sram_oe_n,
    input logic                       i_sram_ub_n,
    input logic                       i_sram_lb_n
);
    
    logic [SRAM_DATA_WIDTH-1:0] sram [0:1048576];

    logic [(SRAM_DATA_WIDTH/2)-1:0] sram_dq_lb;
    logic [(SRAM_DATA_WIDTH/2)-1:0] sram_dq_ub;

    assign sram_dq_lb = (~i_sram_lb_n) ? io_sram_dq[(SRAM_DATA_WIDTH/2)-1:0] : sram[i_sram_addr][(SRAM_DATA_WIDTH/2)-1:0];
    assign sram_dq_ub = (~i_sram_ub_n) ? io_sram_dq[SRAM_DATA_WIDTH-1:(SRAM_DATA_WIDTH/2)] : sram[i_sram_addr][SRAM_DATA_WIDTH-1:(SRAM_DATA_WIDTH/2)];

    assign io_sram_dq[(SRAM_DATA_WIDTH/2)-1:0] = (~i_sram_ce_n && ~i_sram_oe_n && i_sram_we_n) ? 
                                                  (~i_sram_lb_n) ? sram[i_sram_addr][(SRAM_DATA_WIDTH/2)-1:0] :
                                                  'bz : 'bz;

    assign io_sram_dq[SRAM_DATA_WIDTH-1:(SRAM_DATA_WIDTH/2)] = (~i_sram_ce_n && ~i_sram_oe_n && i_sram_we_n) ? 
                                                                 (~i_sram_ub_n) ? sram[i_sram_addr][SRAM_DATA_WIDTH-1:(SRAM_DATA_WIDTH/2)] :
                                                                 'bz : 'bz;

    always_ff @(posedge clk) begin
        if (~i_sram_ce_n && ~i_sram_we_n) begin
            sram[i_sram_addr] <= {sram_dq_ub, sram_dq_lb};
        end
    end

endmodule

module sram_test_tb;

    logic CLOCK_50;
    logic [17:17] SW;
    logic [0:0] KEY;
    logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;
    logic [19:0] SRAM_ADDR;
    wire  [15:0] SRAM_DQ;
    logic SRAM_CE_N, SRAM_WE_N, SRAM_OE_N, SRAM_LB_N, SRAM_UB_N;

    bus_if #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH)
    ) bus ();

    sram_test_master #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH)
    ) sram_test_master_inst (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .i_key(KEY[0]),
        .bus(bus)
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

    sram_controller #(
        .DATA_WIDTH(`DATA_WIDTH),
        .ADDR_WIDTH(`ADDR_WIDTH),
        .BASE_ADDR(`SRAM_SLAVE_ADDR)
    ) sram_controller_inst (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .bus(bus),
        .o_sram_addr(SRAM_ADDR),
        .io_sram_dq(SRAM_DQ),
        .o_sram_ce_n(SRAM_CE_N),
        .o_sram_we_n(SRAM_WE_N),
        .o_sram_oe_n(SRAM_OE_N),
        .o_sram_lb_n(SRAM_LB_N),
        .o_sram_ub_n(SRAM_UB_N)
    );

    sram_model #(
        .SRAM_ADDR_WIDTH(`SRAM_ADDR_WIDTH),
        .SRAM_DATA_WIDTH(`SRAM_DATA_WIDTH)
    ) sram_model_inst (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .i_sram_addr(SRAM_ADDR),
        .io_sram_dq(SRAM_DQ),
        .i_sram_ce_n(SRAM_CE_N),
        .i_sram_we_n(SRAM_WE_N),
        .i_sram_oe_n(SRAM_OE_N),
        .i_sram_lb_n(SRAM_LB_N),
        .i_sram_ub_n(SRAM_UB_N)
    );

endmodule

module sram_test (
    input  logic         CLOCK_50,
    input  logic [17:17] SW,

    input  logic [0:0]   KEY,

    inout  wire  [15:0]  SRAM_DQ,
    output logic [19:0]  SRAM_ADDR,
    output logic         SRAM_CE_N,
    output logic         SRAM_WE_N, 
    output logic         SRAM_OE_N,
    output logic         SRAM_LB_N,
    output logic         SRAM_UB_N,

    output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7
);

    bus_if #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH)
    ) bus ();

    sram_test_master #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH)
    ) sram_test_master_inst (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .i_key(KEY[0]),
        .bus(bus)
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

    sram_controller #(
        .DATA_WIDTH(`DATA_WIDTH),
        .ADDR_WIDTH(`ADDR_WIDTH),
        .BASE_ADDR(`SRAM_SLAVE_ADDR)
    ) sram_controller_inst (
        .clk(CLOCK_50),
        .n_rst(SW[17]),
        .bus(bus),
        .o_sram_addr(SRAM_ADDR),
        .io_sram_dq(SRAM_DQ),
        .o_sram_ce_n(SRAM_CE_N),
        .o_sram_we_n(SRAM_WE_N),
        .o_sram_oe_n(SRAM_OE_N),
        .o_sram_lb_n(SRAM_LB_N),
        .o_sram_ub_n(SRAM_UB_N)
    );

endmodule
