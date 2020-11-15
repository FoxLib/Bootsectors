
        org     $0010
        macro   brk { xchg bx, bx }

; ----------------------------------------------------------------------        
BPB_SecInCluster    equ 7C00h + 0Dh ; Секторов в кластере
BPB_ResvdSecCnt     equ 7C00h + 0Eh ; Резервированных секторов перед FAT
BPB_NumFATs         equ 7C00h + 10h ; Количество FAT 
BPB_RootEntCnt      equ 7C00h + 11h ; Количество записей в root (только fat12/16)
BPB_TotSec16        equ 7C00h + 13h ; Количество секторов в целом (fat12/16)
BPB_FAT16sz         equ 7C00h + 16h ; Размер FAT(16) в секторах
BPB_TotSec32        equ 7C00h + 20h ; Количество секторов в целом (fat16/32)
BPB_FAT32sz         equ 7C00h + 24h ; Размер FAT(32) в секторах
BPB_RootEnt_32      equ 7C00h + 2Ch ; Номер кластера с Root Entries
; ----------------------------------------------------------------------

        ; Запись кода (32кб) из $8000 -> $FFFF:$0000
        xor     ax, ax
        mov     sp, 7C00h
        mov     ds, ax
        dec     ax
        mov     es, ax
        mov     cx, 4000h   ; 2 x 16kb
        mov     si, 8000h
        mov     di, 0010h
        rep     movsw
        jmp     0xFFFF : himem

himem:  ; ds = es = cs = $ffff, ss = 0000h, sp = 7c00h

        ; Перенести Drive Letter в область Himem
        mov     dl, [0000]
        mov     ax, es
        mov     ds, ax
        mov     [Drive_Letter], dl
        
        call    search_fat_partition    ; Поиск FAT раздела
        call    fat_type_detection      ; Определение типа FAT

        cmp     al, 10h
        je      directory_search_16

        cmp     al, 20h
        je      directory_search_32

        mov     si, error_fat_not_support
        jmp     kpanic

; ----------------------------------------------------------------------
; ЗАГРУЗКА ИЗ 16-битной FAT
; ----------------------------------------------------------------------

directory_search_16:

        ; Кол-во секторов под RootDir
        mov     bp, word [ss:BPB_RootEntCnt]
        shr     bp, 4                           
        
        ; Установить первый сектор
        mov     eax, [start_rootdir16]
        mov     [DAP_fat_sector + 8], eax

.load:
        ; Читать 1 сектор (поиск)
        push    bx
        mov     ah, 42h
        mov     si, DAP_fat_sector
        mov     dl, [Drive_Letter]
        int     13h
        pop     bx

        ; Начало тут всегда
        mov     si, 7E00h
        mov     cx, 16          ; 16 x 32 = 512
        
.search:

        ; Определение маски
        cmp     [ss:si + 0], dword 'KERN'
        jne     @f
        cmp     [ss:si + 7], dword ' RUN'   ; KERN??? .RUN
        jne     @f
        jmp     .found

@@:     add     si, 32
        loop    .search
        
        ; Следующий сектор RootEntries
        add     [DAP_fat_sector + 8], dword 1    
        dec     bp
        jne     .load
        
        ; Ничего не было найдено
        mov     si, error_kernelnot
        jmp     kpanic

.found: 
    
        call    get_first_cluster       ; Получить первый кластер
.chain: call    load_cluster            ; Загрузка очередного кластера    
        call    search_next_cluster16   ; Поиск следующего
        
        ; Секторов на кластер
        movzx   bx, byte [DAP_cluster_load + 2]
        shl     bx, 5   ; +20h сегментов на каждый сектор в кластере
        add     [DAP_cluster_load + 6], bx

        ; Если достигнут последний сектор, то выход
        cmp     ax, 0xFFF0
        jb      .chain
        jmp     goto_program

; ----------------------------------------------------------------------
; ЗАГРУЗКА ИЗ 32-битной FAT
; https://ru.wikipedia.org/wiki/FAT :: Структура файловой записи
; ----------------------------------------------------------------------

directory_search_32:  

        ; Загрузка следующего кластера директорий
        mov     eax, [start_rootcluster32]    
        call    load_cluster

        ; Вычислить количество элементов в кластере
        mov     cx, [ss:BPB_SecInCluster]   ; 32 байта на запись | 16 записей в 1 секторе
        shl     cx, 4        
        mov     si, 8000h                   ; ss:si = 0000:8000h - здесь будет Directory Entries

.search:
        
        ; Определение маски
        cmp     [ss:si + 0], dword 'KERN'
        jne     @f
        cmp     [ss:si + 7], dword ' RUN'   ; KERN??? .RUN
        jne     @f
        jmp     .found
@@:     add     si, 32
        loop    .search

        ; Если достигнут конец кластера, отыскать новый кластер
        mov     eax, [start_rootcluster32]
        call    search_next_cluster32
        mov     [start_rootcluster32], eax

        cmp     eax, 0x0FFFFFF0
        jb      directory_search_32

        ; Ничего нет
        mov     si, error_kernelnot
        jmp     kpanic

