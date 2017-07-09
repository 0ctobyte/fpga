# ModelSim TCL Simulation Script

set PROJECT chip_select 
set FILES chip_select.sv
set TOP_LEVEL_ENTITY chip_select

set BASE_ADDR "32'h80000000"
set ADDR_SPAN "32'h14"
set ALIGNED 1

# Create a project if it doesn't exist
if {![file isdirectory $PROJECT]} {
    vlib $PROJECT
    vmap $PROJECT "[exec pwd]/$PROJECT"
}

# Compile the design files
foreach vfile $FILES {
    vlog -work $PROJECT $vfile
}

vsim -GBASE_ADDR=$BASE_ADDR -GADDR_SPAN=$ADDR_SPAN -GALIGNED=$ALIGNED $PROJECT.$TOP_LEVEL_ENTITY

restart -force -nowave

add wave *

force i_address 0x80000000 0ns, 0x80000001 10ns, 0x80000002 20ns, 0x80000003 30ns, 0x80000004 40ns, 0x80000005 50ns, 0x80000006 60ns, 0x80000007 70ns, 0x80000008 80ns, 0x80000009 90ns, 0x8000000a 100ns, 0x8000000b 110ns, 0x8000000c 120ns, 0x8000000d 130ns, 0x8000000e 140ns, 0x8000000f 150ns, 0x80000010 160ns, 0x80000014 170ns

force i_data_valid 1 0ns, 0 160ns

run 200ns

view wave -undock
wave zoom full
