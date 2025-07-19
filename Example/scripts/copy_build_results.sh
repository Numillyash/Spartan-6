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
