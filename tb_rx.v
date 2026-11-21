`timescale 1ns/1ps
module tb_uart;
    localparam CPB = 16;   // clock cycles per bit

    reg        clk = 0, rst = 1, tx_start = 0;
    reg  [7:0] tx_data = 0;
    wire       tick, tx, busy, tx_done;
    wire [7:0] rx_data;
    wire       rx_done, frame_err;

    integer pass = 0, fail = 0;

    always #5 clk = ~clk;   // 100 MHz

    baud_gen #(.CLKS_PER_BIT(CPB)) bg (.clk(clk), .rst(rst), .tick(tick));

    uart_tx dut_tx (.clk(clk), .rst(rst), .tick(tick), .tx_start(tx_start),
                    .tx_data(tx_data), .tx(tx), .busy(busy), .tx_done(tx_done));

    uart_rx #(.CLKS_PER_BIT(CPB)) dut_rx (.clk(clk), .rst(rst), .rx(tx),
                    .rx_data(rx_data), .rx_done(rx_done), .frame_err(frame_err));

    task send_and_check(input [7:0] d);
        begin
            wait (!busy);                 // make sure the TX is free
            @(posedge clk);
            tx_data  = d;
            tx_start = 1;
            wait (busy);                  // TX accepted the byte
            @(posedge clk);
            tx_start = 0;
            @(posedge rx_done);           // RX finished receiving
            #1;
            if (rx_data === d && frame_err === 1'b0) begin
                $display("PASS: sent %h, got %h", d, rx_data);
                pass = pass + 1;
            end else begin
                $display("FAIL: sent %h, got %h (frame_err=%b)", d, rx_data, frame_err);
                fail = fail + 1;
            end
            wait (!busy);                 // wait for the TX to finish its frame
            repeat (8) @(posedge clk);
        end
    endtask

    initial begin
        #50 rst = 0;
        repeat (10) @(posedge clk);

        send_and_check(8'hA5);
        send_and_check(8'h01);
        send_and_check(8'h80);
        send_and_check(8'hFF);
        send_and_check(8'h00);
        send_and_check(8'h55);

        $display("-----------------------------");
        $display("Tests passed: %0d, failed: %0d", pass, fail);
        if (fail == 0) $display("ALL TESTS PASSED");
        $finish;
    end

    // watchdog: stops the simulation if something hangs
    initial begin
        #200000;
        $display("TIMEOUT: simulation stuck, check the waveform");
        $finish;
    end
endmodule