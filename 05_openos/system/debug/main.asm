; ah(цвет) al - хекс, bx - куда писать

dbg_print_hex:

        push ecx eax
        mov  cl, al
        mov  ch, al

        ; Первый ниббл
        shr  cl, 4
        cmp  cl, 10
        jb @f
        add  cl, 7
@@:     mov  al, cl      
        add  al, '0'
        call put_char_low

        ; Второй ниббл
        mov  al, ch
        and  al, 0x0F
        cmp  al, 10
        jb @f
        add  al, 7
@@:     add  al, '0'        
        call put_char_low
        pop  eax ecx 
        ret