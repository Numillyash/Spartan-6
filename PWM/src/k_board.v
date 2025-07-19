`timescale 1ns / 1ps

/**
 * Модуль: k_board
 * Описание: Отвечает за обработку клавиатуры
 * Автор: Numillyash
 * Дата: 2025-07-19
 * FPGA: spartan6 (xc6slx25-ftg256-3)
 */

module k_board (
    input  wire clk,            // Тактовая частота 25 МГц
    input  wire[7:0] duty_cycle, // Ширина импульса (0-255)
    output wire led             // Выходной светодиод
  );

  // Внутренние сигналы
  reg [7:0] pwm_counter;
  reg led_reg;

  // Инициализация
  initial
  begin
    pwm_counter <= 0;
    led_reg <= 1'b1;
  end

  // Основная логика
  always @(posedge clk)
  begin
    pwm_counter <= pwm_counter + 1;
    // Сравниваем с коэффициентом заполнения
    if (pwm_counter < duty_cycle)
      led_reg <= 1'b0;
    else
      led_reg <= 1'b1;
  end

  // Выходы
  assign led = led_reg;

endmodule
