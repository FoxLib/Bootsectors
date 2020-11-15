
; Заглушки Exception / Interrupt
; --------------------------------------------------------------------------------

exception: ; Любое исключение

    brk
    
    iretq    

; ---------------------------------------------
interrupt: ; Любое прерывание

    ;brk
    iretq

cascade: ; Каскад с 2-го PIC

    push rax
    mov al, 0x20
    out 0x20, al
    pop rax
    iretq
