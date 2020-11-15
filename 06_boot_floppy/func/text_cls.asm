; Очистка экрана в серую область

text.cls:

        mov     ax, 0003h
        int     10h            
        mov     ax, 0xB800
        mov     es, ax
        mov     cx, 2000
        mov     ax, 7020h
        xor     di, di
        rep     stosw
        ret
