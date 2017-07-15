# ModelSim TCL Simulation Script

set PROJECT sram_controller 
set FILES {sram_controller.sv sram_controller_tb.sv ../biu_slave/biu_slave.sv ../chip_select/chip_select.sv ../../types.sv}
set TOP_LEVEL_ENTITY sram_controller_tb

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

add wave -r *
add wave /sram

force clk 1 0ns, 0 10ns -repeat 20ns
force n_rst 0 0ns, 1 10ns

force {bus.address} 0x00000000 0ns, 0x80000000 40ns -cancel 60ns 
force {bus.data} 0x00000000 0ns, 0xdeadbeef 40ns -cancel 60ns
force {bus.control} 0x0 0ns, 0x1 40ns -cancel 60ns

force {bus.address} 0x00000000 80ns, 0x80000004 100ns -cancel 120ns
force {bus.data} 0x00000000 80ns, 0x12346778 100ns -cancel 120ns
force {bus.control} 0x0 80ns, 0x1 100ns -cancel 120ns

force {bus.address} 0x00000000 140ns, 0x80000000 160ns -cancel 180ns
force {bus.control} 0x0 140ns, 0x3 160ns -cancel 180ns

force {bus.address} 0x00000000 220ns, 0x80000004 240ns -cancel 260ns
force {bus.control} 0x0 220ns, 0x3 240ns -cancel 260ns

force {bus.address} 0x80000000 300ns
force {bus.data} 0x00000000 300ns
force {bus.control} 0x0 300ns

run 400ns

view wave -undock
wave zoom full
