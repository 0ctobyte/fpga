# ModelSim TCL Simulation Script

set PROJECT seg7_controller
set FILES {seg7_controller.sv ../biu_slave/biu_slave.sv ../chip_select/chip_select.sv ../seg7_decoder/seg7_decoder.sv}
set TOP_LEVEL_ENTITY seg7_controller

set NUM_7SEGMENTS 8

# Create a project if it doesn't exist
if {![file isdirectory $PROJECT]} {
    vlib $PROJECT
    vmap $PROJECT "[exec pwd]/$PROJECT"
}

# Compile the design files
foreach vfile $FILES {
    vlog -work $PROJECT $vfile
}

vsim -GNUM_7SEGMENTS=$NUM_7SEGMENTS $PROJECT.$TOP_LEVEL_ENTITY

restart -force -nowave

add wave *

force clk 1 0ns, 0 10ns -repeat 20ns
force n_rst 0 0ns, 1 10ns

force bus_address 0xc0001000 0ns
force bus_data 0xa65bcde4 0ns
force bus_control 0x1 0ns, 0x0 40ns

run 200ns

view wave -undock
wave zoom full
