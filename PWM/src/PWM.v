`timescale 1ns / 1ps

/**
 * Модуль: PWM
 * Описание: Отвечает за генерацию сигнала ШИМ
 * Автор: Numillyash
 * Дата: 2025-07-19
 * FPGA: spartan6 (xc6slx25-ftg256-3)
 */

module PWM (
        input  wire clk,            // Тактовая частота 25 МГц
        input  wire[7:0] duty_cycle, // Ширина импульса (0-255)
        output wire out             // Выходной светодиод
    );

    // Внутренние сигналы
    reg [7:0] pwm_counter;
    reg out_reg;

    // Инициализация
    initial
    begin
        pwm_counter <= 0;
        out_reg <= 1'b0;
    end

    // Основная логика
    always @(posedge clk)
    begin
        pwm_counter <= pwm_counter + 1;
        // Сравниваем с коэффициентом заполнения
        if (pwm_counter < duty_cycle)
            out_reg <= 1'b1;
        else
            out_reg <= 1'b0;
    end

    // Выходы
    assign out = out_reg;

endmodule
