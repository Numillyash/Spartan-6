#!/bin/bash
# Скрипт автоматической компиляции проекта Spartan 6

# Настройка переменных окружения ISE
source /opt/Xilinx/14.7/ISE_DS/settings64.sh

PROJECT_NAME=${1:-pl_blink}
SRC_DIR="../src"
BUILD_DIR="../build"
TEMP_DIR="../temp"

echo "========================================="
echo "Компиляция проекта Spartan 6: $PROJECT_NAME"
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

# Копируем файлы во временную директорию для сборки
cp "$SRC_DIR/$PROJECT_NAME.v" .
cp "$SRC_DIR/pinout.ucf" .

echo "1. Синтез (XST)..."
xst -intstyle ise -ifn $PROJECT_NAME.xst -ofn $PROJECT_NAME.syr
if [ $? -ne 0 ]; then
    echo "ОШИБКА: Синтез не удался!"
    exit 1
fi

echo "2. NgdBuild..."
ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc pinout.ucf -p xc6slx25-ftg256-3 $PROJECT_NAME.ngc $PROJECT_NAME.ngd
if [ $? -ne 0 ]; then
    echo "ОШИБКА: NgdBuild не удался!"
    exit 1
fi

echo "3. MAP..."
map -intstyle ise -p xc6slx25-ftg256-3 -w -logic_opt off -ol high -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off -o ${PROJECT_NAME}_map.ncd $PROJECT_NAME.ngd $PROJECT_NAME.pcf
if [ $? -ne 0 ]; then
    echo "ОШИБКА: MAP не удался!"
    exit 1
fi

echo "4. Place & Route..."
par -w -intstyle ise -ol high -mt off ${PROJECT_NAME}_map.ncd $PROJECT_NAME.ncd $PROJECT_NAME.pcf
if [ $? -ne 0 ]; then
    echo "ОШИБКА: Place & Route не удался!"
    exit 1
fi

echo "5. Генерация битфайла..."
bitgen -w $PROJECT_NAME.ncd $PROJECT_NAME.bit
if [ $? -ne 0 ]; then
    echo "ОШИБКА: Генерация битфайла не удалась!"
    exit 1
fi

# Перемещаем результаты в build директорию
mv $PROJECT_NAME.bit "$BUILD_DIR/"
[ -f $PROJECT_NAME.mcs ] && mv $PROJECT_NAME.mcs "$BUILD_DIR/"

# Перемещаем временные файлы
mv *.log *.ngc *.ngd *.ncd *.pcf *.map *.mrp *.par *.pad *.drc *.bgn *.xpi *.stx *.syr *.lso *.cmd_log *.ptwx *.unroutes *.xrpt *.html *.xml *.csv *.txt "$TEMP_DIR/" 2>/dev/null || true
mv _ngo _xmsgs iseconfig xlnx_auto_0_xdb xst "$TEMP_DIR/" 2>/dev/null || true

echo "========================================="
echo "✅ КОМПИЛЯЦИЯ ЗАВЕРШЕНА УСПЕШНО!"
echo "✅ Битфайл создан: $BUILD_DIR/$PROJECT_NAME.bit"
ls -lh "$BUILD_DIR/$PROJECT_NAME.bit"
echo "========================================="
