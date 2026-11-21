module uart_tx (
    input            clk, rst,
    input            tick,        // from baud_gen
    input            tx_start,
    input      [7:0] tx_data,
    output reg       tx,
    output reg       busy,
    output reg       tx_done
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;

    reg [1:0] state;
    reg [2:0] bit_idx;
    reg [7:0] shreg;

    always @(posedge clk) begin
        if (rst) begin
            tx      <= 1'b1;
            busy    <= 1'b0;
            tx_done <= 1'b0;
            state   <= IDLE;
            bit_idx <= 3'd0;
            shreg   <= 8'd0;
        end else begin
            tx_done <= 1'b0;                  // default: pulse for one cycle only

            case (state)

                IDLE: begin
                    tx <= 1'b1;
                    if (tx_start && tick) begin
                        shreg <= tx_data;     // copy the byte
                        tx    <= 1'b0;        // start bit begins
                        busy  <= 1'b1;
                        state <= START;
                    end
                end

                START: begin
                    if (tick) begin
                        tx      <= shreg[0];              // send data bit 0
                        shreg   <= {1'b0, shreg[7:1]};    // shift right
                        bit_idx <= 3'd0;
                        state   <= DATA;
                    end
                end

                DATA: begin
                    if (tick) begin
                        if (bit_idx == 3'd7) begin        // all 8 bits sent
                            tx    <= 1'b1;                // stop bit begins
                            state <= STOP;
                        end else begin
                            tx      <= shreg[0];          // send next bit
                            shreg   <= {1'b0, shreg[7:1]};
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end
                end

                STOP: begin
                    if (tick) begin                       // stop bit finished
                        busy    <= 1'b0;
                        tx_done <= 1'b1;
                        state   <= IDLE;
                    end
                end

            endcase
        end
    end
endmodule