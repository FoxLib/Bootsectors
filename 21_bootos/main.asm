; ----------------------------------------------------------------------
; 512 байт ОС
; ----------------------------------------------------------------------

        macro   brk { xchg bx, bx }
        org     7C00h

KEYBUFFER       equ     7800h
LOGGER_ON       equ     7C24h   ; Включено ли логирование поиска
FILENAME        equ     7C2Bh   ; Указатель на имя файла
TAILPARAM       equ     7C13h

        ; 3 байтный переход
        jmp     near start

; ----------------------------------------------------------------------

        db      'BOOT-512'      ; 03 Имя
        dw      200h            ; 0B Байт в секторе (512)
        db      1               ; 0D Секторов на кластер
        dw      1               ; 0E Количество резервированных секторов перед началом FAT (1 - бутсектор)
        db      2               ; 10 Количество FAT
        dw      00E0h           ; 11 Количество записей в ROOT Entries (224 x 32 = 1C00h байт), 14 секторов
        dw      0B40h           ; 13 Всего логических секторов (2880)
        db      0F0h            ; 15 Дескриптор медиа (F0h - флоппи-диск)
        dw      9h              ; 16 Секторов на FAT
        dw      12h             ; 18 Секторов на трек
        dw      2h              ; 1A Количество головок
        dd      0               ; 1C Скрытых секторов (large)
        dd      0               ; 20 Всего секторов (large)
        db      0               ; 24 Номер физического устройства
        db      1               ; 25 Флаги
        db      29h             ; 26 Расширенная сигнатура загрузчика
        dd      07E00000h       ; 27 Serial Number, но на самом деле ES:BX
        db      'AUTOLOADCOM'   ; 2B Метка тома (совпадает с названием запускного файла)
;        db      'FAT12   '      ; 36 Тип файловой системы

; ----------------------------------------------------------------------
start:

        cld
        sti
        mov     sp, 7C00h

; ----------------------------------------------------------------------
; Ожидание ввода символов

entercmd:

        ; Подготовить сегменты и клавиатуру
        mov     di, KEYBUFFER   
        xor     cx, cx
        mov     ds, cx
        mov     es, cx
        mov     ss, cx
        push    di
        mov     cl, 128
        rep     stosw
        pop     di

        ; Проверка на первый запуск бут-сектора
        mov     bx, 7C25h
        cmp     [bx], byte 1
        jne     typing
        dec     byte [bx]
        call    FindFile        ; Найти AUTOLOAD.COM
        and     ax, ax
        jne     LoadFile        ; Исполнить, если он есть

; ----------------------------------------------------------------------

typing:

        xor     ax, ax
        int     16h
        mov     ah, 0x0E
        int     10h
        cmp     al, 0x61        ; Перевести в верхний регистр
        jb      @f
        cmp     al, 0x7B
        jnb     @f
        sub     al, 0x20        ; $61-$7B -> $41->$5B
@@:     stosb
        cmp     al, 13
        je      accept          ; Ввод данных
        cmp     al, 8
        jne     typing          ; Если BS не нажат
        dec     di              ; Повернуть назад
        dec     di
        mov     ax, 0E20h
        int     10h
        mov     al, 08h
        int     10h
        jmp     typing

; Перевод каретки
crlf:   mov     ax, 0E0Ah
        int     10h
        mov     al, 0Dh
        int     10h
        ret

; ----------------------------------------------------------------------
; Был нажат ENTER
; ----------------------------------------------------------------------

accept:

        call    crlf
        mov     [LOGGER_ON], byte 0         ; Выключить логирование
        mov     si, KEYBUFFER               ; Поиск запроса "DIR" или имя файла
        cmp     [si], dword 'CLS' + (0x0D shl 24)
        je      clear
        cmp     [si], dword 'DIR' + (0x0D shl 24)
        jne     finder

        ; Вывод списка файлов
        inc     byte [LOGGER_ON]            ; Включение логирования
        mov     [FILENAME],  byte 1         ; Ошибочное специально        
        call    FindFile
        jmp     entercmd                    ; Ожидание ввода

        ; Очистить экран
clear:  mov     ax, $0003
        int     10h
        jmp     entercmd

; ----------------------------------------------------------------------
; Вывод файла в терминал
; ----------------------------------------------------------------------

LoggerFile:

        cmp     [LOGGER_ON], byte 0 ; Логировать?
        je      .exit
        pusha                       ; Проверка правильности
        lea     si, [di + 0x7E00]
        cmp     [si + 0xB], byte 0x0F
        je      .nope
        lodsb
        test    al, 0x80
        jne     .nope
        cmp     al, 0x20
        jbe     .nope
        mov     cx, 11              ; Выдать имя файла на-гора
        mov     ah, 0Eh
@@:     int     10h
        lodsb
        loop    @b
        call    crlf
.nope:  popa
.exit:  ret

; ----------------------------------------------------------------------
; Искать запрошенный файл и запуск
; ----------------------------------------------------------------------

finder:

        les     ax, [7C1Ch]         ; Запись ES=0
        mov     di, FILENAME        ; Автозаполнение
        mov     cx, 8
