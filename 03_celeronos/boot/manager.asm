; ----------------------------------------------------------------------
; ЧАСТЬ 2. Загрузочный менеджер, по адресу [0000:08000]
; 
; Загрузка необходимого ядра через FAT32, включение Protected Mode
; himem:
; 0x0000 loader, stack ^
; 0x8000 sector [512]
; 0x8200 cluster [4096..32768]
; ----------------------------------------------------------------------

    org 0x0010

    macro   brk { xchg bx, bx }
    
    ref_sector  EQU 0xF000 ; Сектор размера 512 байт
    ref_cluster EQU 0xB000 ; Объем кластера не более 16 кб

    ; --------------------------------
    ; Переместить себя в Himem
    ; --------------------------------

    xor     ax, ax
    mov     sp, 0x8000
    mov     ds, ax
    mov     dl, [$03FF] ; В boot-sector прописывалось сюда это значение
    dec     ax
    mov     es, ax
    mov     cx, 16384   ; 2 x 16kb
    mov     si, 0x0800
    mov     di, 0x0010
    rep     movsw
    jmp     0xffff : himem

; ----------------------------------------------------------------------
drive: db 0 ; Здесь будет номер диска для "работ"-изирования

fat32_begin         dd 0 ; Начало таблиц FAT
fat32_data          dd 0 ; Начало данных
fat32_dir           dd 0 ; Корневая директория
fat32_clsize        dw 0 ; Секторов на кластер
kernel_file         db 'CORE    BIN'

; Чтение одного сектора
DAP_sector: 

    dw 0x0010       ; 0 размер DAP = 16
    dw 0x0001       ; 2 читать 1 сектор
    dw ref_sector   ; 4 смещение
    dw 0x9000       ; 6 сегмент
    dq 0            ; 8 номер сектора от 0 до N-1

; Чтение кластера
DAP_cluster:

    dw 0x0010       ; 0 размер DAP = 16
    dw 0x0001       ; 2 читать кластер 
    dw ref_cluster  ; 4 смещение
    dw 0x9000       ; 6 сегмент
    dq 0            ; 8 номер сектора

; ----------------------------------------------------------------------
himem:

    ; Новые сегменты
    mov     ax, cs
    mov     ds, ax
    mov     ss, ax
    mov     es, ax

    ; Указатели на сектор и кластер
    mov     ax, $9000
    mov     fs, ax

    ; А теперь записать его в нужное место
    mov     [drive], dl       

    ; Очистить экран
    mov     ax, 0x0003
    int     0x10
    
; Грузнуть первый сектор диска
; ----------------------------------------------------------------------

    call    load_sector

    ; В таблице разделов ищем FAT32-раздел
    mov     cx, 4
    mov     si, ref_sector + 0x01BE
@@: cmp     [fs:si + 4], byte 0x0B      ; Это FAT32 ?
    je      fat32_found    
    add     si, 0x10                 ; Нет, не fat32 - следующий раздел
    loop    @b
    mov     si, msg_fat32_not_exists
    jmp     error_message

; FAT32 раздел успешно найден
; ----------------------------------------------------------------------
fat32_found:

    mov     esi, [fs:si + 8]            ; загружаем номер сектора, где находится 1-й сектор раздела
    mov     [DAP_sector + 8], esi    ; пишем указатель на сектор
    call    load_sector              ; грузим 1-сектор FAT32

    ; Вычисление начала важных разделов FAT
    movzx   eax, word [fs:ref_sector + $0E]    ; количество зарезервированных секторов
    add     esi, eax
    mov     [fat32_begin], esi              ; начало = кол-во секторов до раздела + скрытых секторов на разделе    
    
    ; Старт данных
    movzx   eax, byte [fs:ref_sector + $10]    ; 10h 1 количество fat
    mov     ebx, [fs:ref_sector + $24]         ; 24h 4 размер fat в секторах
    mul     ebx
    add     eax, esi
    mov     [fat32_data], eax               ; = fat_count * sectors_by_fat + start_FAT
    
    ; Размер кластера
    mov     al, [fs:ref_sector + $0D]          ; кол-во секторов на кластере
    mov     [DAP_cluster + 2], al
    mov     byte [fat32_clsize], al         ; размер кластера

    ; Начало корневой директории
    mov     eax, [fs:ref_sector + 0x02C]
    mov     [fat32_dir], eax
    
; Поиск файла в каталоге
; ----------------------------------------------------------------------

