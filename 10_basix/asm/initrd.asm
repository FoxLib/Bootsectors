
; ----------------------------------------------------------------------
; initrd (Initial RAM Disk) загрузка из FAT32 в 40`0000h
; поиск и загрузка файла через FAT32 файла initrd
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

initrd:

        ; Читать первый сектор для поиска FAT32
        mov     eax, 0
        call    ReadSector

        ; Поиск в разделах FAT32
        mov     cx, 4
        mov     si, 7DBEh               
@@:     cmp     [si + 4], byte 0Bh
        je      .found32
        add     si, 16
        loop    @b
        jmp     ErrorCaused

; ----------------------------------------------------------------------

.found32:

        ; ES:DI указывает на HMA
        mov     ax, 0x9000
        mov     es, ax

        ; Прочитать первый сектор FAT
        mov     ebp, [si + 8]
        mov     eax, ebp
        call    ReadSector    

        ; Сектор, с которого начинается FAT
        movzx   edi, word [7E00h + BPB_ResvdSecCnt]
        add     edi, ebp
        mov     [start_fat], edi
        
        ; Сектор, откуда начинаются данные
        mov     eax, [7E00h + BPB_FAT32sz]
@@:     movzx   ebx, byte [7E00h + BPB_NumFATs]
        mul     ebx
        add     edi, eax
        mov     [start_data], edi        

        ; Количество секторов в кластере (за 1 раз)
        mov     al, [7E00h + BPB_SecInCluster]          
        mov     byte [CLUSTR + 2], al
        
        ; Получить стартовый кластер на прочтение каталогов        
        mov     eax, [7E00h + BPB_RootEnt_32]

        ; Чтение очередного кластера RootDir в память
GoNext: call    ReadCluster                             
        shl     cx, 4
        mov     bp, cx
        mov     di, 0
        
        ; Поиск необходимого файла в кластере
@@:     mov     si, FILEID
        mov     cx, 12
        push    di
        rep     cmpsb
        pop     di
        jcxz    .found
        add     di, 20h
        dec     bp
        jne     @b        
        call    NextCluster
        cmp     eax, 0x0FFFFFF0
        jb      GoNext
        
        ; Выдать ошибку поиска файла
        mov     ax, 0E22h
        int     10h
        jmp     $

; ----------------------------------------------------------------------
; Файл был найден

.found:  

        ; Размер файла
        mov     eax, [es: di + 1Ch]
        mov     [initrd_size], eax

        ; Первый кластер
        mov     ax, [es: di + 14h]
        shl     eax, 16
        mov     ax, [es: di + 1Ah]        
        
.rd:    call    ReadCluster                 ; Начать цикл скачивания программы в память
        push    eax

        ; Вход в PM для переноса кластера
        mov     edi, [start_xms]    
        and     ecx, 0FFFFh
        shl     ecx, 9
        push    ecx

        mov     eax, cr0
        or      al, 1
        mov     cr0, eax
        jmp     28h : .locpm
.locpm: mov     ax, 20h
        mov     ds, ax
        shr     ecx, 2
        mov     esi, 90000h
.loop:  mov     eax, [esi]
        mov     [edi], eax
        add     esi, 4
        add     edi, 4
        dec     ecx
        jne     .loop
        
        ; Выход из PM обратно
        mov     eax, cr0
        and     al, 0xFE
        mov     cr0, eax
        jmp     0 : .locrm
        
        ; Восстановление сегментов + перемещение указателя
.locrm: xor     ax, ax
        mov     ds, ax
        pop     ecx
        add     [start_xms], ecx
        
        ; Логирование загрузки
        mov     ah, 0Eh
        mov     al, '.'
        int     10h
        pop     eax

        ; Найти следующий кластер
        call    NextCluster            
        cmp     eax, 0x0FFFFFF0
        jb      .rd
        ret

; ----------------------------------------------------------------------
; Вычислить следующий кластер
; На каждый сектор - 128 записей FAT

NextCluster:

        push    ax
        shr     eax, 7
        add     eax, [start_fat]
        call    ReadSector
        pop     di
        and     di, 0x7F
        shl     di, 2
        mov     eax, [di + 7E00h]
        ret

; ----------------------------------------------------------------------
; Читать 1 сектор во временную область

ReadSector:   

        mov     [SECTOR + 8], eax
        mov     ah, 42h
        mov     si, SECTOR
        mov     dl, [7C00h]
        int     13h
        jb      ErrorCaused
        ret

; ----------------------------------------------------------------------
; Читать 1 кластер во временную область

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
        jb      ErrorCaused
        ret

; ----------------------------------------------------------------------
ErrorCaused:

        mov     ax, 0E23h
        int     10h
        jmp     $

; ----------------------------------------------------------------------
FILEID  db 'INITRD  IMG'

; ----------------------------------------------------------------------
SECTOR: dw 0010h  ; 0 | размер DAP = 16
        dw 0001h  ; 2 | 1 сектор
        dw 0000h  ; 4 | смещение
        dw 07E0h  ; 6 | сегмент
        dq 0      ; 8 | номер сектора [0..n - 1]
CLUSTR: dw 0010h  ; 0 | размер DAP = 16
        dw 0001h  ; 2 | 1 сектор
        dw 0000h  ; 4 | смещение
        dw 9000h  ; 6 | сегмент, указывает на HMA
        dq 0      ; 8 | номер сектора [0..n - 1]

; ----------------------------------------------------------------------
start_fat   dd 0
start_data  dd 0
start_xms   dd 00200000h
initrd_size dd 0

