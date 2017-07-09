# ModelSim TCL Simulation Script

set PROJECT biu_test
set FILES {biu_test.sv ../hdl_lib/biu_master/biu_master.sv ../hdl_lib/biu_sl.sve/biu_sl.sve.sv ../hdl_lib/chip_select/chip_select.sv ../hdl_lib/seg7_decoder/seg7_decoder.sv ../hdl_lib/synchronizer/synchronizer.sv}
set TOP_LEVEL_ENTITY biu_test

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

add wave /biu_test/*

force CLOCK_50 1 0ns, 0 5ns -repeat 10ns
force {SW[17]} 0 0ns, 1 10ns

force {SW[16:0]} 0x00000 0ns, 0x00004 10ns

run 100ns

view wave -undock
wave zoom full
