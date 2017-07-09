# ModelSim TCL Simulation Script

set PROJECT uart_test
set FILES {uart_test.sv ../hdl_lib/seg7_decoder/seg7_decoder.sv ../hdl_lib/synchronizer/synchronizer.sv ../hdl_lib/uart_rx/uart_rx.sv}
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

add wave /uart_test/*

force CLOCK_50 1 0ns, 0 10ns -repeat 20ns
force {SW[17]} 0 0ns, 1 10ns

force UART_RXD 1 0ns, 0 8681ns, 1 26043ns, 0 52086ns, 1 60767ns, 0 78129ns, 1 86810ns

run 100000ns

view wave -undock
wave zoom full
