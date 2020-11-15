; Рисование фрейма (AH,AL)-(BH,BL)

text.frame:

        ; (AH,AL) -> y1,x1
        mov     cl, ah
        mov     ch, 0
        mov     [.loc_y1], cx
        cbw
        mov     [.loc_x1], ax

        ; (BH,BL) -> y1,x1
        xchg    ax, bx
        mov     cl, ah
        mov     ch, 0
        mov     [.loc_y2], cx
        cbw
        mov     [.loc_x2], ax

        ; Верх
        mov     dx, [.loc_y1]
        mov     [.loc_cc], 0xDABFC4
        call    .border

        ; Середина
@@:     inc     dx
        cmp     dx, [.loc_y2]
        jnb     @f
        mov     [.loc_cc], 0xB3B300
        call    .border        
        jmp     @b
            
        ; Низ
@@:     mov     dx, [.loc_y2]
        mov     [.loc_cc], 0xC0D9C4
        call    .border    
        ret   

.put:   ; cx - x, dx - y, al - symbol
        and     al, al
        je      @f
        imul    di, dx, 80
        add     di, cx
        add     di, di
        mov     [es: di], al
@@:     ret

.border: ; Рисование черты (верхней или нижней)

        mov     cx, [.loc_x1]
        mov     bx, [.loc_x2]
.loop1: cmp     cx, bx
        ja      .done
        mov     al, byte [.loc_cc + 2]
        cmp     cx, [.loc_x1]
        je      @f
        mov     al, byte [.loc_cc + 1]
        cmp     cx, bx
        je      @f
        mov     al, byte [.loc_cc]   
@@:     call    .put    
        inc     cx
        jmp     .loop1        
.done:  ret

.loc_x1 dw 0
.loc_y1 dw 0
.loc_x2 dw 0
.loc_y2 dw 0
.loc_cc dd 0xDABFC4
