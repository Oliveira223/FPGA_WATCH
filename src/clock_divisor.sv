module clock_divisor(
    input wire clk_100MHz_i,
    input wire reset_i,
    output reg seconds_pulse_o
);

    reg [27:0] counter; 

    always @(posedge clk_100MHz_i) begin
        if (reset_i) begin
            counter <= 0;
            seconds_pulse_o <= 0;
        end else begin
            if (counter == 100_000_000 - 1) begin
                counter <= 0;
                seconds_pulse_o <= 1;
            end else begin
                counter <= counter + 1;
                seconds_pulse_o <= 0;
            end
        end
    end

endmodule