# ModelSim TCL Simulation Script

set PROJECT uart_controller 
set FILES {uart_controller.sv ../biu_slave/biu_slave.sv ../chip_select/chip_select.sv ../dp_ram/dp_ram.sv ../sync_fifo/sync_fifo.sv ../synchronizer/synchronizer.sv ../uart_rx/uart_rx.sv ../uart_tx/uart_tx.sv}
set TOP_LEVEL_ENTITY uart_controller

# Create a project if it doesn't exist
if {![file isdirectory $PROJECT]} {
    vlib $PROJECT
    vmap $PROJECT "[exec pwd]/$PROJECT"
}

# Compile the design files
foreach vfile $FILES {
    vlog -sv -work $PROJECT $vfile
}

vsim $PROJECT.$TOP_LEVEL_ENTITY

restart -force -nowave

add wave *

force clk 1 0ns, 0 10ns -repeat 20ns
force n_rst 0 0ns, 1 10ns

force bus_address 0x00000000 0ns, 0xc0000000 40ns, 0x00000000 60ns, 0xc0000000 86900ns -cancel 86920ns
force bus_data 0x00000000 0ns, 0x0000006e 40ns, 0x00000000 60ns -cancel 86920ns
force bus_control 0x0 0ns, 0x1 40ns, 0x0 60ns, 0x3 86900ns -cancel 86920ns

force bus_address 0x00000000 86960ns
force bus_data 0x00000000 86960ns
force bus_control 0x0 86960ns

force i_rx 1 0ns, 0 8681ns, 1 26043ns, 0 52086ns, 1 60767ns, 0 78129ns, 1 86810ns

run 200000ns

view wave -undock
wave zoom full
