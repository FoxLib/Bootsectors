
Main_Application:

    ; Установка VGA-видеорежима 640 x 480 x 16
    mov ax, 0x0012
    int 0x30

    ; тестовое рисование
    invk5 VGA_rectangle, 0, 0, 639, 479, 8
    invk5 VGA_rectangle, 300, 32, 320, 120, 7
    
    ; Включение прерываний
    sti
       
    ; бесконечный цикл
TC: jmp TC