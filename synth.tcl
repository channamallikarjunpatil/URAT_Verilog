cd {D:/Academics Projects/URAT}
file mkdir reports

read_verilog rtl/baud_gen.v
read_verilog rtl/uart_tx.v
read_verilog rtl/uart_rx.v
read_verilog rtl/uart_top.v
read_xdc constraints/uart.xdc

# Synthesis: 868 clocks per bit = 115200 baud at 100 MHz
synth_design -top uart_top -part xc7a35tcpg236-1 -mode out_of_context -generic CLKS_PER_BIT=868
report_utilization    -file reports/util_synth.txt
report_timing_summary -file reports/timing_synth.txt

# Implementation (place and route) for more realistic timing
opt_design
place_design
route_design
report_utilization    -file reports/util_impl.txt
report_timing_summary -file reports/timing_impl.txt