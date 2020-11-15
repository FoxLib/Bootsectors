; COMPILE
; -------
; fasm boot12.asm && php ../tools/fat32.php disk.img boot boot12.bin
; bochs -f dao.bxrc -q
; -------

macro brk { xchg bx, bx } ; bochs debug

org 7C00h

    jmp short begin
    db 0x90

; ---------------------------------------------------------------------------------------------------------------------
; Пропуск BIOS PARAMETER BLOCK
; ---------------------------------------------------------------------------------------------------------------------

    bpb_BytesPerSector    EQU 0x7C0B
    bpb_SectorsPerCluster EQU 0x7C0D
    bpb_ReservedSectors   EQU 0x7C0E
    bpb_NumberOfFATs      EQU 0x7C10
    bpb_RootEntries       EQU 0x7C11
    bpb_NumberOfSectors   EQU 0x7C13
    bpb_SectorsPerFAT     EQU 0x7C16
    bpb_SectorsPerHead    EQU 0x7C18
    bpb_HeadsPerCylinder  EQU 0x7C1A
    bpb_DriveAutoDetect   EQU 0x7C3E 

    db (40h - 3) dup (0xFF)

; ----------------------------------------------------------------------	
; ДЛЯ ИНФЫ http://www.rayknights.org/pc_boot/w95bboot.htm	
; ----------------------------------------------------------------------
; РАСПРЕДЕЛЕНИЕ ПАМЯТИ СТАНДАРТНОЙ FAT12
;
; 0x7C00 .. 0x7FFF Boot Sector
; 0x8000 .. 0x91FF FAT12
; 0x9200 .. 0xADFF Root-Entries
; 0xAE00 ......... Program
;
; ----------------------------------------------------------------------

begin:

    mov ax, 0x0800
    mov es, ax
    xor ax, ax
    mov ds, ax
    mov ss, ax
    xor sp, sp    

    ; Автодетект. Если floppy недоступен - то это HDD
    mov ax, 0x0201
    xor bx, bx
    mov cx, 0x0001
    mov dx, 0x0000
    int 0x13
    jnb is_not_hdd

    mov [bpb_DriveAutoDetect], byte 0x80

is_not_hdd:

    movzx eax, word [bpb_ReservedSectors]
    push  eax

    ; Получаем цилиндр/дорожку для начала FAT
    call read_sector

    mov al, [bpb_SectorsPerFAT] ; Кол-во секторов FAT
    mov ah, 0x02 ; Чтение
    mov dl, byte [cs:bpb_DriveAutoDetect] ; DiskDrive = Floopy / HDD
    xor bx, bx
    int 0x13     ; Грузим FAT-таблицу в память (Linear = 0x00008000)
    jb load_error

    pop eax

    ; -------
    ; Расчет позиции RootEntries
    ; EAX = 2 * bpb_SectorsPerFAT + bpb_ReservedSectors
    ; -------

    movzx ebx, word [bpb_SectorsPerFAT]
    add   eax, ebx
    add   eax, ebx

    ; Читаем RootEntries
    call read_sector

    ; Позиция в памяти: сразу после FAT
    mov ax,  [bpb_SectorsPerFAT]
    push dx

    ; ax = размер таблицы FAT (bpb_SectorsPerFAT * bpb_BytesPerSector)
    mul word [bpb_BytesPerSector]

    ; bx = адрес начала корневого каталога
    mov bx, ax
    mov di, ax

    ; ax = размер корня в байтах
    mov ax, [bpb_RootEntries]
    shl ax, 5

    ; di - записываем высоту корня
    add di, ax

    ; количество секторов на корень
    xor dx, dx
    div word [bpb_BytesPerSector]
    pop dx

    ; Сохраняем кол-во секторов на корень
    mov bp, ax

    ; Скачать корень
    mov ah, 0x02
    mov dl, byte [cs:bpb_DriveAutoDetect]
    int 0x13
    jb load_error

    ; Поиск LOADER.RUN

read_entry:

    cmp dword [es:bx], 'LOAD'
    jne next_entry
    cmp dword [es:bx + 0x04], 'ER16'
    jne next_entry
    cmp dword [es:bx + 0x07], '6RUN'
    jne next_entry

    ; SI = cluster
    mov si, [es:bx + 0x1A]

    ; ----------
    ; Файл был найден успешно - начинаем читать таблицу FAT12
    ; ----------

    push es
    pop  ds

    ; Начало программы в 0x1000:0000
    mov ax, 0x1000
    mov es, ax

    ; Загрузка цепи (файла) в память
    ; es:0 - буфер вывода сразу за таблицей RootEntries

