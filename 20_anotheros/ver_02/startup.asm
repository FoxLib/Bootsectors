[BITS 32]

; ----------------------------------------------------------------------
[EXTERN main]
[EXTERN pic_timer]          ; IRQ 0
[EXTERN pic_keyboard]       ; IRQ 1
[EXTERN pic_fdc]            ; IRQ 6
[EXTERN pic_ps2mouse]       ; IRQ C
; ----------------------------------------------------------------------

[GLOBAL _start]

[GLOBAL INT_null]
[GLOBAL IRQ_timer]
[GLOBAL IRQ_keyboard]
[GLOBAL IRQ_ps2mouse]
[GLOBAL IRQ_cascade]
[GLOBAL IRQ_master]
[GLOBAL IRQ_slave]
[GLOBAL IRQ_fdc]
[GLOBAL delay]

; ----------------------------------------------------------------------
_start: 

        ; Выделяется 512 кб под стек
        mov     esp, 0x180000
        jmp     main

; ----------------------------------------------------------------------
delay:  push    ecx
        mov     ecx, 32
dely:   loop    dely
        pop     ecx
        ret

; ----------------------------------------------------------------------
; ПРЕРЫВАНИЯ

INT_null:

        xchg    bx, bx
        jmp     INT_null
        iretd

IRQ_master:

        xchg    bx, bx
        pushad
        mov     al, 0x20
        out     0x20, al
        popad
        iretd
        
IRQ_slave:

        xchg    bx, bx
        pushad
        mov     al, 0x20
        out     0xA0, al
        out     0x20, al
        popad
        iretd

; Обработчик клавиатуры
; ----------------------------------------------------------------------

IRQ_timer:

        pushad
        call    pic_timer
        mov     al, 20h
        out     20h, al
        popad
        iretd

IRQ_keyboard:

        pushad
        call    pic_keyboard
        mov     al, 20h
        out     20h, al
        popad
        iretd

IRQ_fdc:

        pushad
        call    pic_fdc
        mov     al, 20h
        out     20h, al
        popad
        iretd

; Прерывание со slave
; ----------------------------------------------------------------------

IRQ_cascade:

        xchg bx, bx
        pushad
        ; ..
        mov     al, 20h
        out     20h, al
        popad
        iretd

; Прерывание от мыши
; ----------------------------------------------------------------------

IRQ_ps2mouse:

        pushad
        
        call    pic_ps2mouse
        
        mov     al, 0x20
        out     0xA0, al
        out     0x20, al
        popad
        iretd
