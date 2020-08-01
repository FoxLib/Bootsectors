[BITS 32]

[EXTERN main]
[EXTERN pic_keyboard]
[EXTERN fdc_irq]
[EXTERN ps2_mouse_handler]

[GLOBAL _start]
[GLOBAL INT_null]
[GLOBAL IRQ_fdc]
[GLOBAL IRQ_master]
[GLOBAL IRQ_slave]
[GLOBAL IRQ_keyboard]
[GLOBAL IRQ_ps2]
[GLOBAL enable_A20]

_start:

        jmp     main

INT_null:

        iretd

IRQ_master:

        push    eax
        mov     al, 0x20  ; EOI
        out     0x20, al  ; PIC1
        pop     eax
        iretd

IRQ_slave:

        push    eax
        mov     al, 0x20  ; EOI
        out     0x20, al  ; PIC1
        out     0xA0, al  ; PIC2
        pop     eax
        iretd

; ----------------------------------------------------------------------
; IRQ #1 Keyboard
; ----------------------------------------------------------------------

IRQ_keyboard:

        pushad
        call    pic_keyboard
        mov     al, 0x20
        out     0x20, al
        popad
        iretd

; ----------------------------------------------------------------------
; IRQ #6 Floppy Disk Controller (FDC)
; ----------------------------------------------------------------------

IRQ_fdc:

        pushad
        call    fdc_irq
        mov     al, 0x20
        out     0x20, al
        popad
        iretd

; ----------------------------------------------------------------------
; IRQ #C PS2
; ----------------------------------------------------------------------

IRQ_ps2:

        pushad
        call    ps2_mouse_handler
        mov     al, 0x20
        out     0x20, al
        out     0xA0, al
        popad
        iretd
