; 4-х цветный курсор мыши
; 00 Прозрачный
; 01 Серый
; 10 Белый
; 11 Черный

PS2Mouse.Cursor:

        db 11000000b, 00000000b, 00000000b
        db 11110000b, 00000000b, 00000000b
        db 11011100b, 00000000b, 00000000b
        db 11100111b, 00000000b, 00000000b
        db 11101001b, 11000000b, 00000000b
        db 11101010b, 01110000b, 00000000b
        db 11101010b, 10011100b, 00000000b
        db 11101010b, 10100111b, 00000000b
        db 11101010b, 10101001b, 11000000b
        db 11101010b, 10101010b, 01110000b
        db 11101010b, 10101010b, 10011100b
        db 11101010b, 10101011b, 11111111b
        db 11101010b, 11101011b, 00000000b
        db 11101011b, 11101011b, 00000000b
        db 11101100b, 00111010b, 11000000b
        db 11110000b, 00111010b, 11000000b
        db 11000000b, 00001110b, 10110000b
        db 00000000b, 00001110b, 10110000b
        db 00000000b, 00000011b, 10101100b
        db 00000000b, 00000011b, 10101100b
        db 00000000b, 00000000b, 11110000b

; Нарисовать курсор
; ----------------------------------------------------------------------

PS2Mouse.loc.show.x dw 0
PS2Mouse.loc.show.y dw 0

PS2Mouse.Show:

        ; Сохранить область за курсором
        mov     di, [PS2Mouse.CursorA]
        mov     [PS2Mouse.loc.show.y], 21
        mov     dx, [PS2Mouse.y]    ; y
.ly:    mov     cx, [PS2Mouse.x]    ; x
        mov     bh, 12
.lx:    call    [GetPixel]
        inc     cx
        shl     al, 4
        mov     bl, al
        call    [GetPixel]
        inc     cx
        and     al, 0Fh
        or      al, bl
        stosb               ; Старший ниббл - левая точка
        sub     bh, 2
        jne     .lx
        inc     dx
        dec     [PS2Mouse.loc.show.y]
        jne     .ly

        ; Вывести курсор (с учетом прозрачности)
        mov     si, PS2Mouse.Cursor
        mov     ax, [PS2Mouse.y]
        mov     [PS2Mouse.loc.show.y], ax
        mov     dl, 21

.cursor_y:

        mov     ch, 3
        mov     ax, [PS2Mouse.x]
        mov     [PS2Mouse.loc.show.x], ax

.cursor_x3:

        lodsb
        mov     bl, al
        mov     cl, 4
        push    si

.cursor_x:

        rol     bl, 2
        mov     al, bl
        and     al, 3
        cmp     al, 0
        je      .skip_pixel
        mov     ah, 00h
        cmp     al, 3
        je      @f
        mov     ah, 7
        cmp     al, 1
        je      @f
        mov     ah, 0Fh
@@:     mov     al, ah
        mov     si, [PS2Mouse.loc.show.x]
        mov     di, [PS2Mouse.loc.show.y]
        call    [SetPixel]

.skip_pixel:

        inc     [PS2Mouse.loc.show.x]
        dec     cl
        jne     .cursor_x

        pop     si
        dec     ch
        jne     .cursor_x3

        inc     [PS2Mouse.loc.show.y]
        dec     dl
        jne     .cursor_y
        ret

; Отключение прерывания мыши на время выполнения длинного CLI
PS2Mouse.Enable:

        push    ax
        in      al, 0A1h
        and     al, 0EFh
        out     0A1h, al
        pop     ax
        sti
        ret
