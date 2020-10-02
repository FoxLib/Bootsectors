        macro   brk { xchg bx, bx }
        org     7C00h

        cld
        sti

        xor     ax, ax
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     sp, 7C00h

        mov     si, ab
@@:     mov     ah, 0Eh
        lodsb
        and     al, al
        je      $
        int     10h
        jmp     @b

ab:     db "Hello World",0
