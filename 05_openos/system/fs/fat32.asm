; Структура находящаяся по адресу [const_FS_LIST] x 64 байт запись
; ----
; 00 dword  lba начала файловой системы
; 04 dword  размер раздела в секторах

bpb_lba_start            equ 0x00 ; 4 Старт раздела
bpb_disk_size            equ 0x04 ; 4 Размер диска в секторах
bpb_fat32_cluster_size   equ 0x08 ; 1 Количество секторов на кластер
bpb_fat32_reserved       equ 0x0C ; 2 Резервированых секторов
bpb_fat32_count          equ 0x10 ; 1 Количество fat
bpb_fat32_size           equ 0x14 ; 4 Количество секторов в fat32
bpb_fat32_root           equ 0x18 ; 4 Корень файловой системы
bpb_fat32_start          equ 0x1C ; 4 Сектор с реальным началом FAT
bpb_fat32_data           equ 0x20 ; 4 Сектор с началом DATA-секции

; -----------------------------------------------
; Поиск файловых систем на дисках
; -----------------------------------------------
search_filesystems:

        ; Определить, куда и что писать
        mov [sector_number], byte 1
        mov [rw_into], dword const_SECTOR

        mov esi, ata_reg_devices
        mov ecx, 8    
        xor ebx, ebx  ; disk_id=0..7

        ; Писать данные по обнаруженным FAT32 в [const_FS_LIST]
        mov edx, const_FS_LIST

.c1:    ; Чтение информации о типе диска
        mov ax, [esi + 4]
        cmp ax, ATADEV_PATA
        jne @f    

        ; Просканировать первый сектор (BPB) и записать информацию
        call .fetch_partitions

@@:     add esi, 8
        loop .c1
        ret

; -------------------------------
; Сканирование Partitions
; -------------------------------

.fetch_partitions:

        push eax ebx ecx esi

        ; Чтение нулевого сектора диска
        xor  eax, eax        
        call disk_read_sector ; eax(lba), ebx(disk)

        mov cl, 4        
        mov esi, const_SECTOR + 0x01BE

.c2:
        ; файловая система fat32?
        cmp [esi + 4], byte 0x0B 
        je .ifat32
        jmp .not_fat32

.ifat32:

        ; Сохранить размер раздела
        mov eax, [esi + 12]
        mov [edx + bpb_disk_size], eax

        ; Записывается LBA начала файловой системы. Прочитать BPB
        mov eax, [esi + 8]
        mov [edx + bpb_lba_start], eax
        call disk_read_sector

        ; Читать с начала
        mov esi, const_SECTOR

        ; Определить ключевые поля и вычислить смещения
        movzx eax, byte [esi + 0x0D]
        mov [edx + bpb_fat32_cluster_size], eax
        movzx eax, word [esi + 0x0E]
        mov [edx + bpb_fat32_reserved], eax
        movzx eax, byte [esi + 0x10]
        mov [edx + bpb_fat32_count], eax
        movzx eax, byte [esi + 0x24]
        mov [edx + bpb_fat32_size], eax
        movzx eax, byte [esi + 0x2C]
        mov [edx + bpb_fat32_root], eax

        ; Вычислить сектор, с которого начинается FAT
        mov eax, [edx + bpb_fat32_reserved]
        add eax, [edx + bpb_lba_start]
        mov [edx + bpb_fat32_start], eax

        ; Вычислить сектор, откуда начинается DATA
        mov  eax, [edx + bpb_fat32_count]
        push edx
        mul  dword [edx + bpb_fat32_size]
        pop  edx
        add  eax, [edx + bpb_lba_start]
        mov [edx + bpb_fat32_data], eax

        ; К следующему разделу
        ; --------------------
        add edx, 64

.not_fat32:

        loop .c2
        pop esi ecx ebx eax 
        ret
        