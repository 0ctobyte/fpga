# ModelSim TCL Simulation Script

set PROJECT synchronizer 
set FILES synchronizer.sv
set TOP_LEVEL_ENTITY synchronizer 

set DATA_WIDTH 8
set SYNC_DEPTH 4

# Create a project if it doesn't exist
if {![file isdirectory $PROJECT]} {
    vlib $PROJECT
    vmap $PROJECT "[exec pwd]/$PROJECT"
}

# Compile the design files
foreach vfile $FILES {
    vlog -work $PROJECT $vfile
}

vsim -GDATA_WIDTH=$DATA_WIDTH -GSYNC_DEPTH=$SYNC_DEPTH $PROJECT.$TOP_LEVEL_ENTITY

restart -force -nowave

add wave *

force clk 1 0ns, 0 5ns -repeat 10ns
force n_rst 0 0ns, 1 10ns

force i_async_data 0x00 0ns, 0x0a 9ns, 0x01 17ns, 0x05 22ns 

run 100ns

view wave -undock
wave zoom full
