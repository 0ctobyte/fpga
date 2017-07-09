# ModelSim TCL Simulation Script

set PROJECT seg7_decoder
set FILES seg7_decoder.sv
set TOP_LEVEL_ENTITY seg7_decoder

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

force n_rst 0 0ns, 1 10ns

force i_hex 0x0 10ns, 0x1 20ns, 0x2 30ns, 0x3 40ns , 0x4 50ns, 0x5 60ns, 0x6 70ns, 0x7 80ns, 0x8 90ns, 0x9 100ns, 0xa 110ns, 0xb 120ns, 0xc 130ns, 0xd 140ns, 0xe 150ns, 0xf 160ns

run 170ns

view wave -undock
wave zoom full