.found: 

        call    get_first_cluster

load_file2mem:

        call    load_cluster
        call    search_next_cluster32
        
        ; Секторов на кластер
        movzx   bx, byte [DAP_cluster_load + 2]
        shl     bx, 5   ; +20h сегментов на каждый сектор в кластере
        add     [DAP_cluster_load + 6], bx

        ; Если достигнут последний сектор, то выход
        cmp     eax, 0x0FFFFFF0
        jb      load_file2mem        

goto_program:

        ; Очистить перед запуском, [DL] = Drive Letter, EBP - Размер файла
        movzx   edx, byte [Drive_Letter]        
        
        xor     eax, eax
        xor     ebx, ebx
        xor     ecx, ecx
        xor     esi, esi
        xor     edi, edi
        xor     ebp, ebp
        mov     ds, ax        
        mov     es, ax  

        jmp     0000 : 8000h

; Получение первого кластера из FAT16/32
get_first_cluster:

        ; Вычисление адреса первого кластера
        mov     ax, [ss:si + 14h]
        shl     eax, 16
        mov     ax, [ss:si + 1Ah]
        
        ; Тест размеров файла
        mov     ebp, [ss:si + 1Ch]        
        test    ebp, ebp
        mov     si, error_filezero  ; 0 байт недопустимо
        je      kpanic        
        mov     si, error_bigfile
        cmp     ebp, 600 * 1024     ; > 600 kb недопустимо
        jnb     kpanic

        ret

; Загрузка кластера в память
; ----------------------------------------------------------------------
load_cluster:

        pushad
        
        ; Кластер начинается всегда с 2 в разделе Data
        sub     eax, 2                  

        ; cluster x [Cluster_Size]
        movzx   ebx, word [DAP_cluster_load + 2]
        mul     ebx

        ; Добавить начальное смещение, edx+1 (если переполнение есть)
        add     eax, [start_data]
        adc     edx, 0
        
        ; Сохраняется адрес сектора
        mov     [DAP_cluster_load + 8],  eax
        mov     [DAP_cluster_load + 12], edx
                
        mov     ah, 42h             ; Загрузка кластера каталога для поиска файла
        mov     si, DAP_cluster_load
        mov     dl, [Drive_Letter]
        int     13h       
        mov     si, error_cluster_fail 
        jc      .dumpout            ; Возникла ошибка при загрузке?

        popad
        ret
        
.dumpout:
        
        ; low / high
        mov     eax, [DAP_cluster_load + 8]
        call    print_hex32
        mov     eax, [DAP_cluster_load + 12]
        call    print_hex32    
        jmp     kpanic
        
; Дебаг
print_hex32:

        push    eax ebx ecx edx
        mov     cx, 8
.symb:  rol     eax, 4
        mov     ebx, eax
        and     al, 0xf
        cmp     al, 10
        jb      @f
        add     al, 7
@@:     add     al, '0'
        mov     ah, 0xe
        int     10h
        mov     eax, ebx
        loop    .symb
        mov     ax, 0x0e20
        int     10h
        pop     edx ecx ebx eax
        ret

; Поиск следующего кластера 32
; ----------------------------------------------------------------------
search_next_cluster32:

        shl     eax, 2
        xor     edx, edx
        mov     ebx, 512
        div     ebx                 ; EAX - номер сектора, EDX - смещение в секторе
        add     eax, [start_fat]    ; FAT_sector + (eax*4 / 512) -- скачать нужный сектор FAT
        push    edx
        
        ; Загрузка необходимого сектора FAT
        mov     [DAP_fat_sector + 8], eax
        mov     ah, 42h
        mov     si, DAP_fat_sector
        mov     dl, [Drive_Letter]
        int     13h

        ; Вычисляем следующий кластер
        pop     edx
        mov     eax, [ss:7E00h + edx]
        ret

; FAT16
search_next_cluster16:

        movzx   eax, ax
        shl     eax, 1
        xor     edx, edx
        mov     ebx, 512
        div     ebx                 ; EAX - номер сектора, EDX - смещение в секторе
        add     eax, [start_fat]    ; FAT_sector + (eax*2 / 512) -- скачать нужный сектор FAT
        push    edx
        
        ; Загрузка необходимого сектора FAT
        mov     [DAP_fat_sector + 8], eax
        mov     ah, 42h
        mov     si, DAP_fat_sector
        mov     dl, [Drive_Letter]
        int     13h

        ; Вычисляем следующий кластер
        pop     edx
        movzx   eax, word [ss:7E00h + edx]
        ret

; ----------------------------------------------------------------------
; ОПРЕДЕЛЕНИЕ ТИПА FAT 
; ВХОД:  EAX = начало раздела
; ВЫХОД: AL = 12/16/32
; ----------------------------------------------------------------------

