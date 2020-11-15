
        org	    100h
        macro   brk { xchg bx, bx }

        mov     ah, 0Eh
        mov     si, Hello
@@:     lodsb
        and     al, al
        je      @f
        int     10h
        jmp     @b
@@:     retf

Hello   db "Welcome to Tiny 512 BootOS",10,13,0
