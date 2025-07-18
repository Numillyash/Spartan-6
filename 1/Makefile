# Makefile для проекта FPGA Spartan-6

PROJECT_NAME = pl_blink
TOP_MODULE = pl_blink
VERILOG_SRC = src/av_blink.v
UCF_FILE = src/pinout.ucf

# Цели по умолчанию
.PHONY: all clean build program help

all: build

# Сборка проекта
build:
	@echo "Сборка проекта $(PROJECT_NAME)..."
	@mkdir -p build
	cd scripts && bash compile.sh

# Программирование FPGA
program:
	@echo "Программирование FPGA..."
	@if [ -f build/$(PROJECT_NAME).bit ]; then \
		echo "Используйте Impact или другой программатор для загрузки build/$(PROJECT_NAME).bit"; \
	else \
		echo "Ошибка: файл build/$(PROJECT_NAME).bit не найден. Сначала выполните 'make build'"; \
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
