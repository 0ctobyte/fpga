// User Defined Types shared by the hdl_lib modules

interface bus_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) ();

    logic [ADDR_WIDTH-1:0] address;
    logic [DATA_WIDTH-1:0] data;
    logic [1:0]            control;

endinterface

interface biu_master_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) ();

    logic [ADDR_WIDTH-1:0] address;
    logic [DATA_WIDTH-1:0] data_out;
    logic                  rnw;
    logic                  en;
    logic [DATA_WIDTH-1:0] data_in;
    logic                  data_valid;
    logic                  busy;

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

    logic [ADDR_WIDTH-1:0] address;
    logic [DATA_WIDTH-1:0] data_in;
    logic                  rnw;
    logic                  en;
    logic [DATA_WIDTH-1:0] data_out;
    logic                  data_valid;

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

interface dp_ram_if #(
    parameter DATA_WIDTH = 8,
    parameter RAM_DEPTH  = 8
) ();

    logic                         wr_en;
    logic [$clog2(RAM_DEPTH)-1:0] wr_addr;
    logic [DATA_WIDTH-1:0]        data_in;

    logic                         rd_en;
    logic [$clog2(RAM_DEPTH)-1:0] rd_addr;
    logic [DATA_WIDTH-1:0]        data_out;

    modport ram (
        input  wr_en,
        input  wr_addr,
        input  data_in,
        input  rd_en,
        input  rd_addr,
        output data_out
    );

    modport sys (
        output wr_en,
        output wr_addr,
        output data_in,
        output rd_en,
        output rd_addr,
        input  data_out
    );

endinterface

interface fifo_if #(
    parameter DATA_WIDTH = 8
) ();

    logic                  wr_en;
    logic [DATA_WIDTH-1:0] data_in;
    logic                  full;

    logic                  rd_en;
    logic [DATA_WIDTH-1:0] data_out;
    logic                  empty;

    modport fifo (
        input  wr_en,
        input  data_in,
        output full,
        input  rd_en,
        output data_out,
        output empty
    );

    modport sys (
        output wr_en,
        output data_in,
        input  full,
        output rd_en,
        input  data_out,
        input  empty
    );

endinterface
