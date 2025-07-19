`timescale 1ns / 1ps

/**
 * Модуль: Example
 * Описание: Основной модуль проекта Example
 * Автор: [Ваше имя]
 * Дата: 2025-07-20
 * FPGA: spartan6 (xc6slx25-ftg256-3)
 */

module Example (
    input  wire clk,            // Тактовая частота 25 МГц
    output wire led_green,      // Выходной светодиод (PWM)
    output wire led_blue,       // Синий светодиод (обнулен)
    output wire led_red,        // Красный светодиод (обнулен)
    output wire debug_led       // Отладочный светодиод (тот же PWM сигнал)
  );
  // Внутренние сигналы
  reg [31:0] counter;
  reg [7:0] pwm_value;

  // Провода для PWM выходов
  wire pwm_green;
  wire pwm_debug;

  // Регистры для обнуленных светодиодов
  reg b_led;
  reg r_led;

  // Инициализация
  initial
  begin
    counter <= 0;
    pwm_value <= 0;
    b_led <= 1'b1;
    r_led <= 1'b1;
  end

  // Основная логика
  always @(posedge clk)
  begin
    if (counter < 500000)
      counter <= counter + 1;
    else
    begin
      counter <= 0;
      pwm_value <= pwm_value + 1;
    end
  end

  PWM pwm_inst (.clk(clk), .duty_cycle(pwm_value), .led(pwm_green));
  PWM pwm_debug_inst (.clk(clk), .duty_cycle(pwm_value), .led(pwm_debug));

  // Подключение внутренних сигналов к выходным портам
  assign led_green = pwm_green;
  assign led_blue = b_led;   // Обнулен
  assign led_red = r_led;    // Обнулен
  assign debug_led = pwm_debug; // Тот же PWM сигнал

endmodule
