
        org     0x8000
        include "inc/macro.asm"

        ; Инициализация
        xor     ax, ax
        xor     sp, sp
        mov     ds, ax
        mov     ss, ax
        mov     ax, $b800
        mov     es, ax

        invoke  cls,$0720
        invoke  locate,2,49
        invoke  printf,h

@@:     call    getch
        call    print
        jmp     @b

h:      db "Core decompressing initializing procedure...", 0

        include "inc/stdio.asm"
        include "inc/keyboard.asm"
