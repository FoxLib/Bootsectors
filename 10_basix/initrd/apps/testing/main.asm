;
; Тестировочный файл
; На входе RAW-файлов не существует DATA-секции
; эта секци создается по мере обращений
;

        use32
        macro   brk { xchg bx, bx}

        brk
        mov     eax, 40
        push    eax
        pop     ebx
        jmp     $
        
