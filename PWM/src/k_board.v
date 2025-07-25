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
        input  wire[3:0] col_data,  // Данные колонок (4 линии)
        output reg [2:0] col_power, // Питание по колонкам (3 колонки)
        output wire [23:0] data      // Массив данных 8 * 3 (24 бита)
    );

    // ---------------------------------------------------------------------------
    // Настройка таймингов (можно переопределить из верхнего модуля через defparam)
    // ---------------------------------------------------------------------------
    localparam CLK_HZ      = 25_000_000; // частота входного тактового сигнала, Гц
    localparam SCAN_RATE   = 60;       // частота опроса колонки, Гц (50 мс на колонку)
    // 20 гц обновление клавиатуры
    localparam BLANK_US    = 10;         // длительность blank‑фазы, мкс
    // Вычисляем требуемые количества тактов
    localparam integer SCAN_CYCLES = CLK_HZ / SCAN_RATE;           // 25 000 тактов
    localparam integer BLANK_CYC   = (CLK_HZ/1_000_000) * BLANK_US;// 250 тактов
    // ---------------------------------------------------------------------------
    // Внутренние регистры
    // ---------------------------------------------------------------------------
    reg [31:0] scan_cnt  = 0;        // счётчик задержки сканирования
    reg [31:0] blank_cnt = 0;        // счётчик blank‑фазы
    reg [1:0]  col_ix    = 0;        // 0 — R, 1 — G, 2 — B

    reg [23:0] data_cur  = 24'b0;    // временный буфер текущего прохода
    reg [23:0] data_out  = 24'b0;    // временный буфер текущего прохода
    // Инициализация
    initial
    begin
        col_power <= 3'b000;
        data_out <= 24'b0;
        data_cur <= 24'b0;
    end

    // ---------------------------------------------------------------------------
    // Основной процесс сканирования
    // ---------------------------------------------------------------------------
    always @(posedge clk)
    begin
        //------------------------------------------------------------------
        // Фаза BLANK — отключаем питание всех колонок и ждём разряда линий
        //------------------------------------------------------------------
        if (blank_cnt != 0)
        begin
            blank_cnt  <= blank_cnt - 1;
            col_power  <= 3'b000;       // все линии в Z/0
        end

        //------------------------------------------------------------------
        // Фаза SCAN — включаем одну колонку раз в 1 мс, фиксируем col_data
        //------------------------------------------------------------------
        else if (scan_cnt == 0)
        begin
            // Устанавливаем питание для новой колонки
            case ((col_ix == 2) ? 0 : col_ix + 1)
                2'd0: col_power <= 3'b001;  // R‑колонка
                2'd1:
                    col_power <= 3'b010;  // G‑колонка
                2'd2:
                    col_power <= 3'b100;  // B‑колонка
                default:
                    col_power <= 3'b000;
            endcase
            // Переход к следующей колонке
            col_ix   <= (col_ix == 2) ? 0 : col_ix + 1;
            scan_cnt <= SCAN_CYCLES;               // ~1 мс

            // После прохода всех колонок переносим данные наружу
            if (col_ix == 0)
            begin
                data_out <= data_cur;
            end
        end
        else if (scan_cnt == SCAN_CYCLES - SCAN_CYCLES/4)  // Читаем данные в конце периода
        begin
            // Инкрементально-декрементальная логика для кнопок
            case (col_ix)
                2'd0:
                begin // R‑колонка
                    if (col_data[0])
                        data_cur[7:0] <= (data_cur[7:0] >= 8'd4) ? data_cur[7:0] - 8'd4 : 8'd0;      // Кнопка 1: -4
                    if (col_data[1])
                        data_cur[7:0] <= (data_cur[7:0] >= 8'd1) ? data_cur[7:0] - 8'd1 : 8'd0;      // Кнопка 2: -1
                    if (col_data[2])
                        data_cur[7:0] <= (data_cur[7:0] <= 8'd254) ? data_cur[7:0] + 8'd1 : 8'd255; // Кнопка 3: +1
                    if (col_data[3])
                        data_cur[7:0] <= (data_cur[7:0] <= 8'd251) ? data_cur[7:0] + 8'd4 : 8'd255; // Кнопка 4: +4
                end
                2'd1:
                begin // G‑колонка
                    if (col_data[0])
                        data_cur[15:8] <= (data_cur[15:8] >= 8'd4) ? data_cur[15:8] - 8'd4 : 8'd0;
                    if (col_data[1])
                        data_cur[15:8] <= (data_cur[15:8] >= 8'd1) ? data_cur[15:8] - 8'd1 : 8'd0;
                    if (col_data[2])
                        data_cur[15:8] <= (data_cur[15:8] <= 8'd254) ? data_cur[15:8] + 8'd1 : 8'd255;
                    if (col_data[3])
                        data_cur[15:8] <= (data_cur[15:8] <= 8'd251) ? data_cur[15:8] + 8'd4 : 8'd255;
                end
                2'd2:
                begin // B‑колонка
                    if (col_data[0])
                        data_cur[23:16] <= (data_cur[23:16] >= 8'd4) ? data_cur[23:16] - 8'd4 : 8'd0;
                    if (col_data[1])
                        data_cur[23:16] <= (data_cur[23:16] >= 8'd1) ? data_cur[23:16] - 8'd1 : 8'd0;
                    if (col_data[2])
                        data_cur[23:16] <= (data_cur[23:16] <= 8'd254) ? data_cur[23:16] + 8'd1 : 8'd255;
                    if (col_data[3])
                        data_cur[23:16] <= (data_cur[23:16] <= 8'd251) ? data_cur[23:16] + 8'd4 : 8'd255;
                end
                default:
                    ;
            endcase
            scan_cnt <= scan_cnt - 1;              // продолжаем обычный счётчик
            // Запускаем blank‑фазу между колонками
            blank_cnt<= BLANK_CYC;                 // ~10 мкс
        end
        else
        begin
            scan_cnt <= scan_cnt - 1;              // обычный счётчик периода
        end
    end
    // Выходы
    assign data = data_out;

endmodule
