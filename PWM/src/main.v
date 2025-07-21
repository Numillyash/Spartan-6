`timescale 1ns / 1ps

/**
 * Модуль: main
 * Описание: Основной модуль проекта PWM
 * Автор: Numillyash
 * Дата: 2025-07-19
 * FPGA: spartan6 (xc6slx25-ftg256-3)
 */

module main (
        input  wire clk,            // Тактовая частота 25 МГц
        input  wire [3:0] col_data,   // строки клавиатуры
        output wire [2:0] col_power,   // питание колонок
        output wire led_green,      // Выходной светодиод (PWM)
        output wire led_blue,       // Синий светодиод
        output wire led_red,        // Красный светодиод
        output wire led       // Сигнальный светодиод
    );

    // Внутренние сигналы
    reg [31:0] counter;
    reg [7:0] pwm_value_R;
    reg [7:0] pwm_value_G;
    reg [7:0] pwm_value_B;

    // Провода для PWM выходов
    wire pwm_red;
    wire pwm_green;
    wire pwm_blue;
    wire [23:0] kbd_data;

    // wire col_data_1, col_data_2, col_data_3, col_data_4;
    // wire col_power_r, col_power_g, col_power_b;

    // Инициализация
    initial
    begin
        counter <= 0;
        pwm_value_R <= 8'b0;
        pwm_value_G <= 8'b0;
        pwm_value_B <= 8'b0;
    end

    // Основная логика
    always @(posedge clk)
    begin
        if (counter < 2500000)
            counter <= counter + 1;
        else
        begin
            counter <= 0;
            // Прямая логика: kbd_data[3] = 0 когда кнопка нажата и замыкает цепь
            pwm_value_R <= kbd_data[7:0];   // Инвертируем: кнопка нажата (0) → светодиод горит
            pwm_value_G <= kbd_data[15:8];   // Кнопка не нажата (1) → светодиод не горит
            pwm_value_B <= kbd_data[23:16];
        end
    end

    k_board kbd (.clk(clk), .col_data(col_data), .col_power(col_power), .data(kbd_data));
    PWM pwm_inst_red (.clk(clk), .duty_cycle(pwm_value_R), .out(pwm_red));
    PWM pwm_inst_green (.clk(clk), .duty_cycle(pwm_value_G), .out(pwm_green));
    PWM pwm_inst_blue (.clk(clk), .duty_cycle(pwm_value_B), .out(pwm_blue));

    // Подключение внутренних сигналов к выходным портам
    assign led_green = ~pwm_green;
    assign led_blue = ~pwm_blue;
    assign led_red = ~pwm_red;
    assign led = |pwm_value_B;
    // assign led = col_data[3];
    // assign col_data = {col_data_4, col_data_3, col_data_2, col_data_1};
    // assign col_power = {col_power_b, col_power_g, col_power_r};

endmodule
