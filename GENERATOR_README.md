# 🚀 Генератор FPGA проектов

Этот инструмент позволяет быстро создавать новые FPGA проекты с организованной структурой файлов.

## 📋 Использование

```bash
# Показать справку
./create_fpga_project.sh --help

# Создать проект с именем "my_project" для Spartan-6 (по умолчанию)
./create_fpga_project.sh my_project

# Создать проект для Spartan-7
./create_fpga_project.sh uart_controller spartan7

# Создать проект для Artix-7
./create_fpga_project.sh dsp_filter artix7
```

## 🏗️ Структура создаваемого проекта

```
project_name/
├── src/                    # Исходные файлы
│   ├── project_name.v      # Основной Verilog модуль
│   └── pinout.ucf          # Файл ограничений
├── build/                  # Готовые файлы для прошивки
├── scripts/                # Скрипты сборки
│   └── compile.sh          # Скрипт компиляции
├── temp/                   # Временные файлы (игнорируются git)
├── docs/                   # Документация
├── .gitignore              # Исключения для git
├── Makefile                # Команды сборки
└── README.md               # Документация проекта
```

## 🎯 Поддерживаемые FPGA

| Тип FPGA | Устройство        | Тактовая частота |
| -------- | ----------------- | ---------------- |
| spartan6 | xc6slx25-ftg256-3 | 25 МГц           |
| spartan7 | xc7s25-csga324-1  | 100 МГц          |
| artix7   | xc7a35t-cpg236-1  | 100 МГц          |

## 🔧 Команды для работы с проектом

После создания проекта перейдите в его директорию и используйте:

```bash
# Сборка проекта
make build

# Очистка временных файлов
make clean

# Полная очистка (включая build)
make distclean

# Показать все доступные команды
make help

# Показать структуру проекта
make tree
```

## ⚠️ Важные замечания

1. **Настройте пины**: Обязательно отредактируйте `src/pinout.ucf` в соответствии с вашей платой
2. **ISE Environment**: Убедитесь, что Xilinx ISE настроен в системе
3. **Имена проектов**: Используйте только буквы, цифры, дефисы и подчеркивания

## 🎨 Возможности шаблона

Созданный проект включает:

- ✅ Базовый модуль с мигающим светодиодом
- ✅ Правильные параметры частоты для выбранной FPGA
- ✅ Отладочный вывод
- ✅ Сброс по низкому уровню
- ✅ Современный Verilog код с параметрами
- ✅ Автоматическую сборку через Makefile
- ✅ Git-готовность (.gitignore)
- ✅ Подробную документацию

## 🔍 Примеры использования

```bash
# Простой проект мигания светодиода
./create_fpga_project.sh led_blink

# UART контроллер для Spartan-7
./create_fpga_project.sh uart_ctrl spartan7

# DSP фильтр для Artix-7
./create_fpga_project.sh fir_filter artix7

# I2C контроллер
./create_fpga_project.sh i2c_master

# VGA контроллер
./create_fpga_project.sh vga_controller
```

## 🚀 Быстрый старт

1. Создайте проект: `./create_fpga_project.sh my_awesome_project`
2. Перейдите в папку: `cd my_awesome_project`
3. Настройте пины в: `src/pinout.ucf`
4. Соберите проект: `make build`
5. Прошейте FPGA файлом: `build/my_awesome_project.bit`

---

**Автор**: Создано автоматически генератором FPGA проектов  
**Дата**: $(date +%Y-%m-%d)
