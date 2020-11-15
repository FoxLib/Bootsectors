
        use16

        org     $8000
        macro   brk { xchg bx, bx }

        ; --------------------------------------
        ; Вход в защищенный режим
        ; --------------------------------------

        include "core/enter_protected_mode.asm"

        ; --------------------------------------
        ; Транзит из 32-х бит в 16 бит из PM
        ; --------------------------------------

prot_mode_transit:

        cli     ; Отключить тут прерывания

        xor     ax, ax
        mov     fs, ax
        mov     gs, ax

        mov     eax, cr0
        and     al, $fe
        mov     cr0, eax
        jmp     $0000 : real_mode_entry

        ; --------------------------------------
        ; Выход из PM в RealMode
        ; --------------------------------------

real_mode_entry:

        ; ... Выполнение инструкции ....

        mov     eax, cr0
        or      al, 1
        mov     cr0, eax
        jmp     $0008 : finalize_16bit_routine

        use32

        ; --------------------------------------
        ; Функции защищенного режима
        ; --------------------------------------

        include "core/pic_irq_redirect.asm"
        include "core/interrupts.asm"
        include "core/paging.asm"
        include "core/rmpm.asm"

        ; --------------------------------------
        ; Выход из процедуры RM в PM
        ; --------------------------------------

finalize_16bit_routine:

        ; ...

        ; --------------------------
        ; Защищенный режим
        ; --------------------------

protected_mode_entry:

        ; Инициализация сегментов и многозадачности
        mov     ax, $10
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        xor     ax, ax
        mov     fs, ax
        mov     gs, ax
        mov     ax, $18
        mov     esp, $8000
        ltr     ax

brk

        ;mov     bx, 1110111111111000b
        call    save_rmidt
        mov     bx, 1111111111111111b ; PS/2, Keyb, Timer, IRQ#2
        call    pic_irq_redirect
        call    pic_irq_set_timer
        call    make_interrupt_list
        call    save_pmidt
        
        brk
        call    paging_make
        
        ; jmp     $0020 : prot_mode_transit

        jmp     $

; ----------------------------------------------------------------------
; Здесь находятся неинициализированные данные
; ----------------------------------------------------------------------

        include "core/sys_undefined_data.asm"
