; ----------------------------------------------------------------------
; Загружается файл LOADER.BIN (не более 608 кб)
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

; 7C00h Записан Drive Letter

        macro   brk { xchg bx, bx }
        org     7c00h

        cli
        cld
        xor     ax, ax
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     sp, 7C00h
        mov     si, 7DBEh               ; Поиск в разделах FAT32
        mov     [7C00h], dl
        mov     cx, 4
@@:     cmp     [si + 4], byte 0Bh      ; Искать только FAT32
        je      exec
        cmp     [si + 4], byte 0Ch      ; Искать только FAT32 (LBA) опасно...
        je      exec
        add     si, 16
        loop    @b
error:  int     18h

; ----------------------------------------------------------------------
exec:   mov     ebp, [si + 8]
        mov     [DAP + 8], ebp
        call    Read            
        movzx   edi, word [7E00h + BPB_ResvdSecCnt]     ; Резервированных секторов        
        add     edi, ebp                                ; Вычислить старт FAT-таблиц
        mov     [start_fat], edi
        mov     eax, [7E00h + BPB_FAT32sz]              ; Начало данных
@@:     movzx   ebx, byte [7E00h + BPB_NumFATs]
        mul     ebx
        add     edi, eax
        mov     [start_data], edi        
        mov     al, [7E00h + BPB_SecInCluster]          ; Количество секторов в кластере
        mov     byte [CLUSTR + 2], al        
        mov     eax, [7E00h + BPB_RootEnt_32]           ; Стартовый кластер на прочтение каталогов
GoNext: call    ReadCluster                             ; Чтение очередного кластера RootDir в память
        shl     cx, 4                                   ; 1 сектор = 16 записей
        mov     bp, cx
        mov     di, 8000h
@@:     mov     si, RunFile
        mov     cx, 12
        push    di
        rep     cmpsb
        pop     di
        jcxz    found
        add     di, 20h
        dec     bp
        jne     @b        
        call    NextCluster
        cmp     eax, 0x0FFFFFF0
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
        jmp     0 : 0x8000              ; Перейти к программе

; ----------------------------------------------------------------------
; Читать 1 сектор во временную область

Read:   mov     ah, 42h
        mov     si, DAP
        mov     dl, [7C00h]
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
        mov     dl, [7C00h]
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
        mov     eax, [di + 7E00h]
        ret

; ----------------------------------------------------------------------
RunFile db 'COREBOOTBIN'

; ----------------------------------------------------------------------
DAP:    dw 0010h  ; 0 | размер DAP = 16
        dw 0001h  ; 2 | 1 сектор
        dw 0000h  ; 4 | смещение
        dw 07E0h  ; 6 | сегмент
        dq 0      ; 8 | номер сектора [0..n - 1]
CLUSTR: dw 0010h  ; 0 | размер DAP = 16
        dw 0001h  ; 2 | 1 сектор
        dw 0000h  ; 4 | смещение
        dw 0800h  ; 6 | сегмент
        dq 0      ; 8 | номер сектора [0..n - 1]

; ----------------------------------------------------------------------
start_fat   dd ?
start_data  dd ?
