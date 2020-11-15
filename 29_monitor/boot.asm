        macro   brk { xchg bx, bx }
        org     7C00h

        cld
        sti

        xor     ax, ax
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     sp, 7C00h

        ; --
        xor     ax, ax
@@:     mov     bx, ax
        xor     al, ah
        lahf
        test    ah, 0x10
        mov     ax, bx
        jnz     @f
        ; --
        inc     ax
        jnz     @b
        mov     si, ac
        jmp     @f

        mov     si, ab
@@:     mov     ah, 0Eh
        lodsb
        and     al, al
        je      $
        int     10h
        jmp     @b

ab:     db "Hello World",0
ac:     db "Drilling",0
