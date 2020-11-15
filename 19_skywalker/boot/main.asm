
        org     $7C00
        macro   brk { xchg bx, bx }

        ; 1. Загрузка BIOS $FFFF : 0000
        ; 2. Загрузка 512 байт с MBR (0-й сектор)
        ; 3. Загрузчик Bootloader загружает в память стартер (kernel)
        ; 4. Стартер запускает ядро и загружает в память ОС

; Инициализация
; ----------------------------------------------------------------------

        cli
        cld
        mov     ax, bx          ; LOGOTYPE
        xor     ax, ax          ; ax = 0
        mov     ss, ax
        mov     sp, $7C00       ; стек под загрузчик
        mov     ds, ax
        mov     es, ax
        mov     [$0000], dl     ; В регистре dl будет номер диска BIOS

; Поиск первого раздела с FAT32
; ----------------------------------------------------------------------

        mov     cx, 4
        mov     si, 1BEh + 7C00h

retry_find:

        cmp     [si + 4], byte 0Bh      ; FAT32
        je      partition_found
        add     si, 16
        loop    retry_find

        mov     si, msg_notfound
        jmp     show_error

; Определение структуры FAT
; ----------------------------------------------------------------------

partition_found:

        mov     ebp, [si + 8]           ; Считывается первый сектор
        mov     [DAP_sector + 8], ebp   ; Номер сектора, где хранится 1-й сектор

        ; Скачать сектор
        mov     ah, 42h
        mov     si, DAP_sector
        int     13h

        ; 1 BPB
        ; n Резервированные сектора
        ; m x fat_count Сектора FAT
        ; Данные

        mov     si, $7E00

        ; Вычислить начало FAT
        movzx   ebx, word [si + $0E]     ; Зарезервированные сектора
        add     ebp, ebx
        mov     [FAT_sector], ebp        ; ebp = адрес сектора с FAT

        ; Вычисление сектора данных
        mov     eax, [si + $24]          ; Секторов в FAT (32)
        movzx   ebx, byte [si + $10]     ; Кол-во FAT
        mul     ebx                      ; Секторов на FAT (eax) = FAT_count * Sectors_in_FAT
        add     ebp, eax                 ; Начало данных
        mov     [FAT_data], ebp

        ; Секторов в кластере
        mov     al,  [si + $0D]
        mov     [DAP_cluster + 2], al

        ; Первый кластер корневого каталога
        mov     eax, [si + $2C]

; Искать файлы в корневом каталоге
; ----------------------------------------------------------------------

search_loop:

        call    load_cluster

        mov     di, $8000
        mov     dx, [DAP_cluster + 2]   ; секторов на кластер
        shl     dx, 4                   ; 1 сектор = 16 записей

row_loop:

        ; Сравнивать файл-эталон поиска и входящий файл
        mov     bx, di
        mov     si, Find_File
        mov     cx, 12                  ; 11 + 1
        repz    cmpsb
        and     cx, cx
        je      file_found

        ; К следующей записи
        lea     di, [bx + 32]
        dec     dx
        jne     row_loop

        ; Поиск следующего кластера в FAT
        call    next_cluster

        ; Проверка на конец последовательности
        cmp     eax, $0FFFFFF8
        jc      search_loop

        ; Файл не был найден
        mov     si, msg_notfound
        jmp     show_error

; Загрузка файла в память
; ----------------------------------------------------------------------

file_found:

        ; Получается адрес кластера
        mov     ax, [bx + $14]          ; старшие 2 байта кластера
        shl     eax, 16
        mov     ax, [bx + $1A]          ; нижние 2 байта кластера

load_file:

        call    load_cluster
        call    next_cluster
        mov     cx, [DAP_cluster + 2]    ; 1 s = 512/16 = 32
        shl     cx, 5                    ; Умножение числа секторов на 32 сегмента
        add     [DAP_cluster + 6], cx    ; Сместим область загрузки на 512 * Sectors_Per_Cluster
        cmp     eax, $0FFFFFF8
        jc      load_file

; Выполнение кода
; ----------------------------------------------------------------------

        jmp     $0000 : $8000

; ----------------------------------------------------------------------

; EAX - номер кластера от 2 от N
; EBP - стартовый сектор данных
; (Cluster - 2) * Sectors_Per_Cluster + EBP

load_cluster:

        pusha
        sub     eax, 2
        movzx   ebx, word [DAP_cluster + 2]
        mul     ebx
        add     eax, ebp
        mov     [DAP_cluster + 8], eax
        mov     si, DAP_cluster
        call    load_data
        popa
        ret

; ----------------------------------------------------------------------
; I: EAX - текущий кластер
; O: EAX - новый кластер

next_cluster:

        ; 512 / 4 = 128 записей в 1 секторе
        ; Расчет сектора, где будет следующий кластер
        mov     ebx, eax
        shr     ebx, 7      ; num / 128
        add     ebx, [FAT_sector]
        mov     [DAP_sector + 8], ebx

        mov     si, DAP_sector
        call    load_data       ; -> 7E00h

        mov     bx, ax
        and     bx, 7Fh         ; eax = eax % 128
        shl     bx, 2           ; eax = eax * 4

        mov     eax, [$7E00 + bx] ; Получен новый номер кластера
        ret

; ----------------------------------------------------------------------
; SI - указатель на структуру

load_data:

        push    ax
        mov     dl, [$0000]         ; Номер диска
        mov     ah, 42h
        int     13h
        pop     ax
        ret

; ----------------------------------------------------------------------
show_error:

        lodsb
        and     al, al
@@:     je      @b
        mov     ah, 0Eh
        int     10h
        jmp     show_error

msg_notfound db "Data not found", 0

; ----------------------------------------------------------------------

Find_File    db 'CORE    BIN'
FAT_sector   dd 0
FAT_data     dd 0

DAP_sector:

        ; 7C00 - 7DFF 1-й MBR
        ; 7E00 - 7FFF 1-й FAT32

        dw      0010h       ; 0 Размер структуры
        dw      0001h       ; 2 Сколько секторов читать
        dw      0000h       ; 4 Смещение
        dw      07E0h       ; 6 Сегмент * 16 = $7E00
        dq      1           ; 8 Номер сектора (начиная с 1)

DAP_cluster:

        dw      0010h       ; 0
        dw      0001h       ; 2
        dw      0000h       ; 4
        dw      0800h       ; 6 $8000
        dq      1           ; 8
