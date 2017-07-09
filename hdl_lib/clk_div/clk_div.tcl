# ModelSim TCL Simulation Script

set PROJECT clk_div 
set FILES clk_div.sv
set TOP_LEVEL_ENTITY clk_div 

set TGT_FREQ 115200

# Create a project if it doesn't exist
if {![file isdirectory $PROJECT]} {
    vlib $PROJECT
    vmap $PROJECT "[exec pwd]/$PROJECT"
}

# Compile the design files
foreach vfile $FILES {
    vlog -work $PROJECT $vfile
}

vsim -GTGT_FREQ=$TGT_FREQ $PROJECT.$TOP_LEVEL_ENTITY

restart -force -nowave

add wave *

force clk 1 0ns, 0 5ns -repeat 10ns
force n_rst 0 0ns, 1 10ns

force i_en 0 0ns, 1 25ns

run 10000ns

view wave -undock
wave zoom full
