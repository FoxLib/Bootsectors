; ------
; Таймер занимается только подсчетом "тиков" в миллисекундах
; -----

clock_time dq 0

; -----
clock:

    push rax
    inc [clock_time] ; +1 миллисекунда    
    mov  al, 20h
    out  20h, al  ; Отсылка эхо на PIC-master
    pop  rax
    iretq
