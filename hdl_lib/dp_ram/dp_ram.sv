// Dual Port RAM
// 1 asynchronous read port and 1 synchronous write port

module dp_ram #(
    parameter DATA_WIDTH = 8,
    parameter RAM_DEPTH  = 8,
    parameter BASE_ADDR  = 0
) (
    input  wire   clk,
    input  wire   n_rst,

    // RAM interface
    dp_ram_if.ram if_ram
);

    // Memory array
    reg [DATA_WIDTH-1:0] ram [BASE_ADDR:BASE_ADDR + RAM_DEPTH - 1];

    // Used to check if addresses are within range
    wire cs_wr;
    wire cs_rd;

    assign cs_wr = (n_rst && if_ram.wr_en && (if_ram.wr_addr >= BASE_ADDR) && (if_ram.wr_addr < (BASE_ADDR + RAM_DEPTH)));
    assign cs_rd = (n_rst && if_ram.rd_en && (if_ram.rd_addr >= BASE_ADDR) && (if_ram.rd_addr < (BASE_ADDR + RAM_DEPTH)));

    // Asynchronous read; perform read combinationally 
    assign if_ram.data_out = (cs_rd) ? ram[if_ram.rd_addr] : 'b0;

    // Synchronous write; perform write at positive clock edge
    always_ff @(posedge clk) begin : RAM_WRITE
        if (cs_wr) begin
            ram[if_ram.wr_addr] <= if_ram.data_in;
        end 
    end

endmodule
