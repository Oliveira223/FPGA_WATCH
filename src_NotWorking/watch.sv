module watch (
    input  wire clk_100MHz_i,
    input  wire reset_i,

    // Vem do counter
    input  wire [5:0] seconds_i,
    input  wire [5:0] minutes_i,
    input  wire [4:0] hours_i,

    // Vem do Debouncer
    input  wire btn_config_i,  
    input  wire btn_inc_i,         
    input  wire btn_dec_i,           
    
    // VOlta para o counter
    output wire count_enable_o,
    output wire [5:0] load_seconds_o,
    output wire [5:0] load_minutes_o,
    output wire [4:0] load_hours_o,
    output wire load_time_o,

    // Displays
    output wire [5:0] d1, d2, d3, d4, d5, d6, d7, d8
);

    // Contador para piscar 
    reg [25:0] blink_counter;
    reg blink_signal;

    // Geração do sinal de piscar (conta até 50mi -> 0.5s a 100MHz)
    always @(posedge clk_100MHz_i) begin
        if (reset_i) begin
            blink_counter <= 26'b0;
            blink_signal <= 1'b0;
        end else begin
            blink_counter <= blink_counter + 1;
            if (blink_counter == 26'd50000000) begin // 0.5 segundos a 100MHz
                blink_counter <= 26'b0;
                blink_signal <= ~blink_signal;
            end
        end
    end

    // Detecção de borda para botões debounced (só responde quando o botão é pressionado e não mantido)
    reg btn_config_prev, btn_inc_prev, btn_dec_prev;
    wire btn_config_edge, btn_inc_edge, btn_dec_edge;
    
    always @(posedge clk_100MHz_i) begin
        if (reset_i) begin
            btn_config_prev <= 0;
            btn_inc_prev <= 0;
            btn_dec_prev <= 0;
        end else begin
            btn_config_prev <= btn_config_i;
            btn_inc_prev <= btn_inc_i;
            btn_dec_prev <= btn_dec_i;
        end
    end
    
    // ERRO: SEM EDIÇÃO DE BORDA
    // assign btn_config_edge = btn_config_i && !btn_config_prev;
    // assign btn_inc_edge = btn_inc_i && !btn_inc_prev;
    // assign btn_dec_edge = btn_dec_i && !btn_dec_prev;

    //FORMA ERRADA ==========================
    assign btn_config_edge = btn_config_i;
    assign btn_inc_edge = btn_inc_i;
    assign btn_dec_edge = btn_dec_i;
    //======================================

    // Máquina de Estados (botão do meio p/ avançar)
    typedef enum reg [2:0] {
        RUN = 3'b000,
        EDIT_HOURS = 3'b001,
        EDIT_MIN = 3'b010,
        EDIT_SEC = 3'b011
    } state_t;
    
    state_t current_state, next_state;
    
    // Novos valores para o horário
    reg [5:0] edit_seconds;
    reg [5:0] edit_minutes;
    reg [4:0] edit_hours;
    
    // ======================
    // Máquina de estados
    // ======================
    always @(posedge clk_100MHz_i) begin
        if (reset_i) begin
            current_state <= RUN;
            edit_seconds <= 0;
            edit_minutes <= 0;
            edit_hours <= 0;
        end else begin
            current_state <= next_state;
            
            case (current_state)
                RUN: begin
                    edit_seconds <= seconds_i;
                    edit_minutes <= minutes_i;
                    edit_hours <= hours_i;
                end
                
                EDIT_HOURS: begin
                    if (btn_inc_edge) begin 
                        if (edit_hours == 23)
                            edit_hours <= 0;
                        else
                            edit_hours <= edit_hours + 1;
                    end else if (btn_dec_edge) begin
                        if (edit_hours == 0)
                            edit_hours <= 23;
                        else
                            edit_hours <= edit_hours - 1;
                    end
                end
                
                EDIT_MIN: begin
                    if (btn_inc_edge) begin
                        if (edit_minutes == 59)
                            edit_minutes <= 0;
                        else
                            edit_minutes <= edit_minutes + 1;
                    end else if (btn_dec_edge) begin
                        if (edit_minutes == 0)
                            edit_minutes <= 59;
                        else
                            edit_minutes <= edit_minutes - 1;
                    end
                end
                
                EDIT_SEC: begin
                    if (btn_inc_edge) begin
                        if (edit_seconds == 59)
                            edit_seconds <= 0;
                        else
                            edit_seconds <= edit_seconds + 1;
                    end else if (btn_dec_edge) begin
                        if (edit_seconds == 0)
                            edit_seconds <= 59;
                        else
                            edit_seconds <= edit_seconds - 1;
                    end
                end
            endcase
        end
    end
    
    // Lógica de transição de estados (Cada clique vai para o próximo)
    always @(*) begin
        next_state = current_state;
        
        if (btn_config_edge) begin
            case (current_state)
                RUN:        next_state = EDIT_HOURS;
                EDIT_HOURS: next_state = EDIT_MIN;
                EDIT_MIN:   next_state = EDIT_SEC;
                EDIT_SEC:   next_state = RUN;
                default:    next_state = RUN;
            endcase
        end
    end
    
    // Saídas para o counter
    assign count_enable_o = (current_state == RUN);
    assign load_seconds_o = edit_seconds;
    assign load_minutes_o = edit_minutes;
    assign load_hours_o = edit_hours;
    assign load_time_o = (current_state == EDIT_SEC && btn_config_edge);
    
    // Lógica de display
    reg [5:0] display_seconds, display_minutes;
    reg [4:0] display_hours;
    
    // Exibe o horário estático se estiver no modo edição
    always @(*) begin
        case (current_state)
            RUN: begin
                display_seconds = seconds_i;
                display_minutes = minutes_i;
                display_hours = hours_i;
            end
            default: begin
                display_seconds = edit_seconds;
                display_minutes = edit_minutes;
                display_hours = edit_hours;
            end
        endcase
    end
    
    // Formatação para os displays (HH:MM:SS)
    wire [3:0] hours_tens, hours_units;
    wire [3:0] minutes_tens, minutes_units;
    wire [3:0] seconds_tens, seconds_units;
    
    // Separa a dezena e a unidade
    assign hours_tens = display_hours / 10;
    assign hours_units = display_hours % 10;
    assign minutes_tens = display_minutes / 10;
    assign minutes_units = display_minutes % 10;
    assign seconds_tens = display_seconds / 10;
    assign seconds_units = display_seconds % 10;
    
    // Mapeamento dos displays com piscar
    wire hours_enable, minutes_enable, seconds_enable;
    
    // Controle de enable baseado no estado atual
    assign hours_enable = (current_state == EDIT_HOURS) ? blink_signal : 1'b1; 
    //                                ↑ condição          ↑ se verdade   ↑ se falso
    assign minutes_enable = (current_state == EDIT_MIN) ? blink_signal : 1'b1;
    assign seconds_enable = (current_state == EDIT_SEC) ? blink_signal : 1'b1;
    
    // Mapeamento dos displays
    assign d8 = {hours_enable, hours_tens, 1'b1};      // Horas dezenas
    assign d7 = {hours_enable, hours_units, 1'b1};     // Horas unidades
    assign d6 = {1'b0, 4'b0000, 1'b1};                 // Vazio (espaço)
    assign d5 = {minutes_enable, minutes_tens, 1'b1};  // Minutos dezenas
    assign d4 = {minutes_enable, minutes_units, 1'b1}; // Minutos unidades
    assign d3 = {1'b0, 4'b0000, 1'b1};                 // Vazio (espaço)
    assign d2 = {seconds_enable, seconds_tens, 1'b1};  // Segundos dezenas
    assign d1 = {seconds_enable, seconds_units, 1'b1}; // Segundos unidades
    
    //{enable, digit[3:0], decimal_point}
    //   ↑         ↑            ↑
    // bit 5    bits 4-1     bit 0

    // bit 0 para o pontinho embaixo
    // 1 a 4 para saber qual valor exibir
    // 5 para ativo/inativo

endmodule
