# ModelSim TCL Simulation Script

set PROJECT sram_test
set FILES {sram_test.sv ../hdl_lib/biu_slave/biu_slave.sv ../hdl_lib/biu_master/biu_master.sv ../hdl_lib/chip_select/chip_select.sv ../hdl_lib/edge_detector/edge_detector.sv ../hdl_lib/rom/rom.sv ../hdl_lib/seg7_controller/seg7_controller.sv ../hdl_lib/seg7_decoder/seg7_decoder.sv ../hdl_lib/sram_controller/sram_controller.sv ../hdl_lib/synchronizer/synchronizer.sv ../types.sv}
set TOP_LEVEL_ENTITY sram_test_tb

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

add wave /sram_test_tb/* /sram_test_master_inst/* /sram_test_master_inst/biu_master_inst/*

force CLOCK_50 1 0ns, 0 10ns -repeat 20ns
force {SW[17]} 0 0ns, 1 10ns

force {KEY[0]} 1 0ns, 0 40ns, 1 80ns, 0 160ns, 1 200ns, 0 380ns, 1 450ns

run 500ns

view wave -undock
wave zoom full
