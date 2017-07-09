# Load Quartus Prime Tcl project package
package require ::quartus::project

# Load flow package
load_package flow

# Create project
project_new seg7_test -revision seg7_test -overwrite

# Set project user libraries
set_global_assignment -name SYSTEMVERILOG_FILE seg7_test.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../hdl_lib/seg7_decoder/seg7_decoder.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../hdl_lib/synchronizer/synchronizer.sv

# Set global assignments
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE115F29C7
set_global_assignment -name TOP_LEVEL_ENTITY seg7_test

# Set pin assignments
source "de2-115.pin.tcl"

# Compile
execute_flow -compile

project_close
