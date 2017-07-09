// 7 Segment Controller
// Interfaces the 7 segment displays with the system bus


module seg7_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WDTH  = 64,
    parameter BASE_ADDR  = 32'hc0001000
