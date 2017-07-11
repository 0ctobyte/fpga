# ModelSim TCL Simulation Script

set PROJECT biu_master 
set FILES {biu_master.sv biu_master_tb.sv ../../types.sv}
set TOP_LEVEL_ENTITY biu_master_tb

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

force clk 1 0ns, 0 5ns -repeat 10ns
force n_rst 0 0ns, 1 10ns

force {biu.address} 0x00000000 0ns, 0x80000000 15ns, 0x80000000 45ns
force {biu.data_out} 0x00000000 0ns, 0x203a0460 15ns, 0x0000000a 45ns
force {biu.en} 0 0ns, 1 15ns, 0 21ns, 1 45ns, 0 51ns
force {biu.rnw} 0 0ns, 1 45ns

force {bus.address} 0x00000000 30ns -cancel 40ns
force {bus.data} 0x00000000 30ns -cancel 40ns
force {bus.control} 0x0 30ns -cancel 40ns

force {bus.address} 0x00000000 60ns
force {bus.data} 0x00000000 60ns, 0x203a0460 81ns
force {bus.control} 0x0 60ns, 0x1 81ns

run 100ns

view wave -undock
wave zoom full
