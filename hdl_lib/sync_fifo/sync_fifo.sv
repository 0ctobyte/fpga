// Synchronous FIFO
// Dual port FIFO for single clock domains with one read and one write port 

module sync_fifo #(
    parameter  DATA_WIDTH = 8,
    parameter  FIFO_DEPTH = 8
) (
    input  wire                  clk,
    input  wire                  n_rst,

    input  wire                  i_wr_en,
    input  wire [DATA_WIDTH-1:0] i_data_in,
    output wire                  o_fifo_full,

    input  wire                  i_rd_en,
    output wire [DATA_WIDTH-1:0] o_data_out,
    output wire                  o_fifo_empty
);

    localparam LOG2_FIFO_DEPTH = $clog2(FIFO_DEPTH);

    // Read and write pointers
    reg [LOG2_FIFO_DEPTH:0] wr_addr;
    reg [LOG2_FIFO_DEPTH:0] rd_addr;

    // Enable signals for the rd_addr and wr_addr registers
    wire wr_addr_en;
    wire rd_addr_en;

    // Enable signals for the FIFO memory
    wire fifo_mem_wr_en;
    wire fifo_mem_rd_en;

    // Write and read addresses for the FIFO memory
    wire [LOG2_FIFO_DEPTH-1:0] fifo_mem_wr_addr;
    wire [LOG2_FIFO_DEPTH-1:0] fifo_mem_rd_addr;

    // Don't update the rd_addr register if the the fifo is empty even if rd_en is asserted
    // Similarly don't update the wr_addr register if the fifo is full even if wr_en is asserted
    assign wr_addr_en = i_wr_en & (~o_fifo_full);
    assign rd_addr_en = i_rd_en & (~o_fifo_empty);

    // The FIFO memory read/write addresses don't include the MSB since that is only 
    // used to check for overflow (i.e. fifo_full) the FIFO entries not actually used to address
    assign fifo_mem_wr_addr = wr_addr[LOG2_FIFO_DEPTH-1:0];
    assign fifo_mem_rd_addr = rd_addr[LOG2_FIFO_DEPTH-1:0];

    // The logic is the same for the FIFO RAM enables and the wr/rd addr enables
    assign fifo_mem_wr_en = wr_addr_en;
    assign fifo_mem_rd_en = rd_addr_en;

    // Update the fifo full/empty signals
    assign o_fifo_full  = ({~wr_addr[LOG2_FIFO_DEPTH], wr_addr[LOG2_FIFO_DEPTH-1:0]} == rd_addr);
    assign o_fifo_empty = (wr_addr == rd_addr);

    // Instantiate RAM for FIFO memory
    dp_ram #(
        .DATA_WIDTH(DATA_WIDTH), 
        .RAM_DEPTH(FIFO_DEPTH), 
        .BASE_ADDR(0)
    ) fifo_mem (
        .clk(clk), 
        .n_rst(n_rst), 
        .i_wr_en(fifo_mem_wr_en), 
        .i_wr_addr(fifo_mem_wr_addr), 
        .i_data_in(i_data_in), 
        .i_rd_en(fifo_mem_rd_en), 
        .i_rd_addr(fifo_mem_rd_addr), 
        .o_data_out(o_data_out)
    ); 

    // Update the wr_addr pointer
    always_ff @(posedge clk, negedge n_rst) begin : WR_ADDR_REG
        if (~n_rst) begin
            wr_addr <= 'b0;
        end else if (wr_addr_en) begin
            wr_addr <= wr_addr + 1;
        end
    end
 
    // Update the rd_addr pointer
    always_ff @(posedge clk, negedge n_rst) begin : RD_ADDR_REG
        if (~n_rst) begin
            rd_addr <= 'b0;
        end else if (rd_addr_en) begin
            rd_addr <= rd_addr + 1;
        end
    end
     
endmodule
