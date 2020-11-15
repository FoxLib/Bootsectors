
; ----------------------------------------------------------------------
; Прочитать одну из частей директории в dos.filename и нормализовать        
; @return  ds:si - следующая часть
;          al    - последний сканированный символ
; ----------------------------------------------------------------------

dos.routines.FetchDirPart:

        mov     di, dos.filename 
        
        ; Заполнить пробелами
        mov     eax, 0x20202020
        mov     [cs: di], eax
        mov     [cs: di+4], eax
        mov     [cs: di+7], eax

        mov     ah, 0
        
.charloop:

        lodsb
        cmp     ax, 0020h       ; Лидирующие пробелы удалить
        je      .charloop

        ; Завершение строк
        cmp     al, 0x5C        ; Символ '\'
        je      .end
        cmp     al, '/'
        je      .end
        cmp     al, 0
        je      .end

        ; Больше символов нельзя писать
        inc     ah
        cmp     ah, 12          
        je      .end

        ; STRTOUPPER
        cmp     al, 'a'
        jb      @f
        cmp     al, 'z'
        jnb     @f
        sub     al, 20h
        
        ; Если это расширение: заполнить пробелами и перейти к позиции 8
@@:     cmp     al, '.'
        jne     .insert_symb

        dec     ah
@@:     cmp     ah, 8
        jnb     .charloop  
        mov     [cs: di], byte ' '
        inc     di
        inc     ah
        jmp     @b

.insert_symb:

        ; Вписать новый символ
@@:     mov     [cs: di], al
        inc     di
        jmp     .charloop

.end:   ; Формирование строки закончено
        mov     al, [si - 1]
        ret