directory_search:

    ; Загрузка кластера
    mov     eax, [fat32_dir]            ; корневой каталог (в кластерах)
    call    load_cluser

    ; Перейти к началу таблицы
    mov     si, ref_cluster  
    mov     bx, [fat32_clsize]
    shl     bx, 4          ; = ^(9-5) (кол-во элементов в кластере), ^9 = 512, ^5=32 запись        
                           ; = cluster_size * 512 / 32 = cluster_size * 16 (shl 4)          
.nextfile:

    ; Сравнение имени файла
    push    si
    mov     di, kernel_file
    mov     cx, 11
    db 64h ; fs:
    rep     cmpsb
    pop     si
    jcxz    file_found
    add     si, 32  
    dec     bx
    jne     .nextfile

    ; Получить следующий кластер из FAT
    mov     eax, [fat32_dir]
    call    next_cluster
    mov     [fat32_dir], eax
    
    ; Искать, пока кластеры еще есть
    cmp     eax, 0x0FFFFFF0
    jb      directory_search

    ; Больше данных нет
    mov     si, msg_file_not_found
    jmp     error_message

; Загрузка файла с диска в память
; ----------------------------------------------------------------------

file_found:

    ; Первый кластер
    mov     ax, word [fs:si + 0x14]
    shl     eax, 16
    mov     ax,  [fs:si + 0x1A]
    
    ; Начать вывод в [00800-...]
    mov     [DAP_cluster + 6], word 0x0080 ; Стартовый сегмент
    mov     [DAP_cluster + 4], word 0x0000 ; Смещение

.next:

    ; Установить адрес на $00800 и загружать туда кластеры    
    mov     [DAP_cluster + 8], eax
    call    load_cluser
    call    next_cluster

    ; Перейти к следующему сегменту
    mov     bx, word [fat32_clsize]
    shl     bx, 5
    add     [DAP_cluster + 6], bx
    cmp     eax, 0x0FFFFFF0     ; Есть еще кластеры?
    jb      .next 

    ; Переход к самому ядру
    jmp     0 : 0x0800

; ПРОЦЕДУРЫ
; ----------------------------------------------------------------------

; Загрузка сектора в фиксированную память
load_sector:

    pushad
    mov     ah, 0x42
    mov     si, DAP_sector
    mov     dl, [drive]
    int     0x13
    mov     si, msg_dap_loadsector
    jb      error_message
    popad
    ret

; Загрузить кластер eax = 2...cl
load_cluser: 

    pushad
    sub     eax, 2                      ; cluster - 2
    movzx   ebx, word [DAP_cluster + 2] ; количество секторов на кластер
    mul     ebx  
    add     eax,  [fat32_data]          ; (cluster-2)*sectors_by_cluster + data_cluster
    mov     [DAP_cluster + 8], eax
    mov     ah, 0x42
    mov     si, DAP_cluster
    mov     dl, [drive]
    int     0x13
    popad
    ret

; Определение следующего кластера eax по текущему eax
next_cluster: 

    shl     eax, 2
    xor     edx, edx
    mov     ebx, 512
    div     ebx                 ; eax - номер сектора, edx - смещение в секторе
    add     eax, [fat32_begin]  ; FAT_sector + (eax*4 / 512) -- скачать нужный сектор FAT

    ; Скачать tmp-данные 
    mov     [DAP_sector + 8], eax
    call    load_sector

    ; Вычисляем следующий кластер
    mov     eax, [fs:ref_sector + edx]
    ret
 
; ----------------------------------------------------------------------

; ds:si - источник
error_message:

    lodsb
    and     al, al
@@: je      @b
    mov     ah, 0x0E
    int     0x10
    jmp     error_message

; ds:si - выдать отладочный дамп hex 16x16
; ----------------------------------------------------------------------
hexdump:

    pushad
    mov dx, 16
.ln:    
    mov cx, 16
.lp:
    lodsb
    push ax
    and al, $F0
    shr al, 4
    cmp al, 10
    jb @f
    add al, 7
@@: add al, '0'
    mov ah, 0x0E
    int 0x10
    pop ax
    and al, $0F
    cmp al, 10
    jb @f
    add al, 7
@@: add al, '0'
    mov ah, 0x0e
    int 0x10
    mov al, ' '
    int 0x10
    loop .lp
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    dec dx
    jne .ln
    mov ax, 0
    int 0x16
    popad
    ret

msg_dap_loadsector      db "DAP load sector fails", 0
msg_file_not_found      db "CORE.BIN not found", 0
msg_fat32_not_exists    db "Partition FAT32 not exists", 0
