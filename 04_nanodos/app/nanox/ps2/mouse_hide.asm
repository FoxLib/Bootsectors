; Отключение прерывания мыши на время выполнения длинного CLI
PS2Mouse.Disable:

        push    ax
        in      al, 0A1h
        or      al, 10h
        out     0A1h, al
        cli
        pop     ax
        ret        

; Восстановление области за курсором мыши
; Прорисовка 4-х битного цвета в позиции [PS2Mouse.x/y]
PS2Mouse.Hide:
  
        mov     si, [PS2Mouse.CursorA]
        mov     di, [PS2Mouse.y]        
        mov     ch, 21
.ly:    mov     cl, 6 
        mov     bp, [PS2Mouse.x]
.lx:    lodsb
        push    si
        mov     si, bp
        mov     bl, al
        shr     al, 4        
        call    [SetPixel]
        inc     si
        mov     al, bl
        and     al, 0Fh
        call    [SetPixel]
        inc     si
        mov     bp, si
        pop     si
        dec     cl
        jne     .lx
        inc     di
        dec     ch
        jne     .ly
        ret
