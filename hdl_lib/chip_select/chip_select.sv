// Address Based Chip Select

module chip_select #(
    parameter ADDR_WIDTH = 32,
    parameter BASE_ADDR  = 32'h0,
    parameter ADDR_SPAN  = 32'h8,
    parameter ALIGNED    = 1'b1      // Check for 4 byte aligned addresses
) (
    input  wire [ADDR_WIDTH-1:0] i_address,
    input  wire                  i_data_valid,  // The address on the bus is valid

    output wire                  o_cs
);

    wire aligned;

    assign aligned = ~ALIGNED | (i_address[1:0] == 2'b00);
    assign o_cs    = ((i_address >= BASE_ADDR) && (i_address < (BASE_ADDR + ADDR_SPAN)) && i_data_valid && aligned);

endmodule
