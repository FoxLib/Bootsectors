; Прорисовать линию в AH,AL длина CL, фон CH

text.line:

        mov     dl, ah
        mov     dh, 0
        cbw
        imul    di, dx, 80
        add     di, ax
        add     di, di
                
        mov     al, ch
@@:     inc di
        stosb        
        
        dec     cl
        jne     @b
        ret