chain_read:

    mov dx, [ds:0]
    and dx, 0x0FFF  ; dx = EOC

    ; FAT12 получение номера следующего кластера
    mov  ax, si
    mov  cx, si
    add  ax, ax ; ax = 2*si
    add  ax, si ; ax = 2*si + si
    shr  ax, 1  ; ax = 1.5 * si
    mov  si, ax

    ; load cluster onto memory
    pusha

    mov  ax,  [cs:bpb_SectorsPerFAT]
    mul  byte [cs:bpb_NumberOfFATs]
    add  ax, bp
    add  ax, [cs:bpb_ReservedSectors]
    mov  bx, ax

    mov  ax, cx
    sub  ax, 2 ; Вычет 2 резервированных
    movzx cx, byte [cs:bpb_SectorsPerCluster]
    mul  cx
    add  ax, bx

    ; ax = cluster*bpb_SectorsPerCluster + root_entries_sectors + bpb_NumberOfFATs*bpb_SectorsPerFAT + bpb_ReservedSectors
    call read_sector

    xor bx, bx
    mov ah, 0x02
    mov al, byte [cs:bpb_SectorsPerCluster]
    mov dl, byte [cs:bpb_DriveAutoDetect]
    int 0x13

    movzx ax, byte [cs:bpb_SectorsPerCluster]
    mul word [cs:bpb_BytesPerSector]

    ; ax = bpb_SectorsPerCluster * bpb_BytesPerSector / 16 (посегментно)
    shr ax, 4
    mov bx, es
    add ax, bx
    mov es, ax
    popa

    mov  ax, [si]
    test cx, 0x01
    je $+5
    shr ax, 4

    and ax, 0xFFF
    mov si, ax      ; номер следующего кластера

    ; Достигнут конец файла?
    cmp  ax, dx
    jb chain_read

    ; Старт!
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    xor sp, sp
    jmp 0x1000:0

; ----------------------------------------------------------------------

next_entry:

    ; Мы достигли предела
    cmp bx, di
    jnb load_error

    add bx, 0x20
    jmp read_entry

; Ошибки загрузки, останов
load_error:

    mov al, ah
    add al, '0'
    mov ah, 0x0e
    mov bl, 7
    int 0x10
    
    jmp  $+0


; Читает сектор, используя LBA (DX:AX) и INT 0x13
; -----------------------------------------------

; Вход:  EAX - LBA
; Выход: получение параметров DX, CX, AL для диска

read_sector:

    ror eax, 16
    mov dx, ax
    ror eax, 16

; http://www.codenet.ru/progr/dos/int_0012.php

; 02H читать секторы
; вход: DL = номер диска (0 = диск A...; 80H = тв.диск 0; 81H = тв.диск 1)
;       DH = номер головки чтения/записи
;       CH = номер дорожки (цилиндра)(0-n) =¬
;       CL = номер сектора (1-n) ===========¦== См. замечание ниже.
;       AL = число секторов (в сумме не больше чем один цилиндр)

;       ES:BX  => адрес буфера вызывающей программы
;       0:0078 => таблица параметров дискеты (для гибких дисков)
;       0:0104 => таблица параметров тв.диска (для твердых дисков)
;
; выход:
;
;      Carry-флаг=1 при ошибке и код ошибки диска в AH.
;      ES:BX буфер содержит данные, прочитанные с диска
;      замечание: на сектор и цилиндр отводится соответственно 6 и 10 бит:

;             1 1 1 1 1 1
;            +5-4-3-2-1-0-9-8-7-6-5-4-3-2-1-0+
;        CX: ¦c c c c c c c c C C s s s s s s¦
;            +-+-+-+-+-+-+-+-¦-+-+-+-+-+-+-+-+
;                            +======> исп. как старшие биты номера цилиндра

    push bx

    push ax
    push dx

    mov ax,  [cs:bpb_HeadsPerCylinder]                    ; heads = tracks/cylinder
    mul word [cs:bpb_SectorsPerHead]                ; BX = sectors/cyl = tracks/cylinder * sectors/track
    mov bx, ax

    pop dx
    pop ax

    div bx                              ; ax = track, dx = sector within cyl
    xchg al, ah                         ; move bits 0-7 to ah, 8 & 9 to high part of al (0-5 zeroed)
    shl al, 6            ; AX = 76543210 | 98...... (track + sector 0..5 bits)

    mov cx, ax                         ; CX = track (cylinder number), BIOS format
    mov ax, dx
    xor dx, dx

    mov bx, [cs:bpb_SectorsPerHead]

    div bx                            ; ax = head, dx = sector in track
    inc dl                            ; one based sector (normal format)
    or  cl, dl                        ; add to track
    mov dh, al                  ; head number (side)

    pop bx
    ret

; BOOT SIGNATURE
; ----------------------------------------------------------------------

	times 7c00h + (512 - 2) - $ db 0
	dw 0xAA55
