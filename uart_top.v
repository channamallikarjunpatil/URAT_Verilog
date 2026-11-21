module uart_top #(parameter CLKS_PER_BIT = 868)(
    input        clk, rst,
    // transmit side
    input        tx_start,
    input  [7:0] tx_data,
    output       tx,
    output       busy,
    output       tx_done,
    // receive side
    input        rx,
    output [7:0] rx_data,
    output       rx_done,
    output       frame_err
);
    wire tick;

    baud_gen #(.CLKS_PER_BIT(CLKS_PER_BIT)) bg (
        .clk(clk), .rst(rst), .tick(tick)
    );

    uart_tx t (
        .clk(clk), .rst(rst), .tick(tick),
        .tx_start(tx_start), .tx_data(tx_data),
        .tx(tx), .busy(busy), .tx_done(tx_done)
    );

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) r (
        .clk(clk), .rst(rst), .rx(rx),
        .rx_data(rx_data), .rx_done(rx_done), .frame_err(frame_err)
    );
endmodule