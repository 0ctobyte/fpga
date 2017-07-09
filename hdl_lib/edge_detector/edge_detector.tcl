# ModelSim TCL Simulation Script

set PROJECT edge_detector 
set FILES {edge_detector.sv ../synchronizer/synchronizer.sv}
set TOP_LEVEL_ENTITY edge_detector 

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

add wave *

force clk 1 0ns, 0 5ns -repeat 10ns
force n_rst 0 0ns, 1 10ns

force i_async 0 0ns, 1 9ns, 0 57ns, 1 83ns 

run 150ns

view wave -undock
wave zoom full
