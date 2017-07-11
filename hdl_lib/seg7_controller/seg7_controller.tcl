# ModelSim TCL Simulation Script

set PROJECT seg7_controller
set FILES {seg7_controller.sv seg7_controller_tb.sv ../biu_slave/biu_slave.sv ../chip_select/chip_select.sv ../seg7_decoder/seg7_decoder.sv ../../types.sv}
set TOP_LEVEL_ENTITY seg7_controller_tb

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

add wave -r *

force clk 1 0ns, 0 10ns -repeat 20ns
force n_rst 0 0ns, 1 10ns

force {bus.address} 0xc0001000 0ns
force {bus.data} 0xa65bcde4 0ns
force {bus.control} 0x1 0ns, 0x0 40ns

run 200ns

view wave -undock
wave zoom full
