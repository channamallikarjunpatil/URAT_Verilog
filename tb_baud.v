`timescale 1ns/1ps
module tb_baud;
    reg  clk = 0, rst = 1;
    wire tick;

    always #5 clk = ~clk;          // 10 ns period = 100 MHz

    baud_gen #(.CLKS_PER_BIT(4)) dut (
        .clk(clk), .rst(rst), .tick(tick)
    );

    initial begin
        #25 rst = 0;               // release reset after a few cycles
        #200 $finish;              // run for 20 clock cycles
    end
endmodule