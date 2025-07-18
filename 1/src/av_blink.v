`timescale 1ns / 1ps

// Определяем стандартный блок-модуль (как класс в С++)
module pl_blink(input CLK25,  // 25 МГц тактовая частота
    output d6_led, 
    output gren_led, 
    output blue_led, 
    output fpga_led, //FPGA_LED согластно схеме
    output debug_pin //Пин H16 на DEBUGPORT1
    );
    
// Задаем регистр для хранения записи о текущем состоянии светодиода
reg r_led;
reg g_led;
reg b_led;  

/*Регистры для FPGA_LED и H16*/
reg fpgaLed; 
reg dbgPin; 

// Задаем регистр для хранения значения счётчика, использующегося в задержке
reg [31:0] counter;

// Тут мы задаем действия которые должны быть выполнены при старте программы
initial begin
    /*Инициализация значений*/
    counter <= 32'b0;  //  Обнуляем счётчик  
    r_led <= 1'b0;    //  Делаем запись о состоянии светодиода
    b_led <= 1'b1;    
    g_led <= 1'b1;   
    fpgaLed <= 1'b1;  
    dbgPin <= 1'b0; 
end

// Тут описываем поведенческий блок, который будет реагировать на положительный фронт тактовой частоты
always@(posedge CLK25)
begin
    counter <= counter + 1'b1;  // Увеличиваем счетчик
    
    if(counter > 6000000)    // Если счетчик больше 6М (25МГц ? 6М = 4.16 Гц)
    begin
        r_led <= !r_led;      // Инвертируем запись о значении состоянии светодиода
        fpgaLed <= !fpgaLed;  //Мигаем зеленым светодиодом на плате
        dbgPin <= !dbgPin;    //Попутно меняем сигнал на DEBUGPORT1 H16
        counter <= 32'b0;     // Сбрасываем счетчик
    end   
    
end

/*Присваиваем выход к регистру управления*/
assign d6_led = r_led;         
assign gren_led = g_led;      
assign blue_led = b_led;      
assign fpga_led = fpgaLed;             
assign debug_pin = dbgPin;       
endmodule