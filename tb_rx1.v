`timescale 1ns/1ps
module tb_uart;
    localparam CPB = 16;   // clock cycles per bit

    reg        clk = 0, rst = 1, tx_start = 0;
    reg  [7:0] tx_data = 0;
    wire       tick, tx, busy, tx_done;
    wire [7:0] rx_data;
    wire       rx_done, frame_err;

    // lets the testbench drive the RX input directly for the glitch test
    reg  glitch_en = 0, glitch_rx = 1;
    wire rx_line = glitch_en ? glitch_rx : tx;

    integer pass = 0, fail = 0;

    always #5 clk = ~clk;   // 100 MHz

    baud_gen #(.CLKS_PER_BIT(CPB)) bg (.clk(clk), .rst(rst), .tick(tick));

    uart_tx dut_tx (.clk(clk), .rst(rst), .tick(tick), .tx_start(tx_start),
                    .tx_data(tx_data), .tx(tx), .busy(busy), .tx_done(tx_done));

    uart_rx #(.CLKS_PER_BIT(CPB)) dut_rx (.clk(clk), .rst(rst), .rx(rx_line),
                    .rx_data(rx_data), .rx_done(rx_done), .frame_err(frame_err));

    // ---------- logger: records every byte the RX receives ----------
    reg [7:0] rx_log [0:63];
    integer   rx_idx = 0;
    always @(posedge clk) begin
        if (rx_done) begin
            rx_log[rx_idx] = rx_data;
            rx_idx = rx_idx + 1;
        end
    end

    // ---------- Test 1: send one byte, wait for RX, compare ----------
    task send_and_check(input [7:0] d);
        begin
            wait (!busy);
            @(posedge clk);
            tx_data  = d;
            tx_start = 1;
            wait (busy);
            @(posedge clk);
            tx_start = 0;
            @(posedge rx_done);
            #1;
            if (rx_data === d && frame_err === 1'b0) begin
                $display("PASS: sent %h, got %h", d, rx_data);
                pass = pass + 1;
            end else begin
                $display("FAIL: sent %h, got %h (frame_err=%b)", d, rx_data, frame_err);
                fail = fail + 1;
            end
            wait (!busy);
            repeat (8) @(posedge clk);
        end
    endtask

    // ---------- Test 2: glitch on the RX input ----------
    task glitch_test(input integer width);
        integer before;
        begin
            wait (!busy);
            before = rx_idx;
            @(posedge clk);
            glitch_en = 1;
            glitch_rx = 0;                       // short pulse low
            repeat (width) @(posedge clk);
            glitch_rx = 1;
            repeat (4*CPB) @(posedge clk);       // give the RX time to react
            if (rx_idx == before && dut_rx.state == 2'd0) begin
                $display("PASS: %0d-cycle glitch ignored, RX back in IDLE", width);
                pass = pass + 1;
            end else begin
                $display("FAIL: %0d-cycle glitch caused a false byte or RX not in IDLE", width);
                fail = fail + 1;
            end
            glitch_en = 0;
            repeat (4) @(posedge clk);
        end
    endtask

    // ---------- Test 3: back-to-back bytes (no gap between frames) ----------
    task send_raw(input [7:0] d);
        begin
            @(posedge clk);
            tx_data  = d;
            tx_start = 1;
            wait (busy);
            @(posedge clk);
            tx_start = 0;
            wait (!busy);                        // next call starts right away
        end
    endtask

    task back_to_back;
        reg [7:0] a, b, c;
        integer   base;
        begin
            a = 8'h3C; b = 8'hC3; c = 8'h96;
            wait (!busy);
            base = rx_idx;
            send_raw(a);
            send_raw(b);
            send_raw(c);
            wait (rx_idx == base + 3);
            #1;
            if (rx_log[base] === a && rx_log[base+1] === b && rx_log[base+2] === c) begin
                $display("PASS: back-to-back bytes %h %h %h received in order", a, b, c);
                pass = pass + 1;
            end else begin
                $display("FAIL: back-to-back sent %h %h %h, got %h %h %h",
                          a, b, c, rx_log[base], rx_log[base+1], rx_log[base+2]);
                fail = fail + 1;
            end
            repeat (8) @(posedge clk);
        end
    endtask

    // ---------- main sequence ----------
    integer i;
    reg [7:0] rnd;

    initial begin
        #50 rst = 0;
        repeat (10) @(posedge clk);

        $display("--- Basic bytes ---");
        send_and_check(8'hA5);
        send_and_check(8'h01);
        send_and_check(8'h80);
        send_and_check(8'hFF);
        send_and_check(8'h00);
        send_and_check(8'h55);

        $display("--- Glitch tests ---");
        glitch_test(1);
        glitch_test(5);
        send_and_check(8'h3C);          // RX must still work after the glitches

        $display("--- Back-to-back test ---");
        back_to_back;

        $display("--- 20 random bytes ---");
        for (i = 0; i < 20; i = i + 1) begin
            rnd = $random;
            send_and_check(rnd);
        end

        $display("-----------------------------");
        $display("Tests passed: %0d, failed: %0d", pass, fail);
        if (fail == 0) $display("ALL TESTS PASSED");
        $finish;
    end

    // watchdog: stops the simulation if something hangs
    initial begin
        #1000000;
        $display("TIMEOUT: simulation stuck, check the waveform");
        $finish;
    end
endmodule