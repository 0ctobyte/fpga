# ModelSim TCL Simulation Script

set PROJECT biu_slave 
set FILES {biu_slave_tb.sv ../chip_select/chip_select.sv biu_slave.sv ../../types.sv}
set TOP_LEVEL_ENTITY biu_slave_tb

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

force clk 1 0ns, 0 5ns -repeat 10ns
force n_rst 0 0ns, 1 10ns

force {biu.data_out} 0x00000000 0ns, 0x2032a450 75ns
force {biu.data_valid} 0x0 0ns, 0x1 75ns

force {bus.address} 0x00000000 0ns, 0x80000000 15ns, 0x00000000 21ns, 0x80000000 35ns, 0x00000000 41ns -cancel 80ns
force {bus.data} 0x00000000 0ns, 0x2032a450 15ns, 0x00000000 21ns, 0x0000000a 35ns, 0x00000000 41ns -cancel 80ns
force {bus.control} 0x0 0ns, 0x1 15ns, 0x0 21ns, 0x3 35ns, 0x0 41ns -cancel 80ns

force {bus.address} 0x00000000 90ns
force {bus.data} 0x00000000 90ns
force {bus.control} 0x0 90ns

run 100ns

view wave -undock
wave zoom full
