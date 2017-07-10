# ModelSim TCL Simulation Script

set PROJECT dp_ram
set FILES {dp_ram.sv}
set TOP_LEVEL_ENTITY dp_ram

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

force clk 1 0ns, 0 10ns -repeat 20ns
force n_rst 0 0ns, 1 20ns

force i_data_in 16#be 20ns, 16#ef 60ns
force i_wr_addr 16#1 20ns, 16#7 60ns
force i_wr_en 0 0ns, 1 20ns, 0 40ns, 1 60ns

force i_rd_addr 16#1 40ns, 16#7 60ns
force i_rd_en 0 0ns, 1 40ns, 1 60ns, 1 80ns

run 100ns

view wave -undock
wave zoom full
