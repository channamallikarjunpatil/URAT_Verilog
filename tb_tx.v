`timescale 1ns/1ps
module tb_tx;
    reg        clk = 0, rst = 1, tx_start = 0;
    reg  [7:0] tx_data = 0;
    wire       tick, tx, busy, tx_done;

    always #5 clk = ~clk;   // 100 MHz

    baud_gen #(.CLKS_PER_BIT(4)) bg (.clk(clk), .rst(rst), .tick(tick));

    uart_tx dut (.clk(clk), .rst(rst), .tick(tick), .tx_start(tx_start),
                 .tx_data(tx_data), .tx(tx), .busy(busy), .tx_done(tx_done));

    initial begin
        #50 rst = 0;
        #20 tx_data = 8'hA5; tx_start = 1;
        wait (busy);
        tx_start = 0;
        wait (tx_done);
        #100 $finish;
    end
endmodule