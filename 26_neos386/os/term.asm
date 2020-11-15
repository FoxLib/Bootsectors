; Инициализация экрана на определенном кеше
; ----------------------------------------------------------------------
term_init:

        push    [dynamic]
        pop     [term.cache]
        add     [dynamic], 4096     ; Выделение памяти для экрана 80x25
        ret

; Очистка экрана от мусора, AL=$07
; ----------------------------------------------------------------------

term_cls:

        mov     edi, [term.cache]
        mov     ebx, $b8000
        mov     ecx, 2000
        xchg    ah, al
        mov     al, 0x20
@@:     mov     [ebx], ax
        stosw
        inc     ebx
        inc     ebx
        loop    @b
        mov     [term.x], 0
        mov     [term.y], 0
        call    term_set_cursor
        ret

; Установка курсора в позицию (BH, BL)
; ----------------------------------------------------------------------
term_set_cursor:

        mov     al, [term.y]
        mov     ah, 80
        mul     ah             ; ax = bh * 80
        add     al, [term.x]
        adc     ah, 0          ; ax = 80*bh + bl
        mov     bx, ax
        mov     al, 0x0f
        mov     dx, 0x3d4
        out     dx, al
        mov     al, bl
        inc     dx
        out     dx, al         ; Установить LO байт
        dec     dx
        mov     al, 0x0e
        out     dx, al
        mov     al, bh
        inc     dx
        out     dx, al         ; Установить HI байт
        ret

; Скроллинг вверх символов
; ----------------------------------------------------------------------
term_scroll_up:

        cld

        ; Поднятие символов
        mov     esi, [term.cache]
        mov     edi, esi
        lea     esi, [edi + 160]
        mov     ecx, 1920
        rep     movsw

        ; Заполнение последней строки
        mov     ah, [edi + 1]
        mov     al, ' '
        mov     ecx, 80
        rep     stosw

        ; Перемещение из кеша в видимую область
        mov     esi, [term.cache]
        mov     edi, $b8000
        mov     ecx, 2000
        rep     movsw
        ret

; Печать 1 символа (AL)
; ----------------------------------------------------------------------
term_outchar:

        push    eax ebx ecx edx esi edi

        ; Если пришел символ ENTER
        cmp     al, 10
        je      .newline

        ; Вычисление и выдача в текстовый видеобуфер
        push    eax
        mov     al, [term.y]
        and     eax, $ff
        mov     ebx, 80
        mul     ebx
        mov     bl, [term.x]
        and     ebx, $ff
        lea     edi, [eax + ebx]
        add     edi, edi
        pop     eax

        ; Вывод символа
        and     edi, $FFF                   ; Ограничение
        mov     edx, [term.cache]           ; Где именно находится этот кеш?
        mov     byte [edi + edx], al        ; Запись в кеш
        mov     byte [edi + $b8000], al     ; Запись в видеопамять

        ; Переход к следующему символу
        inc     [term.x]
        cmp     [term.x], byte 80
        jne     .xno

.newline:

        ; Переход к следующей строке
        mov     [term.x], byte 0
        inc     [term.y]
        cmp     [term.y], byte 25
        jne     .xno

        ; Скроллинг вверх
        mov     [term.y], byte 24
        call    term_scroll_up

.xno:   ;
        call    term_set_cursor
        pop     edi esi edx ecx ebx eax
        ret

; Печать строки в телетайп режиме из DS:ESI
; ----------------------------------------------------------------------

term_print:

        lodsb
        and     al, al
        je      .exit
        call    term_outchar
        jmp     term_print
.exit:  ret
