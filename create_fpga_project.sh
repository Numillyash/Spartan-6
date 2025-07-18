#!/bin/bash

# Скрипт для создания нового FPGA проекта со структурированной организацией файлов
# Использование: ./create_fpga_project.sh <имя_проекта> [тип_FPGA]

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода справки
show_help() {
    echo -e "${BLUE}Создание нового FPGA проекта${NC}"
    echo ""
    echo "Использование: $0 <имя_проекта> [тип_FPGA]"
    echo ""
    echo "Параметры:"
    echo "  имя_проекта  - Имя нового проекта (обязательно)"
    echo "  тип_FPGA     - Тип FPGA (по умолчанию: spartan6)"
    echo ""
    echo "Поддерживаемые типы FPGA:"
    echo "  spartan6     - Xilinx Spartan-6 (xc6slx25-ftg256-3)"
    echo "  spartan7     - Xilinx Spartan-7"
    echo "  artix7       - Xilinx Artix-7"
    echo ""
    echo "Примеры:"
    echo "  $0 my_blink_project"
    echo "  $0 uart_controller spartan7"
}

# Проверяем аргументы
if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    show_help
    exit 0
fi

PROJECT_NAME="$1"
FPGA_TYPE="${2:-spartan6}"

# Проверяем корректность имени проекта
if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo -e "${RED}Ошибка: Имя проекта должно содержать только буквы, цифры, дефисы и подчеркивания${NC}"
    exit 1
fi

# Проверяем, не существует ли уже папка с таким именем
if [ -d "$PROJECT_NAME" ]; then
    echo -e "${RED}Ошибка: Директория '$PROJECT_NAME' уже существует${NC}"
    exit 1
fi

echo -e "${BLUE}Создание нового FPGA проекта: ${YELLOW}$PROJECT_NAME${NC}"
echo -e "${BLUE}Тип FPGA: ${YELLOW}$FPGA_TYPE${NC}"
echo ""

# Создаем структуру директорий
echo -e "${GREEN}📁 Создание структуры директорий...${NC}"
mkdir -p "$PROJECT_NAME"/{src,build,scripts,temp,docs}

# Устанавливаем параметры в зависимости от типа FPGA
case $FPGA_TYPE in
    "spartan6")
        DEVICE="xc6slx25-ftg256-3"
        CLK_FREQ="25"
        ;;
    "spartan7")
        DEVICE="xc7s25-csga324-1"
        CLK_FREQ="100"
        ;;
    "artix7")
        DEVICE="xc7a35t-cpg236-1"
        CLK_FREQ="100"
        ;;
    *)
        echo -e "${YELLOW}Предупреждение: Неизвестный тип FPGA '$FPGA_TYPE', используются настройки Spartan-6${NC}"
        DEVICE="xc6slx25-ftg256-3"
        CLK_FREQ="25"
        ;;
esac

echo -e "${GREEN}📝 Создание файлов проекта...${NC}"

