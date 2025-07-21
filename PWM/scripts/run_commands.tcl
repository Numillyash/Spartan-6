# TCL команды для управления симуляцией
# Этот файл выполняется автоматически при запуске ISim

# Добавление всех сигналов в Wave окно
add_wave /k_board_tb/clk
add_wave /k_board_tb/col_data
add_wave /k_board_tb/col_power
add_wave /k_board_tb/data
add_wave /k_board_tb/clk_count
add_wave /k_board_tb/uut/counter
add_wave /k_board_tb/uut/cur_scan_col
add_wave /k_board_tb/uut/data_cur
add_wave /k_board_tb/uut/data_out

# Настройка временного масштаба
wave zoomfull

# Запуск симуляции
run all

# Сохранение waveform
write_wave k_board_sim.wcfg

echo "Симуляция завершена. Проверьте консольный вывод и временные диаграммы."
