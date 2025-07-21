# TCL скрипт для запуска симуляции k_board в ISim
# Автор: Numillyash
# Дата: 2025-07-20

# Создание проекта симуляции
set project_name "k_board_sim"
set testbench_name "k_board_tb"

# Компиляция исходных файлов
echo "Компиляция исходных файлов..."
vlogcomp -work work ../src/k_board.v
vlogcomp -work work ../src/k_board_tb.v

# Создание симулятора
echo "Создание симулятора..."
fuse -top $testbench_name -o ${testbench_name}_sim

# Запуск симуляции
echo "Запуск симуляции..."
./${testbench_name}_sim -gui -tclbatch run_commands.tcl

echo "Симуляция завершена."
