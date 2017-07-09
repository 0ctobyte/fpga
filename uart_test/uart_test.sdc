create_clock -period 20 CLOCK_50
create_clock -period 20 -name ext_clk
derive_clock_uncertainty

set_input_delay -clock ext_clk -max 2.0 [get_ports {SW[*]}]
set_input_delay -clock ext_clk -min -1.0 [get_ports {SW[*]}]
set_output_delay -clock ext_clk -max 2.0 [get_ports {HEX0[*]}]
set_output_delay -clock ext_clk -min -1.0 [get_ports {HEX0[*]}]
set_output_delay -clock ext_clk -max 2.0 [get_ports {HEX1[*]}]
set_output_delay -clock ext_clk -min -1.0 [get_ports {HEX1[*]}]
set_input_delay -clock ext_clk -max 2.0 [get_ports {UART_RXD}]
set_input_delay -clock ext_clk -min -1.0 [get_ports {UART_RXD}]
