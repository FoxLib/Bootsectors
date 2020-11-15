;
; Печать строки на экране, оканчивающейся на $
; ds:si Источник
; ----------------------------------------------------------------------

dos.io.PrintZ:

        push    ax bx si
        mov     ah, 0Eh
        mov     bh, 00h
@@:     lodsb
        cmp     al, '$'
        je      .exit
        and     al, al
        je      .exit        
        int     10h
        jmp     @b
.exit:  pop     si bx ax
        ret
        
; Печать 8/16/32-битного числа #0000
; ----------------------------------------------------------------------

dos.io.Print16:

        ret
        
; Информационный вывод найденных дисков
; ----------------------------------------------------------------------

dos.io.PrintFoundFAT:

        mov     bp, dos.param.fs_block
        mov     cx, [dos.param.num_fs_detected]
        and     cx, cx
        je      .exit
        
.fs_loop:

        push    cx
        mov     si, dos.io.msg_drv
        call    dos.io.PrintZ
        
        ; Пропечатать найденные файловые системы        
        mov     ax, [fs: bp + fs.dw.filetype]
        mov     si, dos.io.msg_fat12
        cmp     ax, 12
        je      @f
        mov     si, dos.io.msg_fat16
        cmp     ax, 16
        je      @f
        mov     si, dos.io.msg_fat32
@@:     call    dos.io.PrintZ
        
        ; Количество мегабайт
        mov     eax, [fs: bp + fs.dd.size]
        shr     eax, 11
        call    util.itoa
        call    dos.io.PrintZ
        
        ; Надпись "MB"
        mov     si, dos.io.msg_mb
        call    dos.io.PrintZ
        add     bp, 32
        inc     byte [dos.io.msg_drv + 9]       ; Смена буквы диска
        pop     cx
        loop    .fs_loop
        
.exit:  ret


; Некая огромная фатальная ошибка
; ds:si - информация об ошибке
; ----------------------------------------------------------------------

dos.io.Panic:

        
        jmp     $
