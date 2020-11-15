; ----------------------------------------------------------------------
; Эта секция DOS. Здесь могут проводиться различные инсталляции.
; DL - Drive Letter
; ----------------------------------------------------------------------

        org     10h
        include "dos/defines.asm"        

        ; Переместить код в HMA
        cli
        cld    
        mov     ax, 0800h
        mov     ds, ax
        xor     ax, ax
        dec     ax
        mov     es, ax
        mov     ss, ax
        mov     sp, 0
        mov     cx, 7FF8h   ; 65520 байт
        mov     si, 0000h
        mov     di, 0010h
        rep     movsw
        jmp     0xFFFF : himem
        
himem:  mov     ax, 0003h
        int     10h

        mov     ax, es
        mov     ds, ax
        mov     [dos.param.drive_letter], dl
        xor     ax, ax
        mov     fs, ax
        mov     gs, ax
        
        ; Для работы с PM
        lgdt    [cs: GDTR]

        ; Назначить прерывания 20h / 21h
        mov     [fs: 20h*4 + 0], word dos.int20h
        mov     [fs: 20h*4 + 2], cs
        mov     [fs: 21h*4 + 0], word dos.int21h
        mov     [fs: 21h*4 + 2], cs        
        sti

        ; Очистка всех дескрипторов файлов
        mov     bx, dos.param.files
@@:     mov     [fs: bx], word 0
        add     bx, 2
        cmp     bx, dos.param.files_top
        jne     @b

        ; Выдать строку приветствия
        mov     si, dos.messages.welcome
        call    dos.io.PrintZ

        ; Поиск файловых систем
        call    dev.disk.Init
        call    dev.disk.SearchFat
        call    dos.io.PrintFoundFAT
        call    dos.routines.SetRootCluster

        ; Установить главный текущий каталог
        mov     eax, [dos.param.current_dir]
        mov     [cs: dos.param.dir], eax

        ; Запустить операционную систему NanoX
        mov     ah, 4Bh
        mov     dx, run
        int     21h

        ; ... RESTART COMPUTER ...
        jmp     $       
        
; ----------------------------------------------------------------------
; Для работы в PM
; https://ru.wikipedia.org/wiki/Дескриптор_сегмента
; ----------------------------------------------------------------------

GDTR:   ; Регистр глобальной дескрипторной таблицы
        dw 3*8 - 1              ; Лимит GDT (размер - 1)
        dd GDT + 100000h - 10h  ; Линейный адрес GDT

; Дескрипторная таблица
GDT:    dw 0,      0,     0,     0      ; 00 NULL-дескриптор
        dw 0FFFFh, 0,     9200h, 008Fh  ; 08 16-битный дескриптор данных
        dw 0FFFFh, 0,     9A00h, 008Fh  ; 10 16-bit код
 
; ----------------------------------------------------------------------
; МОДУЛИ
; ----------------------------------------------------------------------

        include "dev/disk_init.asm"
        include "dev/disk_read.asm"
        include "dos/int21.asm"
        include "dos/print.asm"
        include "util/itoa.asm"

; ----------------------------------------------------------------------
; ДАННЫЕ
; ----------------------------------------------------------------------

run:    db 'nanox.com', 0

        include "dos/messages.asm"
        include "dos/param.asm"
        
dta:    ; Здесь находятся временные данные        
