 
        org     $7C00
        macro   brk { xchg bx, bx }

        brk

        cli
        mov     ax, $0003
        int     10h
        xor     ax, ax
        mov     es, ax
        mov     ds, ax
        mov     ss, ax
        mov     sp, $7C00
        mov     ax, 0208h
        mov     dh, 00h
        mov     cx, 00002h
        mov     bx, $800        ; Сразу после BDA
        int     13h
        jnc     $0800
        mov     si, error_message
error:  lodsb
        cmp     al, 0
@@:     je      @b
        mov     ah, 0Eh
        int     10h
        jmp     error

error_message db "Can't boot",0