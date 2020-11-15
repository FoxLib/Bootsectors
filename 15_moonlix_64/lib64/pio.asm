interrupt_redirect:

    mov        al, 10001b               ; begin PIC 1 initialization
    out        20h, al

    mov        al, 10001b               ; begin PIC 2 initialization
    out        0A0h, al

    ; ---
    mov        al, 20h                  ; IRQ 0-7: прерыванния 20h-27h
    out        21h, al

    mov        al, 28h                  ; IRQ 8-15: прерывания 28h-2Fh
    out        0A1h, al

    ; ---
    mov        al, 100b                 ; Ведомый контроллер подключен к IRQ2
    out        21h, al
    
    mov        al, 2
    out        0A1h, al

    ; ---
    mov        al, 1                    ; Intel environment, manual EOI
    out        21h, al
    out        0A1h, al

    mov        al, 0xFF
    out        21h, al
    out        0A1h, al
    
    in         al, 21h
    mov        al, 11111000b            ; Включить только таймер, клавиатуру и мышь | и включить каскад
    out        21h,al

    in         al, 0A1h
    mov        al, 11101111b
    out        0A1h, al

    ret
