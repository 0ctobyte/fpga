# ModelSim TCL Simulation Script

set PROJECT uart_tx 
set FILES uart_tx.sv
set TOP_LEVEL_ENTITY uart_tx

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

force i_data 0x41 0ns
force i_data_valid 0 0ns, 1 8681ns

run 200000ns

view wave -undock
wave zoom full
