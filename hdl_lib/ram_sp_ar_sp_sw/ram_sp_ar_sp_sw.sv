// Multi Port RAM
// 1 asynchronous read port and 1 synchronous write port

module ram_sp_ar_sp_sw #(
    parameter DATA_WIDTH = 8,
    parameter RAM_DEPTH  = 8,
    parameter BASE_ADDR  = 0
) (
    input  wire                         clk,
    input  wire                         n_rst,

    input  wire                         i_wr_en,
    input  wire [$clog2(RAM_DEPTH)-1:0] i_wr_addr,
    input  wire [DATA_WIDTH-1:0]        i_data_in,

    input  wire                         i_rd_en, 
    input  wire [$clog2(RAM_DEPTH)-1:0] i_rd_addr,
    output wire [DATA_WIDTH-1:0]        o_data_out
);

    // Memory array
    reg [DATA_WIDTH-1:0] ram [BASE_ADDR:BASE_ADDR + RAM_DEPTH - 1];

    // Used to check if addresses are within range
    wire cs_wr;
    wire cs_rd;

    assign cs_wr = (n_rst && i_wr_en && (i_wr_addr >= BASE_ADDR) && (i_wr_addr < (BASE_ADDR + RAM_DEPTH)));
    assign cs_rd = (n_rst && i_rd_en && (i_rd_addr >= BASE_ADDR) && (i_rd_addr < (BASE_ADDR + RAM_DEPTH)));

    // Asynchronous read; perform read combinationally 
    assign o_data_out = (cs_rd) ? ram[i_rd_addr] : 'b0;

    // Synchronous write; perform write at positive clock edge
    always_ff @(posedge clk) begin : RAM_WRITE
        if (cs_wr) begin
            ram[i_wr_addr] <= i_data_in;
        end 
    end

endmodule
