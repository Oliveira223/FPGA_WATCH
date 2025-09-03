module counter (
    input  wire clk_100MHz_i,
    input  wire reset_i,           
    input  wire seconds_pulse_i,
    input  wire count_enable_i,         // Pode contar

    // Valores para carregar (do watch)
    input  wire [5:0] load_seconds_i,  
    input  wire [5:0] load_minutes_i,
    input  wire [4:0] load_hours_i,   
    input  wire load_time_i,
    
    output reg [5:0] seconds_o,   // 0-59
    output reg [5:0] minutes_o,   // 0-59
    output reg [4:0] hours_o      // 0-23
);
    
    always @(posedge clk_100MHz_i) begin
        if (reset_i) begin
            seconds_o <= 0;
            minutes_o <= 0;
            hours_o   <= 0;
        end else begin            
            // Carrega novo horário quando solicitado
            if (load_time_i) begin
                seconds_o <= load_seconds_i;
                minutes_o <= load_minutes_i;
                hours_o   <= load_hours_i;
            end
            // Conta apenas se habilitado
            else if (count_enable_i && seconds_pulse_i) begin
                if (seconds_o == 59) begin
                    seconds_o <= 0;
                    if (minutes_o == 59) begin
                        minutes_o <= 0;
                        if (hours_o == 23)
                            hours_o <= 0;
                        else
                            hours_o <= hours_o + 1;
                    end else begin
                        minutes_o <= minutes_o + 1;
                    end
                end else begin
                    seconds_o <= seconds_o + 1;
                end
            end
        end
    end
    
endmodule