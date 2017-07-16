# Quartus tools
QUARTUS_SH := quartus_sh
QUARTUS_PGM := quartus_pgm

# Project configuration
PROJECT := sram_test
TOP_LEVEL_ENTITY := sram_test

# Device information
FAMILY := "Cyclone IV E"
DEVICE := EP4CE115F29C7
PIN_ASSIGNMENTS_FILE := de2-115.pin.tcl

# Directory where source files are located
SRCS := sram_test.sv ../hdl_lib/biu_slave/biu_slave.sv ../hdl_lib/biu_master/biu_master.sv ../hdl_lib/chip_select/chip_select.sv ../hdl_lib/rom/rom.sv ../hdl_lib/seg7_controller/seg7_controller.sv ../hdl_lib/seg7_decoder/seg7_decoder.sv ../hdl_lib/edge_detector/edge_detector.sv ../hdl_lib/synchronizer/synchronizer.sv ../hdl_lib/sram_controller/sram_controller.sv ../types.sv

all: $(PROJECT).sof

sim: ${PROJECT}.do.tcl
	vsim -do $<

program: $(PROJECT).sof
	$(QUARTUS_PGM) -m JTAG -o "P;$<"

clean: 
	-$(QUARTUS_SH) --clean $(PROJECT)
	rm -rf ${PROJECT}/ transcript modelsim.ini vsim.wlf
	rm -rf db/ $(PROJECT).qsf $(PROJECT).qpf

$(PROJECT).tcl: $(PIN_ASSIGNMENTS_FILE)
	echo "# Load Quartus Prime Tcl project package" >> $@
	echo "package require ::quartus::project" >> $@
	echo "" >> $@
	echo "# Load flow package" >> $@ 
	echo "load_package flow" >> $@
	echo "" >> $@
	echo "# Create project" >> $@
	echo "project_new $(PROJECT) -revision $(PROJECT) -overwrite" >> $@
	echo "" >> $@
	echo "# Set project user libraries" >> $@
	$(foreach SRC,$(SRCS),echo "set_global_assignment -name SYSTEMVERILOG_FILE $(SRC)" >> $@;)
	echo "" >> $@
	echo "# Set global assignments" >> $@
	echo "set_global_assignment -name FAMILY \"$(FAMILY)\"" >> $@
	echo "set_global_assignment -name DEVICE $(DEVICE)" >> $@
	echo "set_global_assignment -name TOP_LEVEL_ENTITY $(TOP_LEVEL_ENTITY)" >> $@
	echo "" >> $@
	echo "# Set pin assignments" >> $@
	echo "source \"$(PIN_ASSIGNMENTS_FILE)\"" >> $@
	echo "" >> $@
	echo "# Compile" >> $@
	echo "execute_flow -compile" >> $@
	echo "" >> $@
	echo "project_close" >> $@

$(PROJECT).sof: $(PROJECT).tcl
	$(QUARTUS_SH) -t $<