@@:     lodsb
        mov     [TAILPARAM], si
        cmp     al, 20h
        je      @f                  ; Если пробел, то тоже выход
        cmp     al, 0Dh
        je      @f
        stosb
        loop    @b
@@:     jcxz    @f                  ; Дополнить пробелами
        mov     al, 0x20
        stosb
        loop    @b

; Поиск запрошенного файла на диске
@@:     call    FindFile
        and     ax, ax
        je      @f
        jmp     LoadFile

@@:     ; Ошибка загрузки файла
        mov     ax, 0E00h + '?'
        int     10h
        call    crlf
        jmp     entercmd

; ----------------------------------------------------------------------
; Процедура поиска файла в RootEntries (224 файла, 14 секторов) -> DI
; ----------------------------------------------------------------------

FindFile:

        mov     word [7C11h], 00E0h ; Установить поиск 224-х элементов
        mov     ax, 19              ; 19-й сектор - начало RootEntries
dir:    les     bx, [7C27h]         ; ES:BX = 7E0h : 0h
        call    ReadSector
        mov     di, bx
        mov     bp, 16              ; 16 элементов в сектое
item:   mov     si, FILENAME        ; ds:si
        mov     cx, 12
        push    di
        call    LoggerFile          ; Вывод файлового имени
        repe    cmpsb
        pop     di
        jcxz    found
        add     di, 32
        dec     bp
        jne     item
        inc     ax                  ; К следующему сектору
        sub     word [7C11h], 16    ; Всего 14 секторов в Root (16 x 14 = 224)
        jne     dir
        xor     ax, ax              ; Файла нет
        ret
found:  mov     ax, [es: di+1Ah]    ; Номер кластера
        ret                         ; Не загружен

; ----------------------------------------------------------------------
; Первый кластер начинается с сектора 33 (сектора начинаются с 0)
; ----------------------------------------------------------------------

LoadFile:

        mov     [7C22h], word 0x810 ; +100h для ORG файлов
next:   push    ax                  ; Прочесть очередной кластер (1 сектор)
        add     ax, 31              ; 33 - 2
        les     bx, [7C20h]         ; Заполнять c 0800h : 0000h
        call    ReadSector
        add     [7C22h], word 20h   ; + 512
        pop     ax
        mov     bx, 3               ; Каждый элемент занимает 12 бит (3/2 байта)
        mul     bx
        push    ax
        shr     ax, 1 + 9           ; cluster*3/2 -> номер байта / 512 -> номер сектора
        inc     ax                  ; FAT начинается с сектора 1 (второй сектор)
        mov     si, ax
        les     bx, [7C27h]         ; ES:BX = 07E0h : 0000h
        call    ReadSector
        pop     ax
        mov     bp, ax
        mov     di, ax              ; Отыскать указатель на следующий кластер
        shr     di, 1
        and     di, 0x1FF
        mov     ax, [es: di]
        cmp     di, 0x1FF           ; Случай, когда требуется 4/8 бит из следующего сектора
        jne     @f                  ; Загрузка требуется?
        push    ax
        xchg    ax, si
        inc     ax
        call    ReadSector
        pop     ax
        mov     ah, [es: bx]
@@:     test    bp, 1               ; Сдвинуто на 4 бита?
        jz      @f
        shr     ax, 4               ; Выровнять из старшего байта >> 4
@@:     and     ax, 0x0FFF          ; Срезать лишние биты
        cmp     ax, 0x0FF0
        jb      next

        ; ---------------------------------
        ; Установка новых сегментов
        ; ---------------------------------
        
        mov     [7C20h], dword 0x8000100  ; Адрес вызова
        mov     ax, $800            ; Вернуть ES = $800
        mov     es, ax
        mov     si, [TAILPARAM]     ; Переписать 128 символов параметров
        mov     di, 80h
        mov     cx, di
        rep     movsb               ; В ES:$0080
        mov     ds, ax              ; Установка сегментов
        mov     ss, ax
        xor     sp, sp        
        call    far [cs: 7C20h]     ; Переход к программе
        jmp     start               ; Перезапуск командной строки

; ----------------------------------------------------------------------
; Загрузка сектора AX в ES:BX (32 байта)
; ----------------------------------------------------------------------

ReadSector:

        push    ax
        cwd
        div     word [7C18h] ; AX - номер трека, DL - номер сектора 12h (секторов на треке)
        xchg    ax, cx
        mov     dh, cl
        and     dh, 1        ; Дорожка (Disk Head) = 0..1, TrackNum % 2
        shr     cx, 1
        xchg    ch, cl       ; CH-младший, CL[7:6] - старшие 2 бита
        shl     cl, 6
        inc     dx
        or      cl, dl       ; Номер сектора
        mov     dl, 0        ; disk a:/
        mov     ax, 0201h
        int     13h
        pop     ax
        ret

; ----------------------------------------------------------------------
; ОСТАТОК МЕСТА ЗАПОЛНИТЬ ЗАГЛУШКОЙ
; ----------------------------------------------------------------------

        ; Заполнить FFh
        times   7c00h + (512 - 2) - $ db 255

        ; Сигнатура
        dw      0xAA55
