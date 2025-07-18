`timescale 1ns / 1ps

// ���������� ����������� ����-������ (��� ����� � �++)
module pl_blink(input CLK25,  // 25 ��� �������� �������
    output d6_led, 
    output gren_led, 
    output blue_led, 
    output fpga_led, //FPGA_LED ��������� �����
    output debug_pin //��� H16 �� DEBUGPORT1
    );
    
// ������ ������� ��� �������� ������ � ������� ��������� ����������
reg r_led;
reg g_led;
reg b_led;  

/*�������� ��� FPGA_LED � H16*/
reg fpgaLed; 
reg dbgPin; 

// ������ ������� ��� �������� �������� ��������, ��������������� � ��������
reg [31:0] counter;

// ��� �� ������ �������� ������� ������ ���� ��������� ��� ������ ���������
initial begin
    /*������������� ��������*/
    counter <= 32'b0;  //  �������� �������  
    r_led <= 1'b0;    //  ������ ������ � ��������� ����������
    b_led <= 1'b1;    
    g_led <= 1'b1;   
    fpgaLed <= 1'b1;  
    dbgPin <= 1'b0; 
end

// ��� ��������� ������������� ����, ������� ����� ����������� �� ������������� ����� �������� �������
always@(posedge CLK25)
begin
    counter <= counter + 1'b1;  // ����������� �������
    
    if(counter > 6000000)    // ���� ������� ������ 6� (25��� ? 6� = 4.16 ��)
    begin
        r_led <= !r_led;      // ����������� ������ � �������� ��������� ����������
        fpgaLed <= !fpgaLed;  //������ ������� ����������� �� �����
        dbgPin <= !dbgPin;    //������� ������ ������ �� DEBUGPORT1 H16
        counter <= 32'b0;     // ���������� �������
    end   
    
end

/*����������� ����� � �������� ����������*/
assign d6_led = r_led;         
assign gren_led = g_led;      
assign blue_led = b_led;      
assign fpga_led = fpgaLed;             
assign debug_pin = dbgPin;       
endmodule