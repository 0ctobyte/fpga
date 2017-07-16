# Load Quartus Prime Tcl project package
package require ::quartus::project

# Load flow package
load_package flow

# Create project
project_new sram_test -revision sram_test -overwrite

# Set project user libraries
set_global_assignment -name SYSTEMVERILOG_FILE sram_test.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../hdl_lib/biu_slave/biu_slave.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../hdl_lib/biu_master/biu_master.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../hdl_lib/chip_select/chip_select.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../hdl_lib/rom/rom.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../hdl_lib/seg7_controller/seg7_controller.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../hdl_lib/seg7_decoder/seg7_decoder.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../hdl_lib/edge_detector/edge_detector.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../hdl_lib/synchronizer/synchronizer.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../hdl_lib/sram_controller/sram_controller.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../types.sv

# Set global assignments
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE115F29C7
set_global_assignment -name TOP_LEVEL_ENTITY sram_test

# Set pin assignments
source "de2-115.pin.tcl"

# Compile
execute_flow -compile

project_close
