# Сессия работы с OpenOCD и настройка ISE в WSL

## Дата: 18 июля 2025

## Решенные задачи:

### 1. ✅ OpenOCD + USB Blaster + Spartan 6

- **Проблема**: OpenOCD не мог подключиться к USB Blaster на Windows
- **Решение**: Установка WinUSB драйвера через Zadig
- **Результат**: USB Blaster успешно обнаружен, Spartan 6 найден (IDCODE: 0x24004093)
- **Файл конфигурации**: `quick_test.cfg`

### 2. ✅ Настройка WSL для ISE

- **Ubuntu WSL**: Установлен как дистрибутив по умолчанию
- **Зависимости**: Установлены все необходимые библиотеки для ISE GUI
- **ISO**: Смонтирован из `N:\Xilinx\ISE Design Suite\Xilinx ISE Design Suite_14.7_1015_1.iso`
- **Символическая ссылка**: `~/spartan6` → `/mnt/c/Users/Georgul/Documents/FPGA_ALL/ПЛИСы/Spartan 6`

### 3. ✅ Архитектура решения

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   WSL2 Ubuntu   │    │   Windows 11     │    │   FPGA Board    │
│                 │    │                  │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│ │    ISE      │ │    │ │   OpenOCD    │ │    │ │  Spartan 6  │ │
│ │   Синтез    │ │◄──►│ │ USB Blaster  │ │◄──►│ │    JTAG     │ │
│ │  .bit файлы │ │    │ │ Программатор │ │    │ │             │ │
│ └─────────────┘ │    │ └──────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └──────────────────┘    └─────────────────┘
        ▲                        ▲
        │                        │
    Общая папка (/mnt/c/...)     │
                                 │
              VS Code с Remote-WSL
```

## Следующие шаги:

### 4. ✅ Установка ISE (завершена)

- ISO смонтирован из `N:\Xilinx\ISE Design Suite\Xilinx ISE Design Suite_14.7_1015_1.iso`
- ISE успешно установлен в `/opt/Xilinx/14.7/ISE_DS/`
- Лицензия скопирована из `N:\Xilinx\ISE Design Suite\Activation\xilinx_ise.lic`
- Переменные окружения настроены в `~/.bashrc`

### 5. ✅ Первая успешная компиляция

- Проект `av_blink.v` (мигание светодиодов) успешно скомпилирован
- Синтез (XST): ✅ Завершен без ошибок
- MAP: ✅ Завершен без ошибок
- Place & Route (PAR): ✅ Завершен без ошибок
- Генерация битфайла: ✅ Создан `pl_blink.bit` (801KB)
- Использовано ресурсов: 26 регистров, 58 LUT (менее 1% чипа)

### 6. 📋 Workflow

1. **Разработка**: VS Code Remote-WSL в Ubuntu
2. **Синтез**: ISE в WSL с WSLg GUI
3. **Файлы**: Общая папка `~/spartan6` ↔ Windows
4. **Программирование**: OpenOCD в Windows

## Рабочие файлы:

- `quick_test.cfg` - конфигурация OpenOCD для USB Blaster + Spartan 6
- `~/spartan6` - символическая ссылка на проекты
- `/mnt/ise_iso/` - смонтированный ISO ISE

## Команды для справки:

```bash
# Проверка USB Blaster
.\openocd-0.12.0\bin\openocd.exe -f quick_test.cfg -c "init; shutdown"

# Переход в проект
wsl cd ~/spartan6

# Установка ISE
wsl sudo /mnt/ise_iso/xsetup
```

## Статус: ✅ Полная среда разработки готова! ISE установлен, первый проект скомпилирован, битфайл создан
