#!/bin/bash

# Скрипт для создания нового FPGA проекта с поддержкой TerosHDL
# Использование: ./create_fpga_project_with_teroshdl.sh <имя_проекта> [тип_FPGA]

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода справки
show_help() {
    echo -e "${BLUE}Создание нового FPGA проекта с поддержкой TerosHDL${NC}"
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

echo -e "${BLUE}Создание нового FPGA проекта с TerosHDL: ${YELLOW}$PROJECT_NAME${NC}"
echo -e "${BLUE}Тип FPGA: ${YELLOW}$FPGA_TYPE${NC}"
echo ""

# Создаем структуру директорий
echo -e "${GREEN}📁 Создание структуры директорий...${NC}"
mkdir -p "$PROJECT_NAME"/{src,build,scripts,temp,docs,bitstreams,reports,synthesis}

# Устанавливаем параметры в зависимости от типа FPGA
case $FPGA_TYPE in
    "spartan6")
        DEVICE="xc6slx25-ftg256-3"
        FAMILY="spartan6"
        PACKAGE="ftg256"
        SPEED="-3"
        CLK_FREQ="25"
        ;;
    "spartan7")
        DEVICE="xc7s25-csga324-1"
        FAMILY="spartan7"
        PACKAGE="csga324"
        SPEED="-1"
        CLK_FREQ="100"
        ;;
    "artix7")
        DEVICE="xc7a35t-cpg236-1"
        FAMILY="artix7"
        PACKAGE="cpg236"
        SPEED="-1"
        CLK_FREQ="100"
        ;;
    *)
        echo -e "${YELLOW}Предупреждение: Неизвестный тип FPGA '$FPGA_TYPE', используются настройки Spartan-6${NC}"
        DEVICE="xc6slx25-ftg256-3"
        FAMILY="spartan6"
        PACKAGE="ftg256"
        SPEED="-3"
        CLK_FREQ="25"
        ;;
esac

echo -e "${GREEN}📝 Создание файлов проекта...${NC}"

# Создаем файл конфигурации TerosHDL
cat > "$PROJECT_NAME/teroshdl.json" << TEROS_EOF
{
  "project": {
    "name": "$PROJECT_NAME",
    "description": "FPGA проект $PROJECT_NAME для $FPGA_TYPE",
    "version": "1.0.0",
    "fpga": {
      "family": "$FAMILY",
      "device": "${DEVICE%%-*}",
      "package": "$PACKAGE",
      "speed": "$SPEED"
    }
  },
  "tools": {
    "synthesizer": "xilinx",
    "simulator": "ghdl",
    "build_dir": "build"
  },
  "files": [
    {
      "path": "src/$PROJECT_NAME.v",
      "type": "verilog",
      "is_toplevel": true
    },
    {
      "path": "src/pinout.ucf",
      "type": "constraint"
    }
  ],
  "toplevel": "$PROJECT_NAME"
}
TEROS_EOF

# Создаем основной Verilog модуль
cat > "$PROJECT_NAME/src/${PROJECT_NAME}.v" << VERILOG_EOF
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
VERILOG_EOF

# Создаем файл ограничений
cat > "$PROJECT_NAME/src/pinout.ucf" << UCF_EOF
# Файл ограничений для проекта $PROJECT_NAME
# FPGA: $FPGA_TYPE ($DEVICE)
# Дата создания: $(date +%Y-%m-%d)

# Тактовая частота
NET "clk" LOC = P123;  # Замените на реальный пин для вашей платы
NET "clk" IOSTANDARD = LVCMOS33;
NET "clk" TNM_NET = "clk";
TIMESPEC TS_clk = PERIOD "clk" ${CLK_FREQ} MHz HIGH 50%;

# Сброс
NET "reset_n" LOC = P124;  # Замените на реальный пин для вашей платы
NET "reset_n" IOSTANDARD = LVCMOS33;
NET "reset_n" PULLUP;

# Светодиод
NET "led" LOC = P125;  # Замените на реальный пин для вашей платы
NET "led" IOSTANDARD = LVCMOS33;
NET "led" DRIVE = 8;
NET "led" SLEW = SLOW;

