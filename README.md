# UART Transmitter and Receiver (Verilog)

FSM-based UART (8N1) with a parameterized baud rate generator, mid-bit sampling receiver
and a two-flop input synchronizer. Verified in ModelSim, implemented in Vivado 2025.2.

## Frame format
idle (1) | start (0) | D0 ... D7 (LSB first) | stop (1)

## Modules
| File | Description |
|---|---|
| rtl/baud_gen.v | Counter that produces a tick every CLKS_PER_BIT clock cycles |
| rtl/uart_tx.v | Transmitter FSM: IDLE, START, DATA, STOP |
| rtl/uart_rx.v | Receiver FSM with synchronizer, half-bit start check and mid-bit sampling |
| rtl/uart_top.v | Top module connecting the three blocks |

## Verification
Self-checking loopback testbench (tb/tb_rx.v) in ModelSim:
- Corner-case bytes: 00, FF, 01, 80, A5, 55
- Glitch injection (1-cycle and 5-cycle) on the RX input
- Back-to-back frames
- 20 random bytes
- Result: [30] passed, [0] failed

![Frame waveform](docs/frame_waveform.png)
![Glitch test](docs/glitch_waveform.png)

## Synthesis results (Vivado 2025.2, xc7a35tcpg236-1, post-route, out-of-context)
| Metric | Value |
|---|---|
| LUTs | 58 |
| Registers | 68 |
| WNS at 100 MHz | +5.445 ns |
| Estimated Fmax | about 219 MHz |

Clock for synthesis: 100 MHz, CLKS_PER_BIT = 868 (115200 baud).

## How to run the simulation
vlib work
vlog rtl/baud_gen.v rtl/uart_tx.v rtl/uart_rx.v tb/tb_rx.v
vsim -voptargs=+acc work.tb_uart
add wave -r /*
run -all

## How to run synthesis
In the Vivado Tcl console: source synth.tcl (edit the path on the first line).

## Possible improvements
Parity bit, configurable data width, TX/RX FIFOs, 16x oversampling and an FPGA demo.
