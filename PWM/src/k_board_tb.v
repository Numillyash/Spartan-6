`timescale 1ns / 1ns

/**
 * Testbench для модуля k_board
 * Описание: Тестирует функциональность сканирования клавиатуры
 * Автор: Numillyash
 * Дата: 2025-07-20
 */

module k_board_tb;

    // Параметры тестирования
    parameter CLK_PERIOD = 40; // 25 МГц = 40 нс период
    parameter SCAN_CYCLES = 10; // Количество циклов сканирования для теста
    parameter SCAN_COUNT = 25000; // 25000 тактов = 1 мс при 25 МГц
    parameter BLANK_COUNT = 250;  // 250 тактов = 10 мкс при 25 МГц

    // Сигналы для подключения к тестируемому модулю
    reg clk;
    reg [3:0] col_data;
    wire [2:0] col_power;
    wire [11:0] data;

    // Счетчик тактов для мониторинга
    reg [31:0] clk_count;

    // Экземпляр тестируемого модуля
    k_board uut (
                .clk(clk),
                .col_data(col_data),
                .col_power(col_power),
                .data(data)
            );

    // Генерация тактового сигнала
    initial
    begin
        clk = 0;
        forever
            #(CLK_PERIOD/2) clk = ~clk;
    end

    // Инициализация и основной тест
    initial
    begin
        // Инициализация сигналов
        col_data = 4'b0000;
        clk_count = 0;

        // Ожидание сброса
        #100;

        $display("=== Начало тестирования модуля k_board ===");
        $display("Частота CLK: 25 МГц, Период: %0d нс", CLK_PERIOD);
        $display("Частота сканирования: 1000 Гц");
        $display("Циклов на сканирование: %0d", SCAN_COUNT);
        $display("Циклов на blanking: %0d", BLANK_COUNT);

        // Тест 1: Проверка базового сканирования без нажатий
        $display("\n--- Тест 1: Базовое сканирование ---");
        test_basic_scanning();

        // Тест 1.5: Проверка тайминга и фаз
        $display("\n--- Тест 1.5: Тайминг и фазы ---");
        test_timing_and_phases();

        // Тест 2: Проверка обнаружения нажатий в разных колонках
        $display("\n--- Тест 2: Нажатия в разных колонках ---");
        test_key_presses();

        // Тест 3: Проверка одновременных нажатий
        $display("\n--- Тест 3: Одновременные нажатия ---");
        test_multiple_presses();

        // Тест 4: Проверка последовательности сканирования
        $display("\n--- Тест 4: Последовательность сканирования ---");
        test_scan_sequence();

        $display("\n=== Тестирование завершено ===");
        $finish;
    end

    // Счетчик тактов
    always @(posedge clk)
    begin
        clk_count <= clk_count + 1;
    end

    // Мониторинг изменений col_power (только ключевые изменения)
    always @(col_power)
    begin
        if (clk_count > 1000) // Избегаем мусора в начале симуляции
            $display("Время: %0t нс, col_power = %b", $time, col_power);
    end

    // Мониторинг изменений данных
    always @(data)
    begin
        if (data != 12'b0 && clk_count > 1000) // Показываем только ненулевые данные
            $display("Время: %0t нс, Данные обновлены: data = %b (%h)", $time, data, data);
    end

    // Задача: Базовое сканирование
    task test_basic_scanning;
        begin
            $display("Проверка циклического сканирования колонок...");
            col_data = 4'b0000; // Никаких нажатий

            // Ждем стабилизации системы
            repeat(SCAN_COUNT * 2) @(posedge clk);

            // Ждем несколько полных циклов сканирования
            repeat(3)
            begin
                wait_full_scan_cycle();
            end

            if (data == 12'b0)
            begin
                $display("✓ Базовое сканирование работает корректно - данные равны нулю");
            end
            else
            begin
                $display("✗ Ошибка: данные не равны нулю при отсутствии нажатий");
                $display("   Текущие данные: %b (%h)", data, data);
            end
        end
    endtask

    // Задача: Тест нажатий клавиш
    task test_key_presses;
        begin
            $display("Тестирование обнаружения нажатий...");

            // Тест нажатия в первой колонке
            $display("Тестирование первой колонки...");
            test_column_press(0, 4'b0001);
            test_column_press(0, 4'b1010);

            // Тест нажатия во второй колонке
            $display("Тестирование второй колонки...");
            test_column_press(1, 4'b0100);
            test_column_press(1, 4'b1111);

            // Тест нажатия в третьей колонке
            $display("Тестирование третьей колонки...");
            test_column_press(2, 4'b1000);
            test_column_press(2, 4'b0101);
        end
    endtask

    // Задача: Тест нажатия в определенной колонке
    task test_column_press;
        input integer column;
        input [3:0] press_pattern;
        reg [11:0] expected_data;
        begin
            // Сброс состояния
            col_data = 4'b0000;
            $display("Сброс состояния, ожидание стабилизации...");
            repeat(SCAN_COUNT * 2) @(posedge clk);

            $display("Тестирование колонки %0d с паттерном %b", column, press_pattern);

            // Установка ожидаемых данных
            expected_data = 12'b0;
            case(column)
                0:
                    expected_data[3:0] = press_pattern;
                1:
                    expected_data[7:4] = press_pattern;
                2:
                    expected_data[11:8] = press_pattern;
                default:
                    expected_data = 12'b0;
            endcase

            // Ждем активации нужной колонки и подаем данные
            wait_for_column_activation(column);
            col_data = press_pattern;
            $display("Данные установлены для колонки %0d: %b", column, press_pattern);

            // Ждем завершения полного цикла сканирования для обновления данных
            wait_full_scan_cycle();

            // Проверка результата
            if (data == expected_data)
            begin
                $display("✓ Колонка %0d: обнаружение работает корректно (данные: %b)", column, data);
            end
            else
            begin
                $display("✗ Колонка %0d: ошибка. Ожидалось: %b (%h), получено: %b (%h)",
                         column, expected_data, expected_data, data, data);
            end

            // Очистка
            col_data = 4'b0000;
            repeat(SCAN_COUNT) @(posedge clk);
        end
    endtask

    // Задача: Тест одновременных нажатий
    task test_multiple_presses;
        reg [11:0] expected_result;
        begin
            $display("Тестирование одновременных нажатий в разных колонках...");

            col_data = 4'b0000;
            repeat(SCAN_COUNT * 2) @(posedge clk);

            expected_result = {4'b1010, 4'b1100, 4'b0011}; // blue, green, red

            // Имитируем нажатия во всех колонках последовательно
            // Колонка 0 (red)
            wait_for_column_activation(0);
            col_data = 4'b0011;
            repeat(SCAN_COUNT/2) @(posedge clk);

            // Колонка 1 (green)
            wait_for_column_activation(1);
            col_data = 4'b1100;
            repeat(SCAN_COUNT/2) @(posedge clk);

            // Колонка 2 (blue)
            wait_for_column_activation(2);
            col_data = 4'b1010;
            repeat(SCAN_COUNT/2) @(posedge clk);            // Ждем обновления данных
            wait_full_scan_cycle();

            $display("Ожидаемый результат: %b (%h)", expected_result, expected_result);
            $display("Полученный результат: %b (%h)", data, data);

            if (data == expected_result)
            begin
                $display("✓ Одновременные нажатия обрабатываются корректно");
            end
            else
            begin
                $display("✗ Ошибка обработки одновременных нажатий");
                $display("   Red (биты 3:0): ожидалось %b, получено %b", expected_result[3:0], data[3:0]);
                $display("   Green (биты 7:4): ожидалось %b, получено %b", expected_result[7:4], data[7:4]);
                $display("   Blue (биты 11:8): ожидалось %b, получено %b", expected_result[11:8], data[11:8]);
            end

            // Очистка
            col_data = 4'b0000;
        end
    endtask

    // Задача: Тест последовательности сканирования
    task test_scan_sequence;
        reg [2:0] prev_col_power;
        integer sequence_errors;
        integer cycle_count;
        begin
            $display("Проверка правильности последовательности сканирования...");
            sequence_errors = 0;
            cycle_count = 0;
            prev_col_power = 3'b000;

            // Ждем стабилизации
            repeat(100) @(posedge clk);

            repeat(SCAN_COUNT * 8) // Несколько полных циклов
            begin
                @(posedge clk);
                if (col_power != prev_col_power)
                begin
                    $display("Смена col_power: %b -> %b на такте %0d", prev_col_power, col_power, cycle_count);
                    case(prev_col_power)
                        3'b000: // blanking -> red
                            if (col_power != 3'b001)
                            begin
                                $display("✗ Ошибка: после blanking ожидался red (001), получен %b", col_power);
                                sequence_errors = sequence_errors + 1;
                            end
                        3'b001: // red -> green
                            if (col_power != 3'b010)
                            begin
                                $display("✗ Ошибка: после red ожидался green (010), получен %b", col_power);
                                sequence_errors = sequence_errors + 1;
                            end
                        3'b010: // green -> blue
                            if (col_power != 3'b100)
                            begin
                                $display("✗ Ошибка: после green ожидался blue (100), получен %b", col_power);
                                sequence_errors = sequence_errors + 1;
                            end
                        3'b100: // blue -> blanking
                            if (col_power != 3'b000)
                            begin
                                $display("✗ Ошибка: после blue ожидался blanking (000), получен %b", col_power);
                                sequence_errors = sequence_errors + 1;
                            end
                        default:
                        begin
                            $display("✗ Неожиданное значение col_power: %b", prev_col_power);
                            sequence_errors = sequence_errors + 1;
                        end
                    endcase
                    prev_col_power = col_power;
                end
                cycle_count = cycle_count + 1;
            end

            if (sequence_errors == 0)
            begin
                $display("✓ Последовательность сканирования корректна");
            end
            else
            begin
                $display("✗ Обнаружено %0d ошибок в последовательности", sequence_errors);
            end
        end
    endtask

    // Задача: Ожидание полного цикла сканирования
    task wait_full_scan_cycle;
        begin
            // Ждем полного цикла: Red + Blank + Green + Blank + Blue + Blank
            $display("Ожидание полного цикла сканирования...");

            // Ждем цикл Red
            wait(col_power == 3'b001);
            repeat(SCAN_COUNT + BLANK_COUNT) @(posedge clk);

            // Ждем цикл Green
            wait(col_power == 3'b010);
            repeat(SCAN_COUNT + BLANK_COUNT) @(posedge clk);

            // Ждем цикл Blue
            wait(col_power == 3'b100);
            repeat(SCAN_COUNT + BLANK_COUNT) @(posedge clk);

            $display("Полный цикл сканирования завершен");
        end
    endtask    // Задача: Ожидание активации определенной колонки
    task wait_for_column_activation;
        input integer column;
        reg [2:0] target_power;
        begin
            case(column)
                0:
                    target_power = 3'b001; // red
                1:
                    target_power = 3'b010; // green
                2:
                    target_power = 3'b100; // blue
                default:
                    target_power = 3'b000;
            endcase

            $display("Ожидание активации колонки %0d (col_power = %b)", column, target_power);
            wait(col_power == target_power);
            $display("Колонка %0d активирована", column);
        end
    endtask

    // Задача: Проверка тайминга и фаз
    task test_timing_and_phases;
        integer phase_counts[0:3];
        integer i;
        reg [2:0] current_col_power;
        reg [2:0] prev_col_power;
        begin
            $display("Проверка тайминга смены фаз...");

            // Инициализация счетчиков
            for (i = 0; i < 4; i = i + 1)
                phase_counts[i] = 0;

            prev_col_power = col_power;

            // Подсчет длительности каждой фазы
            repeat(SCAN_COUNT * 8) // 8 полных циклов
            begin
                @(posedge clk);
                current_col_power = col_power;

                case(current_col_power)
                    3'b000:
                        phase_counts[0] = phase_counts[0] + 1;
                    3'b001:
                        phase_counts[1] = phase_counts[1] + 1;
                    3'b010:
                        phase_counts[2] = phase_counts[2] + 1;
                    3'b100:
                        phase_counts[3] = phase_counts[3] + 1;
                endcase

                prev_col_power = current_col_power;
            end

            $display("Количество тактов в каждой фазе:");
            $display("  Фаза 0 (blanking): %0d тактов", phase_counts[0]);
            $display("  Фаза 1 (red):      %0d тактов", phase_counts[1]);
            $display("  Фаза 2 (green):    %0d тактов", phase_counts[2]);
            $display("  Фаза 3 (blue):     %0d тактов", phase_counts[3]);

            // Проверка, что каждая фаза длится примерно SCAN_COUNT тактов
            for (i = 0; i < 4; i = i + 1)
            begin
                if (phase_counts[i] > SCAN_COUNT * 6 && phase_counts[i] < SCAN_COUNT * 10) // С учетом погрешности
                begin
                    $display("✓ Фаза %0d имеет корректную длительность", i);
                end
                else
                begin
                    $display("✗ Фаза %0d имеет некорректную длительность: %0d (ожидалось ~%0d)", i, phase_counts[i], SCAN_COUNT * 8);
                end
            end
        end
    endtask

    // Дамп сигналов для анализа
    initial
    begin
        $dumpfile("k_board_tb.vcd");
        $dumpvars(0, k_board_tb);
    end

endmodule
