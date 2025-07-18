# TCL script для создания и синтеза ISE проекта
# Spartan 6 LED Blink Project

# Создаем новый проект
project new av_blink.xise

# Настраиваем свойства проекта для Spartan 6
project set family "Spartan6"
project set device "xc6slx25"
project set package "ftg256"
project set speed "-3"
project set top_level_module_type "HDL"
project set synthesis_tool "XST (VHDL/Verilog)"
project set simulator "ISim (VHDL/Verilog)"

# Добавляем Verilog файл
xfile add "av_blink.v"

# Добавляем файл ограничений
xfile add "pinout.ucf"

# Устанавливаем top модуль
project set top "pl_blink"

# Сохраняем проект
project save

# Запускаем синтез
process run "Synthesize - XST"

# Если синтез прошел успешно, запускаем Implementation
if { [process get "Synthesize - XST" status] == "up_to_date" } {
    puts "Synthesis completed successfully"
    process run "Implement Design"
    
    # Если Implementation прошел успешно, генерируем битфайл
    if { [process get "Implement Design" status] == "up_to_date" } {
        puts "Implementation completed successfully"
        process run "Generate Programming File"
        
        if { [process get "Generate Programming File" status] == "up_to_date" } {
            puts "Bitfile generation completed successfully"
        }
    }
}

# Закрываем проект
project close

puts "Build process completed"
exit
