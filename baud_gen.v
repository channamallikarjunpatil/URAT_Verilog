module baud_gen #(parameter CLKS_PER_BIT = 868)(
    input  clk, rst,
    output reg tick
);
    reg [15:0] count;

    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            tick  <= 0;
        end else if (count == CLKS_PER_BIT-1) begin
            count <= 0;
            tick  <= 1;
        end else begin
            count <= count + 1;
            tick  <= 0;
        end
    end
endmodule