# Отладочный вывод
NET "debug_pin" LOC = P126;  # Замените на реальный пин для вашей платы
NET "debug_pin" IOSTANDARD = LVCMOS33;
NET "debug_pin" DRIVE = 8;
NET "debug_pin" SLEW = FAST;

# Дополнительные ограничения
# Добавьте здесь свои ограничения по мере необходимости
UCF_EOF

# Создаем скрипт для распределения файлов сборки TerosHDL
cat > "$PROJECT_NAME/scripts/copy_build_results.sh" << 'COPY_SCRIPT_EOF'
#!/bin/bash

# Скрипт для копирования и распределения результатов сборки TerosHDL
# по соответствующим папкам проекта

TEROSHDL_BUILD_DIR="/root/.teroshdl/build"
PROJECT_DIR="$(dirname "$(dirname "$(realpath "$0")")")"

# Директории назначения
BUILD_DIR="$PROJECT_DIR/build"
BITSTREAMS_DIR="$PROJECT_DIR/bitstreams" 
REPORTS_DIR="$PROJECT_DIR/reports"
SYNTHESIS_DIR="$PROJECT_DIR/synthesis"
TEMP_DIR="$PROJECT_DIR/temp"

# Создаем все необходимые директории
mkdir -p "$BUILD_DIR" "$BITSTREAMS_DIR" "$REPORTS_DIR" "$SYNTHESIS_DIR" "$TEMP_DIR"

echo "=== Копирование результатов сборки TerosHDL ==="
echo "Источник: $TEROSHDL_BUILD_DIR"
echo "Проект: $PROJECT_DIR"

if [ ! -d "$TEROSHDL_BUILD_DIR" ]; then
    echo "❌ ОШИБКА: Директория сборки TerosHDL не найдена: $TEROSHDL_BUILD_DIR"
    echo "   Возможно, сборка еще не выполнялась через TerosHDL"
    exit 1
fi

echo ""
echo "📁 Распределение файлов по папкам:"

