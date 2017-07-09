# ModelSim TCL Simulation Script

set PROJECT uart_rx 
set FILES {uart_rx.sv ../synchronizer/synchronizer.sv ../clk_div/clk_div.sv}
set TOP_LEVEL_ENTITY uart_rx

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

force i_rx 1 0ns, 0 8681ns, 1 26043ns, 0 52086ns, 1 60767ns, 0 78129ns, 1 86810ns
force i_rx 0 104172ns, 1 112853ns, 0 121534ns, 1 164939ns, 0 173620ns, 1 182301ns

run 200000ns

view wave -undock
wave zoom full
