[BITS 32]
[EXTERN __kernel]
[EXTERN dev_keyb_isr]
[EXTERN timer_ticker]
[EXTERN ps2_handler]
[GLOBAL _start]
[GLOBAL _irq_isr_null]
[GLOBAL isr_timer]
[GLOBAL isr_keyboard]
[GLOBAL isr_cascade]
[GLOBAL isr_ps2mouse]
[GLOBAL apic_disable]

_start:

    mov     esp, 0x09FFFC
    call    __kernel

; http://wiki.osdev.org/ISR
; -------------------------------------------------------------

; Нулевой обработчик ничего не делает вообще
_irq_isr_null:
    
    iretd

; Каскад нужен для работы мыши
isr_cascade:

    push    ax
    mov     al, 0x20
    out     0xA0, al
    out     0x20, al
    pop     ax
    iretd
    
; Обработчик таймера
isr_timer:    

    pushad
    call    timer_ticker
    mov     al, 0x20
    out     0x20, al
    popad
    iretd

; Обработчик прерывания с клавиатуры
isr_keyboard:
    
    pushad
    call    dev_keyb_isr    
    mov     al, 0x20
    out     0x20, al
    popad
    iretd

isr_ps2mouse:
    
    pushad
    call    ps2_handler
    mov     al, 0x20
    out     0xA0, al
    out     0x20, al
    popad
    iretd
    
; Отключение локального APIC    
apic_disable:

    mov ecx, 0x1b
    rdmsr
    and eax, 0xfffff7ff
    wrmsr
    ret