# 1. Битстримы и файлы программирования -> bitstreams/
echo -n "  🔧 Битстримы и файлы программирования... "
BITSTREAM_COUNT=0
for ext in bit mcs bin; do
    if cp "$TEROSHDL_BUILD_DIR"/*.$ext "$BITSTREAMS_DIR/" 2>/dev/null; then
        BITSTREAM_COUNT=$((BITSTREAM_COUNT + $(ls "$TEROSHDL_BUILD_DIR"/*.$ext 2>/dev/null | wc -l)))
    fi
done
echo "скопировано $BITSTREAM_COUNT файлов"

# 2. Файлы синтеза -> synthesis/
echo -n "  ⚙️  Файлы синтеза... "
SYNTH_COUNT=0
for ext in ngc ngd ncd pcf; do
    if cp "$TEROSHDL_BUILD_DIR"/*.$ext "$SYNTHESIS_DIR/" 2>/dev/null; then
        SYNTH_COUNT=$((SYNTH_COUNT + $(ls "$TEROSHDL_BUILD_DIR"/*.$ext 2>/dev/null | wc -l)))
    fi
done
echo "скопировано $SYNTH_COUNT файлов"

# 3. Отчеты -> reports/
echo -n "  📊 Отчеты и анализ... "
REPORT_COUNT=0
for ext in xrpt mrp map par pad csv txt xml html; do
    if cp "$TEROSHDL_BUILD_DIR"/*.$ext "$REPORTS_DIR/" 2>/dev/null; then
        REPORT_COUNT=$((REPORT_COUNT + $(ls "$TEROSHDL_BUILD_DIR"/*.$ext 2>/dev/null | wc -l)))
    fi
done
echo "скопировано $REPORT_COUNT файлов"

# 4. Все остальные файлы -> build/ (для совместимости)
echo -n "  📦 Остальные файлы сборки... "
BUILD_COUNT=0
find "$TEROSHDL_BUILD_DIR" -maxdepth 1 -type f \( \
    -name "*.bgn" -o -name "*.bld" -o -name "*.drc" -o \
    -name "*.lso" -o -name "*.prj" -o -name "*.xst" -o \
    -name "*.syr" -o -name "*.cmd_log" -o -name "*.ptwx" -o \
    -name "*.unroutes" -o -name "*.xpi" -o -name "*.stx" -o \
    -name "*.ut" -o -name "*.twr" -o -name "*.twx" \) \
    -exec cp {} "$BUILD_DIR/" \; 2>/dev/null || true
BUILD_COUNT=$(find "$BUILD_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l)
echo "скопировано файлов в build/"

# 5. Временные файлы -> temp/ (для отладки)
echo -n "  🗂️  Временные файлы... "
cp -r "$TEROSHDL_BUILD_DIR"/_ngo "$TEMP_DIR/" 2>/dev/null || true
cp -r "$TEROSHDL_BUILD_DIR"/_xmsgs "$TEMP_DIR/" 2>/dev/null || true
cp -r "$TEROSHDL_BUILD_DIR"/xlnx_auto_0_xdb "$TEMP_DIR/" 2>/dev/null || true
cp -r "$TEROSHDL_BUILD_DIR"/xst "$TEMP_DIR/" 2>/dev/null || true
TEMP_COUNT=$(find "$TEMP_DIR" -type f 2>/dev/null | wc -l)
echo "скопировано $TEMP_COUNT файлов"

echo ""
echo "📋 Результаты копирования:"
echo "  📁 bitstreams/ : $(find "$BITSTREAMS_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l) файлов"
echo "  📁 synthesis/  : $(find "$SYNTHESIS_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l) файлов"
echo "  📁 reports/    : $(find "$REPORTS_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l) файлов"
echo "  📁 build/      : $(find "$BUILD_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l) файлов"
echo "  📁 temp/       : $(find "$TEMP_DIR" -type f 2>/dev/null | wc -l) файлов"

# Показываем главные результаты
echo ""
echo "🎯 Основные результаты:"
if ls "$BITSTREAMS_DIR"/*.bit >/dev/null 2>&1; then
    echo "  ✅ Битстрим: $(ls "$BITSTREAMS_DIR"/*.bit | head -1)"
    ls -lh "$BITSTREAMS_DIR"/*.bit | awk '{print "     Размер: " $5}'
fi

if ls "$REPORTS_DIR"/*summary* >/dev/null 2>&1; then
    echo "  📊 Сводка: $(ls "$REPORTS_DIR"/*summary* | head -1)"
fi

if ls "$REPORTS_DIR"/*usage* >/dev/null 2>&1; then
    echo "  📈 Использование ресурсов: $(ls "$REPORTS_DIR"/*usage* | head -1)"
fi

echo ""
echo "✅ Распределение файлов завершено успешно!"
COPY_SCRIPT_EOF

chmod +x "$PROJECT_NAME/scripts/copy_build_results.sh"

# Создаем пустые файлы для сохранения структуры папок в git
touch "$PROJECT_NAME/docs/.gitkeep"
touch "$PROJECT_NAME/bitstreams/.gitkeep" 
touch "$PROJECT_NAME/reports/.gitkeep"
touch "$PROJECT_NAME/synthesis/.gitkeep"
touch "$PROJECT_NAME/temp/.gitkeep"

echo ""
echo -e "${GREEN}✅ Проект '$PROJECT_NAME' с поддержкой TerosHDL успешно создан!${NC}"
echo ""
echo -e "${YELLOW}🎯 Следующие шаги:${NC}"
echo -e "1. ${BLUE}cd $PROJECT_NAME${NC}"
echo -e "2. ${BLUE}code .${NC} - открыть в VS Code"
echo -e "3. ${BLUE}Отредактируйте src/pinout.ucf для вашей платы${NC}"
echo -e "4. ${BLUE}Используйте TerosHDL для сборки проекта${NC}"
echo -e "5. ${BLUE}./scripts/copy_build_results.sh${NC} - для организации результатов"
echo ""
echo -e "${GREEN}🎉 Готово! Используйте TerosHDL для сборки проектов.${NC}"

# Функция для добавления проекта в TerosHDL
add_project_to_teroshdl() {
    local project_name="$1"
    local project_path="$2"
    local toplevel_file="$3"
    local constraint_file="$4"
    local device="$5"
    local family="$6"
    local package="$7"
    local speed="$8"
    
    local teroshdl_config="/root/.teroshdl2_prj.json"
    
    echo -e "${BLUE}🔗 Интеграция с TerosHDL...${NC}"
    
    # Проверяем существование файла конфигурации TerosHDL
    if [ ! -f "$teroshdl_config" ]; then
        echo -e "${YELLOW}⚠️  Файл конфигурации TerosHDL не найден, создаем новый...${NC}"
        # Создаем базовую структуру если файла нет
        cat > "$teroshdl_config" << TEROSHDL_BASE
{
    "selected_project": "$project_name",
    "project_list": []
}
TEROSHDL_BASE
    fi
    
    # Создаем новый проект для добавления
    local new_project=$(cat << NEW_PROJECT_JSON
{
    "name": "$project_name",
    "project_disk_path": "",
    "project_type": "genericProject",
    "toplevel": "$toplevel_file",
    "files": [
        {
            "name": "$toplevel_file",
            "file_type": "verilogSource",
            "is_include_file": false,
            "include_path": "",
            "logical_name": "",
            "is_manual": false,
            "file_version": "2000",
            "source_type": "none"
        },
        {
            "name": "$constraint_file",
            "file_type": "none",
            "is_include_file": false,
            "include_path": "",
            "logical_name": "",
            "is_manual": true,
            "source_type": "none"
        }
    ],
    "hooks": {
        "pre_build": [],
        "post_build": [],
        "pre_run": [],
        "post_run": []
    },
    "watchers": [],
    "configuration": {},
    "tool_options": {
        "ise": {
            "name": "ise",
            "installation_path": "/opt/Xilinx/14.7/ISE_DS",
            "config": {
                "installation_path": "/opt/Xilinx/14.7/ISE_DS",
                "family": "$family",
                "device": "${device%%-*}",
                "package": "$package", 
                "speed": "$speed"
            }
        }
    }
}
NEW_PROJECT_JSON
)
    
    # Проверяем, не существует ли уже проект с таким именем
    local existing_project=$(jq -r ".project_list[] | select(.name == \"$project_name\") | .name" "$teroshdl_config" 2>/dev/null)
    
    if [ "$existing_project" = "$project_name" ]; then
        echo -e "${YELLOW}⚠️  Проект '$project_name' уже существует в TerosHDL, обновляем...${NC}"
        # Удаляем существующий проект и добавляем новый
        jq --argjson new_project "$new_project" \
           --arg project_name "$project_name" \
           '.project_list = (.project_list | map(select(.name != $project_name))) + [$new_project] | .selected_project = $project_name' \
           "$teroshdl_config" > "${teroshdl_config}.tmp" && mv "${teroshdl_config}.tmp" "$teroshdl_config"
    else
        echo -e "${GREEN}➕ Добавляем новый проект '$project_name' в TerosHDL...${NC}"
        # Добавляем новый проект
        jq --argjson new_project "$new_project" \
           --arg project_name "$project_name" \
           '.project_list += [$new_project] | .selected_project = $project_name' \
           "$teroshdl_config" > "${teroshdl_config}.tmp" && mv "${teroshdl_config}.tmp" "$teroshdl_config"
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Проект успешно добавлен в TerosHDL!${NC}"
        echo -e "${BLUE}📋 Текущий активный проект в TerosHDL: ${YELLOW}$project_name${NC}"
        
        # Показываем количество проектов
        local project_count=$(jq '.project_list | length' "$teroshdl_config")
        echo -e "${BLUE}📊 Всего проектов в TerosHDL: ${YELLOW}$project_count${NC}"
    else
        echo -e "${RED}❌ Ошибка при добавлении проекта в TerosHDL${NC}"
        return 1
    fi
}

# Вызываем функцию интеграции с TerosHDL
echo ""
PROJECT_FULL_PATH="$(pwd)/$PROJECT_NAME"
TOPLEVEL_FILE="$PROJECT_FULL_PATH/src/${PROJECT_NAME}.v"
CONSTRAINT_FILE="$PROJECT_FULL_PATH/src/pinout.ucf"

add_project_to_teroshdl "$PROJECT_NAME" "$PROJECT_FULL_PATH" "$TOPLEVEL_FILE" "$CONSTRAINT_FILE" "$DEVICE" "$FAMILY" "$PACKAGE" "$SPEED"

echo ""
echo -e "${GREEN}🎉 Проект готов к работе в TerosHDL!${NC}"
echo -e "${BLUE}💡 Откройте VS Code и используйте расширение TerosHDL для работы с проектом.${NC}"