# Создаем основной Verilog модуль
cat > "$PROJECT_NAME/src/${PROJECT_NAME}.v" << EOF
\`timescale 1ns / 1ps

/**
 * Модуль: $PROJECT_NAME
 * Описание: Основной модуль проекта $PROJECT_NAME
 * Автор: [Ваше имя]
 * Дата: $(date +%Y-%m-%d)
 * FPGA: $FPGA_TYPE ($DEVICE)
 */

module $PROJECT_NAME (
    input  wire clk,          // Тактовая частота ${CLK_FREQ} МГц
    input  wire reset_n,      // Сброс (активный низкий уровень)
    output wire led,          // Выходной светодиод
    output wire debug_pin     // Отладочный вывод
);

    // Параметры
    localparam CLK_FREQ = ${CLK_FREQ}_000_000;  // Частота в Гц
    localparam BLINK_FREQ = 1;                   // Частота мигания в Гц
    localparam COUNTER_MAX = CLK_FREQ / (2 * BLINK_FREQ) - 1;

    // Внутренние сигналы
    reg [\$clog2(COUNTER_MAX+1)-1:0] counter;
    reg led_reg;
    reg debug_reg;

    // Инициализация
    initial begin
        counter <= 0;
        led_reg <= 1'b0;
        debug_reg <= 1'b0;
    end

    // Основная логика
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 0;
            led_reg <= 1'b0;
            debug_reg <= 1'b0;
        end else begin
            if (counter >= COUNTER_MAX) begin
                counter <= 0;
                led_reg <= ~led_reg;
                debug_reg <= ~debug_reg;
            end else begin
                counter <= counter + 1;
            end
        end
    end

    // Выходы
    assign led = led_reg;
    assign debug_pin = debug_reg;

endmodule
EOF

# Создаем файл ограничений
cat > "$PROJECT_NAME/src/pinout.ucf" << EOF
# Файл ограничений для проекта $PROJECT_NAME
# FPGA: $FPGA_TYPE ($DEVICE)
# Дата создания: $(date +%Y-%m-%d)

# Тактовая частота
NET "clk" LOC = P123;  # Замените на реальный пин
NET "clk" IOSTANDARD = LVCMOS33;
NET "clk" TNM_NET = "clk";
TIMESPEC TS_clk = PERIOD "clk" ${CLK_FREQ} MHz HIGH 50%;

# Сброс
NET "reset_n" LOC = P124;  # Замените на реальный пин  
NET "reset_n" IOSTANDARD = LVCMOS33;
NET "reset_n" PULLUP;

# Светодиод
NET "led" LOC = P125;  # Замените на реальный пин
NET "led" IOSTANDARD = LVCMOS33;
NET "led" DRIVE = 8;
NET "led" SLEW = SLOW;

# Отладочный вывод
NET "debug_pin" LOC = P126;  # Замените на реальный пин
NET "debug_pin" IOSTANDARD = LVCMOS33;
NET "debug_pin" DRIVE = 8;
NET "debug_pin" SLEW = FAST;

# Дополнительные ограничения
# Добавьте здесь свои ограничения по мере необходимости
EOF

# Создаем скрипт компиляции
cat > "$PROJECT_NAME/scripts/compile.sh" << 'EOF'
#!/bin/bash
# Скрипт автоматической компиляции FPGA проекта

# Получаем имя проекта из имени директории
PROJECT_NAME=$(basename "$(dirname "$(pwd)")")
SRC_DIR="../src"
BUILD_DIR="../build"
TEMP_DIR="../temp"

# Проверяем наличие ISE
if ! command -v xst &> /dev/null; then
    echo "Ошибка: Xilinx ISE не найден в PATH"
    echo "Запустите: source /opt/Xilinx/14.7/ISE_DS/settings64.sh"
    exit 1
fi

echo "========================================="
echo "Компиляция проекта: $PROJECT_NAME"
echo "========================================="

# Создаем необходимые директории
mkdir -p "$BUILD_DIR" "$TEMP_DIR"

# Проверяем наличие входных файлов
if [ ! -f "$SRC_DIR/$PROJECT_NAME.v" ]; then
    echo "ОШИБКА: Файл $SRC_DIR/$PROJECT_NAME.v не найден!"
    exit 1
fi

if [ ! -f "$SRC_DIR/pinout.ucf" ]; then
    echo "ОШИБКА: Файл $SRC_DIR/pinout.ucf не найден!"
    exit 1
fi

# Копируем файлы для сборки
cp "$SRC_DIR/$PROJECT_NAME.v" .
cp "$SRC_DIR/pinout.ucf" .

# Создаем XST скрипт
cat > "$PROJECT_NAME.xst" << XSTEOF
set -tmpdir "xst/projnav.tmp"
set -xsthdpdir "xst"
run
-ifn $PROJECT_NAME.prj
-ifmt mixed
-ofn $PROJECT_NAME
-ofmt NGC
-p xc6slx25-ftg256-3
-top $PROJECT_NAME
-opt_mode Speed
-opt_level 1
-power NO
-iuc NO
-keep_hierarchy No
-netlist_hierarchy As_Optimized
-write_timing_constraints NO
-cross_clock_analysis NO
-hierarchy_separator /
-bus_delimiter <>
-case Maintain
-slice_utilization_ratio 100
-bram_utilization_ratio 100
-dsp_utilization_ratio 100
-lc Auto
-reduce_control_sets Auto
-fsm_extract YES
-fsm_encoding Auto
-safe_implementation No
-fsm_style LUT
-ram_extract Yes
-ram_style Auto
-rom_extract Yes
-shreg_extract YES
-rom_style Auto
-auto_bram_packing NO
-resource_sharing YES
-async_to_sync NO
-use_dsp48 Auto
-iobuf YES
-max_fanout 100000
-bufg 16
-register_duplication YES
-register_balancing No
-optimize_primitives NO
-use_clock_enable Auto
-use_sync_set Auto
-use_sync_reset Auto
-iob Auto
-equivalent_register_removal YES
-slice_utilization_ratio_maxmargin 5
XSTEOF

# Создаем PRJ файл
echo "verilog work \"$PROJECT_NAME.v\"" > "$PROJECT_NAME.prj"

echo "1. Синтез (XST)..."
xst -intstyle ise -ifn "$PROJECT_NAME.xst" -ofn "$PROJECT_NAME.syr"
if [ $? -ne 0 ]; then
    echo "ОШИБКА: Синтез не удался!"
    exit 1
fi

echo "2. NgdBuild..."
ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc pinout.ucf -p xc6slx25-ftg256-3 "$PROJECT_NAME.ngc" "$PROJECT_NAME.ngd"
if [ $? -ne 0 ]; then
    echo "ОШИБКА: NgdBuild не удался!"
    exit 1
fi

echo "3. MAP..."
map -intstyle ise -p xc6slx25-ftg256-3 -w -logic_opt off -ol high -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off -o "${PROJECT_NAME}_map.ncd" "$PROJECT_NAME.ngd" "$PROJECT_NAME.pcf"
if [ $? -ne 0 ]; then
    echo "ОШИБКА: MAP не удался!"
    exit 1
fi

echo "4. Place & Route..."
par -w -intstyle ise -ol high -mt off "${PROJECT_NAME}_map.ncd" "$PROJECT_NAME.ncd" "$PROJECT_NAME.pcf"
if [ $? -ne 0 ]; then
    echo "ОШИБКА: Place & Route не удался!"
    exit 1
fi

echo "5. Генерация битфайла..."
bitgen -w "$PROJECT_NAME.ncd" "$PROJECT_NAME.bit"
if [ $? -ne 0 ]; then
    echo "ОШИБКА: Генерация битфайла не удалась!"
    exit 1
fi

# Перемещаем результаты
mv "$PROJECT_NAME.bit" "$BUILD_DIR/"
[ -f "$PROJECT_NAME.mcs" ] && mv "$PROJECT_NAME.mcs" "$BUILD_DIR/"

# Перемещаем временные файлы
mv *.log *.ngc *.ngd *.ncd *.pcf *.map *.mrp *.par *.pad *.drc *.bgn *.xpi *.stx *.syr *.lso *.cmd_log *.ptwx *.unroutes *.xrpt *.html *.xml *.csv *.txt *.prj *.xst "$TEMP_DIR/" 2>/dev/null || true
mv _ngo _xmsgs iseconfig xlnx_auto_0_xdb xst "$TEMP_DIR/" 2>/dev/null || true

echo "========================================="
echo "✅ КОМПИЛЯЦИЯ ЗАВЕРШЕНА УСПЕШНО!"
echo "✅ Битфайл создан: $BUILD_DIR/$PROJECT_NAME.bit"
ls -lh "$BUILD_DIR/$PROJECT_NAME.bit"
echo "========================================="
EOF

chmod +x "$PROJECT_NAME/scripts/compile.sh"

# Создаем Makefile
cat > "$PROJECT_NAME/Makefile" << EOF
# Makefile для FPGA проекта $PROJECT_NAME

PROJECT_NAME = $PROJECT_NAME
TOP_MODULE = $PROJECT_NAME
VERILOG_SRC = src/$PROJECT_NAME.v
UCF_FILE = src/pinout.ucf

# Цели по умолчанию
.PHONY: all clean build program help

all: build

# Сборка проекта
build:
	@echo "Сборка проекта \$(PROJECT_NAME)..."
	@mkdir -p build
	cd scripts && bash compile.sh

# Программирование FPGA  
program:
	@echo "Программирование FPGA..."
	@if [ -f build/\$(PROJECT_NAME).bit ]; then \\
		echo "Используйте Impact или другой программатор для загрузки build/\$(PROJECT_NAME).bit"; \\
	else \\
		echo "Ошибка: файл build/\$(PROJECT_NAME).bit не найден. Сначала выполните 'make build'"; \\
	fi

# Очистка временных файлов
clean:
	@echo "Очистка временных файлов..."
	rm -rf temp/*
	rm -f *.log *.jou

# Полная очистка (включая build)
distclean: clean
	@echo "Полная очистка..."
	rm -rf build/*

# Справка
help:
	@echo "Доступные команды:"
	@echo "  make build    - собрать проект"
	@echo "  make program  - запрограммировать FPGA"
	@echo "  make clean    - очистить временные файлы"
	@echo "  make distclean- полная очистка"
	@echo "  make help     - показать эту справку"

# Показать структуру проекта
tree:
	@echo "Структура проекта:"
	@find . -type f -not -path "./temp/*" -not -path "./.git/*" | sort
EOF

# Создаем .gitignore
cat > "$PROJECT_NAME/.gitignore" << 'EOF'
# ISE и Vivado временные файлы
temp/
*.log
*.jou
*.backup
*~

# Файлы синтеза
*.ngc
*.ngd
*.ngr
*.ncd
*.pcf
*.bld
*.mrp
*.map
*.par
*.pad
*.drc
*.bgn
*.xpi
*.stx
*.syr
*.lso
*.cmd_log
*.ptwx
*.unroutes
*.xwbt

# Отчеты
*.xrpt
*.html
*.xml
*.csv
*.txt
usage_statistics_webtalk.html

# Служебные директории
_xmsgs/
_ngo/
iseconfig/
xlnx_auto_0_xdb/
xst/
.Xil/
vivado*

# Временные проектные файлы
*.prj
*.xst

# OS файлы
.DS_Store
Thumbs.db

# Резервные копии редакторов
*.bak
*.swp
*.swo
*~
EOF

# Создаем README.md
cat > "$PROJECT_NAME/README.md" << EOF
# $PROJECT_NAME

Проект для FPGA $FPGA_TYPE.

## Описание

[Добавьте описание вашего проекта здесь]

## Структура проекта

### 📁 src/
Исходные файлы проекта:
- \`${PROJECT_NAME}.v\` - основной Verilog модуль
- \`pinout.ucf\` - файл ограничений и назначения выводов

### 📁 build/
Готовые файлы для прошивки:
- \`*.bit\` - битфайл для прошивки FPGA
- \`*.mcs\` - файл прошивки в формате MCS

### 📁 scripts/
Скрипты сборки и конфигурации:
- \`compile.sh\` - bash скрипт компиляции

### 📁 temp/
Временные файлы сборки (можно удалить после успешной сборки):
- Отчеты синтеза и имплементации
- Логи компиляции
- Служебные директории ISE

### 📁 docs/
Документация проекта

## Быстрый старт

1. Отредактируйте \`src/pinout.ucf\` - укажите правильные пины для вашей платы
2. При необходимости измените параметры в \`src/${PROJECT_NAME}.v\`
3. Соберите проект: \`make build\`
4. Прошейте FPGA файлом \`build/${PROJECT_NAME}.bit\`

## Сборка

\`\`\`bash
# Сборка проекта
make build

# Очистка временных файлов
make clean

# Полная очистка
make distclean

# Справка
make help
\`\`\`

## Технические характеристики

- **FPGA**: $FPGA_TYPE ($DEVICE)
- **Тактовая частота**: ${CLK_FREQ} МГц
- **Инструменты**: Xilinx ISE

## Примечания

⚠️ **Важно**: Обязательно проверьте и исправьте назначение пинов в файле \`src/pinout.ucf\` в соответствии с вашей платой!

## Автор

[Ваше имя]

## Лицензия

[Укажите лицензию]
EOF

# Создаем пустой файл для документации
touch "$PROJECT_NAME/docs/.gitkeep"

echo ""
echo -e "${GREEN}✅ Проект '$PROJECT_NAME' успешно создан!${NC}"
echo ""
echo -e "${YELLOW}Следующие шаги:${NC}"
echo -e "1. ${BLUE}cd $PROJECT_NAME${NC}"
echo -e "2. ${BLUE}Отредактируйте src/pinout.ucf для вашей платы${NC}"
echo -e "3. ${BLUE}make build${NC} - для сборки проекта"
echo ""
echo -e "${YELLOW}Структура проекта:${NC}"
find "$PROJECT_NAME" -type f | sed 's/^/  /' | sort
echo ""
echo -e "${GREEN}Готово! 🎉${NC}"
