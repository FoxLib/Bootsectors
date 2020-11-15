; КОМПИЛЯЦИЯ
; fasm boot_fat32.asm

; ЗАПИСЬ БУТ-СЕКТОРА В IMG-файл диска (равносильно записи на драйв)
; ./boot flash.img boot_fat32.bin

; ПОЛНОСТЬЮ
; fasm boot_fat32.asm && ./boot flash.img boot_fat32.bin && bochs -f boot.bxrc -q
; fasm boot_fat32.asm && ./boot /dev/sdf boot_fat32.bin sudo (записать на flash-диск)

; ---
; Через утилиту dd записать из linux/windows только первые 446 байт

    macro brk { xchg bx, bx }
    org 0x7C00

    cli
    cld

    ; Не забываем проставлять нули везде!
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7000 ; "Спустить" SP вниз, чтобы не допустить ошибки при загрузке файла

    ; Сохранить номер запускного диска из BIOS
    mov [0x7BFE], dl 

    ; Проверка расширения BIOS для чтения из DAP
    mov ah, 0x41
    mov bx, 0x55AA    
    int 0x13
    jc boot_failed

    ; ---------------------- Загружаем первый сектор ----------------

    ; Поиск раздела FAT32
    mov cx, 4
    mov si, 0x7DBE
@@:    
    cmp [si + 4], byte 0x0B ; FAT32 ?
    je .fat32
    add si, 0x10 ; Следующий раздел
    loop @b
    jmp boot_failed

.fat32:

    mov si,  [0x7DBC]    ; считывает заранее подготовленный адрес
    mov esi, [si + 8]    ; загружаем 1-й сектор раздела
    mov [DAP + 8], esi   ; пишем указатель
    call load_sector_DAP ; грузим 1-сектор

    ; +512 байт вперед
    add [DAP + 6], byte 32 ; следующие данные начать загружать уже в 0x8200 

    ; Старт FAT
    movzx ebx, word [0x800E]  ; Кол-во зарезервированных секторов
    mov [0x8000], esi
    add [0x8000], ebx         ; Записать адрес начала раздела [start_FAT]

    ; Расчет начала данных
    mov   eax, [0x8024]      ; eax = fat_count
    movzx ebx, byte [0x8010] ; ebx = sectors_by_fat
    mul   ebx
    add   eax, [0x8000]
    mov   [0x8004], eax      ; 0x8004 = fat_count * sectors_by_fat + start_FAT
    
    movzx eax, byte [0x800D] ; Количество секторов на кластер
    mov   [DAP + 2], al      ; Читать теперь не секторами, а кластерами
    mov   [0x8008], eax      ; 0x8008 = sectors_per_cluster (Секторов на кластер)

    ; ---------------- поиск файлов в корневой директории ----------------

lookup:

    mov eax, [0x802C] ; Номер текущего кластера
    call load_cluster ; Загружаем кластер в память

    ; Начинаем поиск данных
    xor esi, esi
    mov ecx, [0x8008] ; Секторов на кластер
    shl ecx, 4        ; 9 - 5 (кол-во элементов в кластере)

@lookup:

    ; Поиск RUN
    cmp dword [0x8200 + esi], 'MOON'
    jne next_entry
    cmp dword [0x8207 + esi], ' BIN'
    je  file_found

next_entry:

    ; Последовательный перебор
    add esi, 32
    loop @lookup

    ; Если не найдено ничего, то получить следующий кластер через таблицу FAT
    mov eax, [0x802C]
    call get_next_cluster
    mov [0x802C], eax

    cmp eax, 0x0FFFFFF0
    jb  lookup ; есть еще кластеры
    jmp boot_failed

; Файл был успешно найден
; ------------------------------------------------------------------------------------------
; Начать скачивание файла в памяти по адресу 0xC000 (48 кб) 592 кб максимальный размер файла
file_found:

    mov ax, [0x8200 + esi + 0x14]
    shl eax, 16
    mov ax, [0x8200 + esi + 0x1A] ; eax - кластер
    mov di, 0x0C00

loading:

    mov [DAP + 6], di ; сегмент
    mov [0x802C], eax ; запись кластера
    call load_cluster

    ; Ищем следующий кластер
    call get_next_cluster

    ; К следующему сегменту
    mov ebx, [0x8008]
    shl bx, 5
    add di, bx

    cmp eax, 0x0FFFFFF0
    jb  loading ; есть еще кластеры?

    ; При загрузке кластера могут быть "лишние" данные
    ; ------

    ; ЗАПУСК!
    jmp far 0:0xC000

boot_failed:

    mov si, boot_string
@@:    
    mov ah, 0xe
    lodsb
    and al, al
    je @f
    int 0x10
    jmp @b
@@: jmp $

boot_string db "Boot fail", 0

; Загрузить сектор с сохранением контекста
; --------------------------------------------------------------------
load_sector_DAP:

    pusha
    mov ah, 0x42
    mov si, DAP
    mov dl, [0x7BFE]
    int 0x13
    popa
    ret

; Загрузка кластера. eax - номер кластера
load_cluster:

    pusha
    sub  eax, 2 ; cluster - 2
    mul  dword [0x8008] ; количество секторов на кластер
    add  eax,  [0x8004] ; (cluster-2)*sectors_by_cluster + data_cluster
    mov  [DAP + 8], eax
    call load_sector_DAP ; прочитать кластер
    popa
    ret

; Определить следующий кластер
get_next_cluster:
   
    shl eax, 2
    xor edx, edx
    mov ebx, 512
    div ebx           ; eax - номер сектора, edx - смещение в секторе
    add eax, [0x8000] ; FAT_sector + (eax*4 / 512) -- скачать нужный сектор FAT

    ; Скачать tmp-данные
    mov [DAP + 6], word 0x0A00 ; 0xA000 .. 0xBxxx
    mov [DAP + 8], eax 
    call load_sector_DAP
    mov [DAP + 6], word 0x0820 ; Вернуть на 0x8200 указатель 

    ; Вычисляем новый кластер
    mov eax, [0xA000 + edx]
    ret

DAP: ; ext-загрузчик 
    dw 0x0010  ; 0 размер DAP = 16
    dw 0x0001  ; 2 читать 1 сектор (поначалу)
    dw 0x0000  ; 4 смещение
    dw 0x0800  ; 6 сегмент
    dq 0       ; 8 номер сектора от 0 до N-1

; 0x8000 Стартовый сектор FAT
; 0x8004 Сектор, данные
; 0x8008 Кол-во секторов на кластер

; -------------------------------------------------------------------------
times 7c00h + (512 - 2 - 64) - $ db 0 ; Остаток заполнить нулями

; 0x1BE ... 0x1FF системная область
; -------------------------------------------------------------------------
times 64 db 0xff ; Таблица разделов будет заполнена оригинальной таблицей
dw 0xAA55 ; Сигнатура boot sector