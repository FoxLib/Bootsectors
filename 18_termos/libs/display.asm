; -------------------------------------------
; Освободить предпоследнюю строку (сдвинуть)
; -------------------------------------------

print_blank_line:

        push si ds

        push es
        pop  ds                

        ; Поднять все строки на 1 вверх
        mov  si, 2*SCREEN_WIDTH
        mov  di, 0
        mov  cx, (SCREEN_WIDTH * (SCREEN_HEIGHT - 2))
        rep  movsw

        ; Очистить основную выводящую строку
        mov  cx, SCREEN_WIDTH
        mov  ax, 0x0700
        rep  stosw

        ; Сбросить позицию курсора
        pop  ds si

        mov  [cursor], byte 0
        call require_cursor
        ret

; -------------------------------------------
; Процедура вывода свободной памяти (по сути является программой free)
; -------------------------------------------

proc_print_free_memory:

        call print_blank_line    ; Освободить место под новую строку
        call calc_free_memory    ; Подсчет свободной памяти на диске
        mov  ax, dx
        call itoa                ; Перевести в число
        call print_int           ; Напечатать число
        mov  si, sz_bytes_free
        call print_sz            ; Вывести строку " bytes free"
        ret

; -------------------------------------------
; Печать строки, оканчивающейся на 0 (ds:si)
; -------------------------------------------

print_sz:

        call require_cursor
@@:     lodsb
        and al, al
        je .r
        cmp al, 10
        jne .s
        call print_blank_line
        jmp @b

.s:     stosw
        inc word [cursor]
        jmp @b
.r:     ret

; -------------------------------------------
; Запросить позицию курсора DI и цвет AH 
; -------------------------------------------

require_cursor:

        mov ah, [pcolor]
        mov di, [cursor]
        add di, di
        add di, SCREEN_WIDTH*2*(SCREEN_HEIGHT - 2)
        ret

; -----------------------------------------
; Печать строки для INT
; -----------------------------------------

print_int:

        call require_cursor
        mov si, nmeric      ; Источник данных
        mov cl, 8
@@:     lodsb
        cmp al, '0'         
        loopz @b            ; Выход из цикла либо пока al='0', либо если cx = 0
@@:     stosw               ; Пропечатать символ, который первый (либо последний)
        inc word [cursor]
        and cl, cl          ; Если у нас только 1 символ ("0-9"), то печатать его, и выйти
        je @f
        lodsb
        loop @b
        stosw
        inc word [cursor]
@@:     ret

; -------------------------------------------
; Вывод на экран линии консоли
; -------------------------------------------

print_console_line:

        mov si, con            ; Откуда будут браться данные для консоли
        mov di, (2*SCREEN_WIDTH*(SCREEN_HEIGHT - 1)) ; Позиционирование зависит от выбранного экрана
        mov ah, 0x07           ; Цвет
        mov cl, 0x00           ; Счетчик = 0
.r:     lodsb                  ; Прочесть символ
        cmp cl, [con_ps]       ; Сравнить позицию курсора
        jne @f                 ; Если мы не в позиции курсора, пропуск
        mov al, 0xB2           ; Иначе печатаем курсор
@@:     stosw                  ; Печать либо символа, либо курсора
        inc cl                 ; Сместить печатаемый символ
        cmp cl, 80             ; Проверить окончание печати
        jne .r                 ; Пока не закончился буфер очереди,
        ret                    ; выход
