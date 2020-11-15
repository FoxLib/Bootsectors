; Печать текста на экране

text.print:
        
        ; di = 2*(80*ah + al)
        push    ax cx
        mov     cl, ah
        mov     ch, 0
        cbw
        imul    di, cx, 80
        add     di, ax
        add     di, di
@@:     lodsb
        and     al, al
        je      @f
        stosb
        inc     di
        jmp     @b        
@@:     pop     cx ax
        ret        