fat_type_detection:

        ; LBA-адрес начала раздела
        mov     [start_partition], eax   
        mov     [DAP_boot_sector + 8], eax

        ; Получение сектора для определения параметров загрузки
        mov     ah, 42h
        mov     si, DAP_boot_sector
        mov     dl, [Drive_Letter]
        int     13h

        ; 1. Резервированных секторов
        movzx   edi, word [ss:BPB_ResvdSecCnt]
        
        ; 2. Вычислить старт FAT-таблиц
        mov     eax, [start_partition]
        add     eax, edi
        mov     [start_fat], eax

        ; 3. FAT size
        movzx   eax, word [ss:BPB_FAT16sz]
        test    ax, ax
        jne     @f                      ; Если не 0, взять это значение
        mov     eax, [ss:BPB_FAT32sz]
@@:     movzx   ebx, byte [ss:BPB_NumFATs]
        mul     ebx
        add     edi, eax
 
        ; 4. Начало RootDir для FAT16
        mov     eax, [start_partition]
        add     eax, edi
        mov     [start_rootdir16], eax

        ; 5. Root Entries (для FAT32 = 0)
        movzx   eax, word [ss:BPB_RootEntCnt]
        shr     ax, 4                       ; BPB_RootEntCnt * 32 / 512 = BPB_RootEntCnt >> 4
        add     edi, eax
        
        ; 6. Где находятся сектора с данными
        mov     eax, [start_partition]
        add     eax, edi
        mov     [start_data], eax
        
        ; 7. Определить, сколько секторов на диске
        movzx   eax, word [ss:BPB_TotSec16]
        test    eax, eax
        jne     @f
        mov     eax, [ss:BPB_TotSec32]

        ; 8. Определить, сколько кластеров в Data секции
@@:     sub     eax, edi
        movzx   ebx, byte [ss:BPB_SecInCluster]
        mov     [DAP_cluster_load + 2], bl          ; ... и в DAP
        xor     edx, edx
        div     ebx

        ; 9. Определить тип ФС (12/16/32)
        cmp     eax, 4085
        jnb     @f
        mov     al, 12              ; < 4085 - FAT12
        ret
        
@@:     cmp     eax, 65525
        jnb     @f                  ; <= 65524 - FAT16
        mov     al, 16
        ret
        
@@:     ; Записать указатель на кластер RootEntries
        ; Кластер 2 - начальный (старт с Data-секции)

        mov     eax, [ss:BPB_RootEnt_32]
        mov     [start_rootcluster32], eax

        mov     al, 32              ; > 65524 - FAT32     
        ret

; ----------------------------------------------------------------------
; ПРОЦЕДУРА ПОИСКА FAT16/32 РАЗДЕЛА
; ВЫХОД: EAX - начало раздела
; ----------------------------------------------------------------------

search_fat_partition:

        mov     si, 0x1BE + 0x7C00
        mov     cx, 4        

.retry:
        ; FAT32
        cmp     [ss:si + 4], byte 0Bh           
        je      fat_was_found

        ; FAT16
        cmp     [ss:si + 4], byte 06h           
        je      fat_was_found
        add     si, 16
        loop    .retry
        
        mov     si, error_fat_not_found       
        jmp     kpanic

fat_was_found:

        mov     eax, [ss:si + 8]
        ret

; ----------------------------------------------------------------------
; ПЕЧАТЬ СООБЩЕНИЯ ОБ ОШИБКЕ
; ----------------------------------------------------------------------

kpanic: lodsb
        and     al, al
        je      @f
        mov     ah, 0Eh
        int     10h
        jmp     kpanic
@@:     jmp     $       

; ----------------------------------------------------------------------
; ДАННЫЕ
; ----------------------------------------------------------------------

Drive_Letter   db 0            ; ID диска

DAP_boot_sector:

    dw 0010h  ; 0 | размер DAP = 16
    dw 0001h  ; 2 | читать 1 сектор (512 байт)
    dw 0000h  ; 4 | смещение
    dw 07C0h  ; 6 | сегмент
    dq 0      ; 8 | номер сектора [0..n-1]

DAP_fat_sector:

    dw 0010h  ; 0 | размер DAP = 16
    dw 0001h  ; 2 | читать 1 сектор (512 байт)
    dw 0000h  ; 4 | смещение
    dw 07E0h  ; 6 | сегмент
    dq 0      ; 8 | номер сектора [0..n-1]

DAP_cluster_load:

    dw 0010h  ; 0
    dw 0001h  ; 2 | 1 сектор по умолчанию
    dw 0000h  ; 4
    dw 0800h  ; 6
    dq 0      ; 8

; Сообщения об ошибках
error_fat_not_found     db "(Exception) FAT16/32 not found!", 0
error_fat_not_support   db "(Fatal) FAT12 not supported", 0
error_cluster_fail      db "(Exception) Cluster not loaded", 0
error_kernelnot         db "(Fatal) No KERN??? RUN file", 0
error_filezero          db "(Warning) File exists, but zero", 0
error_bigfile           db "(Warning) File exists, but over 600k - too big", 0

; Номер сектора, откуда начинается раздел
start_partition         dd 0 ; Сектор начала Partition
start_fat               dd 0 ; Сектор начала FAT
start_rootdir16         dd 0 ; Начало Root Directory (FAT16)
start_rootcluster32     dd 0 ; Начало Root Directory (FAT32)
start_data              dd 0 ; Сектор начала данных
