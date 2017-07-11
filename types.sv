// User Defined Types shared by the hdl_lib modules

interface bus_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) ();

    wire [ADDR_WIDTH-1:0] address;
    wire [DATA_WIDTH-1:0] data;
    wire [1:0]            control;

endinterface

interface biu_master_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) ();

    wire [ADDR_WIDTH-1:0] address;
    wire [DATA_WIDTH-1:0] data_out;
    wire                  rnw;
    wire                  en;
    wire [DATA_WIDTH-1:0] data_in;
    wire                  data_valid;
    wire                  busy;

    modport biu (
        input  address,
        input  data_out,
        input  rnw,
        input  en,
        output data_in,
        output data_valid,
        output busy
    );

    modport device (
        output address,
        output data_out,
        output rnw,
        output en,
        input  data_in,
        input  data_valid,
        input  busy
    );

endinterface

interface biu_slave_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) ();

    wire [ADDR_WIDTH-1:0] address;
    wire [DATA_WIDTH-1:0] data_in;
    wire                  rnw;
    wire                  en;
    wire [DATA_WIDTH-1:0] data_out;
    wire                  data_valid;

    modport biu (
        output address,
        output data_out,
        output rnw,
        output en,
        input  data_in,
        input  data_valid
    );

    modport device (
        input  address,
        input  data_out,
        input  rnw,
        input  en,
        output data_in,
        output data_valid
    );

endinterface
