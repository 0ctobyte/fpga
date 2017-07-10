# ModelSim TCL Simulation Script

set PROJECT uart_test
set FILES {uart_test.sv ../hdl_lib/biu_slave/biu_slave.sv ../hdl_lib/biu_master/biu_master.sv ../hdl_lib/chip_select/chip_select.sv ../hdl_lib/dp_ram/dp_ram.sv ../hdl_lib/seg7_controller/seg7_controller.sv ../hdl_lib/seg7_decoder/seg7_decoder.sv ../hdl_lib/sync_fifo/sync_fifo.sv ../hdl_lib/synchronizer/synchronizer.sv ../hdl_lib/uart_controller/uart_controller.sv ../hdl_lib/uart_rx/uart_rx.sv ../hdl_lib/uart_tx/uart_tx.sv}
set TOP_LEVEL_ENTITY uart_test

# Create a project if it doesn't exist
if {![file isdirectory $PROJECT]} {
    vlib $PROJECT
    vmap $PROJECT "[exec pwd]/$PROJECT"
}

# Compile the design files
foreach vfile $FILES {
    vlog -work $PROJECT $vfile
}

vsim $PROJECT.$TOP_LEVEL_ENTITY

restart -force -nowave

add wave /uart_test/* /uart_test_master_inst/* /uart_controller_inst/*

force CLOCK_50 1 0ns, 0 10ns -repeat 20ns
force {SW[17]} 0 0ns, 1 10ns

force UART_RXD 1 0ns, 0 8681ns, 1 26043ns, 0 52086ns, 1 60767ns, 0 78129ns, 1 86810ns

run 200000ns

view wave -undock
wave zoom full
