
        org     0x8000
        include "macro.asm"

        cli
        cld
        xor     ax, ax
        xor     sp, sp
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     sp, $8000
; ----------------------------------------------------------------------
; Вход в нереальный режим без CS: https://wiki.osdev.org/Unreal_Mode
; ----------------------------------------------------------------------
        push    ds es               ; save real mode
        lgdt    [gdtidx]            ; load gdt register
        mov     eax, cr0            ; switch to pmode by
        or      al, 1               ; set pmode bit
        mov     cr0, eax
        jmp     $+2                 ; tell 386/486 to not crash
        mov     bx, 0x08            ; select descriptor 1
        mov     ds, bx
        mov     es, bx
        and     al, 0xFE            ; back to realmode
        mov     cr0, eax            ; by toggling bit again
        jmp     gdtend              ; tell 386/486 to not crash
gdtidx: dw      gdtend - gdt - 1    ; last byte in table
        dd      gdt                 ; start of table
gdt     dd      0, 0                ; entry 0 is always unused
        db      0xFF, 0xFF, 0x00, 0x00, 0x00, 0x92, 0xCF, 0x00
gdtend: pop     es ds               ; get back old segment
; ----------------------------------------------------------------------
        sti
        mov     bx,     0x0f02
        mov     eax,    0x0b8000
        mov     word    [es: eax], bx
        jmp     $




