module clock_top(
    input wire clock,
    input wire config_i,      // BTNC - botão de configuração
    input wire increment_i,   // BTNU - botão de incremento
    input wire decrement_i,   // BTND - botão de decremento
    input wire [15:0] SW,     // Switches (não usados)
    output wire [15:0] LED,   // LEDs mostram segundos em binário
    output wire [7:0] an,     // Anodos do display
    output wire [7:0] dec_ddp // Segmentos do display
);

    // Sinais internos
    wire reset;
    wire reset_n;  // Reset ativo baixo para debounce
    wire display_reset;  // Reset separado para o display
    wire seconds_pulse;
    wire count_enable;
    wire [5:0] seconds, load_seconds;
    wire [5:0] minutes, load_minutes;
    wire [4:0] hours, load_hours;
    wire load_time;
    wire [5:0] d1, d2, d3, d4, d5, d6, d7, d8;
    
    // Sinais dos botões debounced
    wire btn_config_db, btn_inc_db, btn_dec_db;
    
    // Reset automático na inicialização (não usa botão)
    reg [3:0] reset_counter;
    always @(posedge clock) begin
        if (reset_counter < 4'hF) begin
            reset_counter <= reset_counter + 1;
        end
    end
    assign reset = (reset_counter < 4'h8);  // Reset por alguns ciclos apenas
    assign reset_n = ~reset;  // Reset ativo baixo para debounce
    
    // Reset para display (sempre baixo após inicialização)
    reg [3:0] display_reset_counter;
    always @(posedge clock) begin
        if (display_reset_counter < 4'hF) begin
            display_reset_counter <= display_reset_counter + 1;
        end
    end
    assign display_reset = (display_reset_counter < 4'h4);  // Reset por alguns ciclos apenas
    
    // LEDs mostram os segundos em binário
    assign LED = {10'b0, seconds};
    
    // Instâncias dos módulos debounce
    debounce #(.DELAY(500_000)) deb_config (
        .clk_i(clock),
        .rstn_i(reset_n),
        .key_i(config_i),
        .debkey_o(btn_config_db)
    );
    
    debounce #(.DELAY(500_000)) deb_inc (
        .clk_i(clock),
        .rstn_i(reset_n),
        .key_i(increment_i),
        .debkey_o(btn_inc_db)
    );
    
    debounce #(.DELAY(500_000)) deb_dec (
        .clk_i(clock),
        .rstn_i(reset_n),
        .key_i(decrement_i),
        .debkey_o(btn_dec_db)
    );
    
    // Instância do divisor de clock (gera pulso de 1 segundo)
    clock_divisor clk_div (
        .clk_100MHz_i(clock),
        .reset_i(reset),
        .seconds_pulse_o(seconds_pulse)
    );
    
    // Instância do contador de tempo
    counter time_counter (
        .clk_100MHz_i(clock),
        .reset_i(reset),
        .seconds_pulse_i(seconds_pulse),
        .count_enable_i(count_enable),
        .load_seconds_i(load_seconds),
        .load_minutes_i(load_minutes),
        .load_hours_i(load_hours),
        .load_time_i(load_time),
        .seconds_o(seconds),
        .minutes_o(minutes),
        .hours_o(hours)
    );
    
    // Instância do watch (módulo principal) - USANDO SINAIS DEBOUNCED
    watch main_watch (
        .clk_100MHz_i(clock),
        .reset_i(reset),
        .seconds_i(seconds),
        .minutes_i(minutes),
        .hours_i(hours),
        .btn_config_i(btn_config_db),    // CORRIGIDO: usando sinal debounced
        .btn_inc_i(btn_inc_db),          // CORRIGIDO: usando sinal debounced
        .btn_dec_i(btn_dec_db),          // CORRIGIDO: usando sinal debounced
        .count_enable_o(count_enable),
        .load_seconds_o(load_seconds),
        .load_minutes_o(load_minutes),
        .load_hours_o(load_hours),
        .load_time_o(load_time),
        .d1(d1), .d2(d2), .d3(d3), .d4(d4),
        .d5(d5), .d6(d6), .d7(d7), .d8(d8)
    );
    
    // Instância do driver de display
    dspl_drv_8dig display_driver (
        .clock(clock),
        .reset(display_reset),
        .d1(d1), .d2(d2), .d3(d3), .d4(d4),
        .d5(d5), .d6(d6), .d7(d7), .d8(d8),
        .an(an),
        .dec_ddp(dec_ddp)
    );
    
endmodule