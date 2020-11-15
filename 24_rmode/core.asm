
        org     $7E00
        macro   brk { xchg bx, bx }

        brk
        
        ; Ввод с командной строки
        ; Редактирование сектора, E <id> <num>
        ; - Чтение с сектора
        ; - Запись сектора
        ; Запуск R <id> <num>

@@:     xor     ax, ax
        int     16h
        mov     ah, 0Eh
        int     10h
        jmp     @b
