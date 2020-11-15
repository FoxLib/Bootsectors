[BITS 64]

[EXTERN main]
[EXTERN keyboard_isr]
[EXTERN timer_ticker]
[EXTERN ps2_handler]
[EXTERN fb_vesa]

; Для портов ввода-вывода
[EXTERN io_port]
[EXTERN io_addr]
[EXTERN io_count]

[GLOBAL _start]
[GLOBAL _irq_isr_null]
[GLOBAL isr_timer]
[GLOBAL isr_keyboard]
[GLOBAL isr_cascade]
[GLOBAL isr_ps2mouse]
[GLOBAL apic_disable]

[GLOBAL fbvesa_set]
[GLOBAL IoOutSW]
[GLOBAL IoInSW]

_start:

        mov     rsp, 0x0A0000
        call    main

; http://wiki.osdev.org/ISR
; -------------------------------------------------------------

; Поскольку компилятор Clang жестко тупит, пришлось сделать так
fbvesa_set:

        push    rax
        mov     rax, [0]
        mov     qword [fb_vesa], rax
        pop     rax
        ret

; outsw
IoOutSW:

        push    rcx
        push    rsi
        push    rdx
        mov     dx,  [io_port]
        mov     rsi, [io_addr]
        mov     rcx, [io_count]
        rep     outsw
        pop     rdx
        pop     rsi
        pop     rdx
        ret

; insw
IoInSW:

        push    rcx
        push    rdi
        push    rdx
        mov     dx,  [io_port]
        mov     rdi, [io_addr]
        mov     rcx, [io_count]
        rep     insw
        pop     rdx
        pop     rdi
        pop     rdx
        ret

; Нулевой обработчик ничего не делает вообще
_irq_isr_null:

        xchg bx, bx
        
        push    rax
        mov     al, 0x20
        out     0x20, al
        pop     rax

        ;out     0xA0, al

        iretq

; Каскад нужен для работы мыши
isr_cascade:

        push    rax
        mov     al, 0x20
        out     0xA0, al
        out     0x20, al
        pop     rax
        iretq
        
; Обработчик таймера
isr_timer:    

        push    rax 
        push    rbx
        push    rcx
        push    rdx
        push    rsi
        push    rdi
        push    rbp
        
        call    timer_ticker
        mov     al, 0x20
        out     0x20, al
        
        pop     rbp
        pop     rdi
        pop     rsi
        pop     rdx
        pop     rcx
        pop     rbx
        pop     rax 

        iretq

; Обработчик прерывания с клавиатуры
isr_keyboard:

        push    rax 
        push    rbx
        push    rcx
        push    rdx
        push    rsi
        push    rdi
        push    rbp
        
        call    keyboard_isr    
        mov     al, 0x20
        out     0x20, al
        
        pop     rbp
        pop     rdi
        pop     rsi
        pop     rdx
        pop     rcx
        pop     rbx
        pop     rax 
        iretq

isr_ps2mouse:
        
        push    rax 
        push    rbx
        push    rcx
        push    rdx
        call    ps2_handler
        mov     al, 0x20
        out     0xA0, al
        out     0x20, al
        pop     rdx
        pop     rcx
        pop     rbx
        pop     rax 
        iretq
        
; Отключение локального APIC    
apic_disable:

        mov ecx, 0x1b
        rdmsr
        and eax, 0xfffff7ff
        wrmsr
        ret

