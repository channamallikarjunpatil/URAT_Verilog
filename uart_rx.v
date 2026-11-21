module uart_rx #(parameter CLKS_PER_BIT = 868)(
    input            clk, rst,
    input            rx,            // serial input (from the TX wire)
    output reg [7:0] rx_data,       // received byte
    output reg       rx_done,       // 1-cycle pulse when a byte is ready
    output reg       frame_err      // 1 if the stop bit was not 1
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    localparam HALF = CLKS_PER_BIT / 2;

    reg [1:0]  state;
    reg [15:0] clk_cnt;             // the RX's own counter
    reg [2:0]  bit_idx;
    reg [7:0]  shreg;
    reg        rx_m, rx_s;          // two-flop synchronizer

    always @(posedge clk) begin
        if (rst) begin
            rx_m      <= 1'b1;
            rx_s      <= 1'b1;
            state     <= IDLE;
            clk_cnt   <= 16'd0;
            bit_idx   <= 3'd0;
            shreg     <= 8'd0;
            rx_data   <= 8'd0;
            rx_done   <= 1'b0;
            frame_err <= 1'b0;
        end else begin
            rx_m    <= rx;          // synchronize the asynchronous input
            rx_s    <= rx_m;
            rx_done <= 1'b0;        // default: pulse for one cycle only

            case (state)

                IDLE: begin
                    clk_cnt <= 16'd0;
                    if (rx_s == 1'b0)             // falling edge: start bit?
                        state <= START;
                end

                START: begin
                    if (clk_cnt == HALF-1) begin  // middle of the start bit
                        clk_cnt <= 16'd0;
                        if (rx_s == 1'b0) begin   // still 0: real start bit
                            bit_idx <= 3'd0;
                            state   <= DATA;
                        end else                  // back to 1: it was a glitch
                            state   <= IDLE;
                    end else
                        clk_cnt <= clk_cnt + 1'b1;
                end

                DATA: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin  // middle of a data bit
                        clk_cnt <= 16'd0;
                        shreg   <= {rx_s, shreg[7:1]};    // new bit enters at the top
                        if (bit_idx == 3'd7)
                            state   <= STOP;
                        else
                            bit_idx <= bit_idx + 1'b1;
                    end else
                        clk_cnt <= clk_cnt + 1'b1;
                end

                STOP: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin  // middle of the stop bit
                        rx_data   <= shreg;
                        rx_done   <= 1'b1;
                        frame_err <= ~rx_s;               // stop bit should be 1
                        clk_cnt   <= 16'd0;
                        state     <= IDLE;
                    end else
                        clk_cnt <= clk_cnt + 1'b1;
                end

            endcase
        end
    end
endmodule