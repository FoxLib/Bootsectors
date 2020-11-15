; ----------------------------------------------------------------------
; Загружается файл LOADER.BIN (не более 636 кб)
; ----------------------------------------------------------------------

; ----------------------------------------------------------------------
BPB_SecInCluster    equ 0Dh ; Секторов в кластере
BPB_ResvdSecCnt     equ 0Eh ; Резервированных секторов перед FAT
BPB_NumFATs         equ 10h ; Количество FAT
BPB_RootEntCnt      equ 11h ; Количество записей в root (только fat12/16)
BPB_TotSec16        equ 13h ; Количество секторов в целом (fat12/16)
BPB_FAT16sz         equ 16h ; Размер FAT(16) в секторах
BPB_TotSec32        equ 20h ; Количество секторов в целом (fat16/32)
BPB_FAT32sz         equ 24h ; Размер FAT(32) в секторах
BPB_RootEnt_32      equ 2Ch ; Номер кластера с Root Entries
; ----------------------------------------------------------------------

        macro   brk { xchg bx, bx }
        org     600h

        ; Установка сегментов и копирование 512 байт
        cli
        cld
        xor     ax, ax
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     sp, 1000h
        mov     si, 7C00h
        mov     di, 600h
        mov     cx, 256
        rep     movsw
        jmp     0 : boot

        ; Исполнение кода
boot:   mov     si, 7BEh                ; Поиск в разделах FAT32
        mov     [600h], dl
        mov     cx, 4
@@:     cmp     [si + 4], byte 0Bh      ; Искать только FAT32
        je      exec
        add     si, 16
        loop    @b
error:  int     18h

; ----------------------------------------------------------------------

        ; Считывание Bios Parameter Block
exec:   mov     ebp, [si + 8]
        mov     [DAP + 8], ebp
        call    Read                                ; Прочитать первый сектор

        ; Вычисление
        movzx   edi, word [800h + BPB_ResvdSecCnt]  ; Резервированных секторов
        add     edi, ebp                            ; Вычислить старт FAT-таблиц
        mov     [start_fat], edi
        mov     eax, [800h + BPB_FAT32sz]           ; Начало данных
@@:     movzx   ebx, byte [800h + BPB_NumFATs]
        mul     ebx
        add     edi, eax
        mov     [start_data], edi
        mov     al, [800h + BPB_SecInCluster]       ; Количество секторов в кластере
        mov     byte [CLUSTR + 2], al
        mov     eax, [800h + BPB_RootEnt_32]        ; Стартовый кластер на прочтение каталогов

        ; Считывание нового кластера и поиск файла в корневом каталоге
GoNext: call    ReadCluster         ; Чтение очередного кластера RootDir в память
        shl     cx, 4               ; 1 сектор = 16 записей
        mov     bp, cx              ; Просматривать N блоков в кластере
        mov     di, 0x1000
@@:     mov     si, RunFile         ; Имя запускного файла
        mov     cx, 12
        push    di
        rep     cmpsb               ; Сравнить 11 байт
        pop     di
        jcxz    found
        add     di, 20h             ; Если не подошел, к следующей записи
        dec     bp
        jne     @b
        call    NextCluster
        cmp     eax, 0x0FFFFFF0     ; Конец файла
        jb      GoNext
        int     18h

; ----------------------------------------------------------------------

        ; Загрузка данных в память
found:  mov     ax, [di + 14h]          ; Первый кластер
        shl     eax, 16
        mov     ax, [di + 1Ah]
@@:     call    ReadCluster             ; Начать цикл скачивания программы в память
        shl     cx, 5
        add     [CLUSTR + 6], cx        ; Сместить на ClusterSize * 512 байт
        call    NextCluster
        cmp     eax, 0x0FFFFFF0
        jb      @b

; ---------------------------------------------------------------------
; Инициализация загрузки ядра именно отсюда
; ---------------------------------------------------------------------

        mov     ax, 0012h
        int     10h         ; Переход в графический режим из бутсектора
        lgdt    [GDTR]      ; Загрузка регистра GDT/IDT
        lidt    [IDTR]
        mov     eax, cr0    ; Вход в Protected Mode
        or      al, 1
        mov     cr0, eax
        jmp     10h : pm

; ----------------------------------------------------------------------
; Читать 1 сектор во временную область

Read:   mov     ah, 42h
        mov     si, DAP
        mov     dl, [600h]
        int     13h
        jb      error
        ret

; ----------------------------------------------------------------------
; Читать кластер EAX = 2...N

ReadCluster:

        push    eax
        sub     eax, 2
        movzx   ecx, word [CLUSTR + 2]
        mul     ecx
        add     eax, [start_data]
        mov     [CLUSTR + 8], eax
        mov     ah, 42h
        mov     si, CLUSTR
        mov     dl, [600h]
        int     13h
        pop     eax
        jb      error
        ret

; ----------------------------------------------------------------------
; Вычислить следующий кластер
; На каждый сектор - 128 записей FAT

NextCluster:

        push    ax
        shr     eax, 7
        add     eax, [start_fat]
        mov     [DAP + 8], eax
        call    Read
        pop     di
        and     di, 0x7F
        shl     di, 2
        mov     eax, [di + 800h]
        ret

; ----------------------------------------------------------------------
RunFile db 'MAIN    BIN'

; ----------------------------------------------------------------------
DAP:    dw 0010h  ; 0 | размер DAP = 16
        dw 0001h  ; 2 | 1 сектор
        dw 0000h  ; 4 | смещение
        dw 0080h  ; 6 | сегмент
        dq 0      ; 8 | номер сектора [0..n - 1]
CLUSTR: dw 0010h  ; 0 | размер DAP = 16
        dw 0001h  ; 2 | 1 сектор
        dw 0000h  ; 4 | смещение
        dw 0100h  ; 6 | сегмент
        dq 0      ; 8 | номер сектора [0..n - 1]

; ----------------------------------------------------------------------
GDTR:   dw 3*8 - 1                  ; Лимит GDT (размер - 1)
        dq GDT                      ; Линейный адрес GDT
IDTR:   dw 256*8 - 1                ; Лимит GDT (размер - 1)
        dq 0                        ; Линейный адрес GDT
GDT:    dw 0,      0,    0,     0   ; 00 NULL-дескриптор
        dw 0FFFFh, 0, 9200h, 00CFh  ; 08 32-битный дескриптор данных
        dw 0FFFFh, 0, 9A00h, 00CFh  ; 10 32-bit код
; ----------------------------------------------------------------------

        use32

; ----------------------------------------------------------------------
; Установка сегментов
; ----------------------------------------------------------------------
pm:     mov     ax, 8
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     fs, ax
        mov     gs, ax

        ; Переход в ОС по загруженному адресу
        jmp     0010h : 1000h

; ----------------------------------------------------------------------
start_fat   dd ?
start_data  dd ?
