; reference ATA_PORTS [lib/data.asm]

; Драйвер ATA
; ------------

ATA_DATA           EQU 0 ; Data port
ATA_FEATURES       EQU 1 ; Usually used for ATAPI devices.
ATA_SECT_COUNT     EQU 2 ; Number of sectors to read/write (0 is a special value).
ATA_LBA_LO         EQU 3 ; LBAlo
ATA_LBA_MID        EQU 4 ; LBAmid
ATA_LBA_HI         EQU 5 ; LBAhi
ATA_DRIVE          EQU 6 ; Drive 
ATA_CMD_STATUS     EQU 7 ; Command port / Regular Status port

; Типы драйва
ATADEV_UNKNOWN     EQU 0
ATADEV_PATA        EQU 1 ; ATA
ATADEV_PATAPI      EQU 2 ; ATAPI
ATADEV_SATA        EQU 3 ; SATA
ATADEV_SATAPI      EQU 4 ; ATAPI

; Инициализация устройств ATA и регистрация их в системе docs/ata.txt
; ----------------------------------------------------------------------------------------------------------
ATA_init_devices:

    ; Проверка всех 8 возможных устройств ATA    
    ; и запись информации о них в [DS:ATA_PORTS]
    ; ---
    invk3 ATA_identify, 0x1F0, 0, 0 ; ATA-0
    invk3 ATA_identify, 0x1F0, 1, 1 ; ATA-1
    invk3 ATA_identify, 0x170, 0, 2 ; ATA-2
    invk3 ATA_identify, 0x170, 1, 3 ; ATA-3
    invk3 ATA_identify, 0x1E0, 0, 4 ; ATA-4
    invk3 ATA_identify, 0x1E0, 1, 5 ; ATA-5
    invk3 ATA_identify, 0x160, 0, 6 ; ATA-6
    invk3 ATA_identify, 0x160, 1, 7 ; ATA-7   

    ret    

; par1 = "база": {0x1F0, 0x170, 0x1E0, 0x160}
; par2 = "slave": {0, 1}
; par3 = номер 0..7 устройства
; ----------------------------------------------------------------------------------------------------------
; возврат EAX = 0...

ATA_identify:

    create_frame 0

    ; Адрес записи
    mov edi, [par3]
    shl edi, 11
    add edi, ata_info

    ; Определить тип устройства
    mov dx, [par1] ; base
    add dx, ATA_DRIVE
    mov ax, [par2] ; slave
    shl al, 4
    or  al, 0xA0 ; al = 0xA0 | (slavebit << 4)
    out dx, al

    ; Отсылка команды IDENTIFY
    mov al, 0
    mov dx, [par1]
    add dx, ATA_SECT_COUNT
    out dx, al ; sect_count = 0
    inc dx
    out dx, al ; lo = 0
    inc dx
    out dx, al ; mid = 0
    inc dx
    out dx, al ; hi = 0
    add dx, 2
    mov al, 0xEC ; IDENTIFY
    out dx, al

    ; Проверка на сущестование драйва
    in al, dx
    and al, al
    je .drive_err

    ; -----
    mov si, 65535

.poll:

    ; Чтение CH и CL
    mov dx, [par1]
    add dx, ATA_LBA_MID
    in  al, dx
    mov cl, al ; cl=mid
    inc dx
    in  al, dx
    mov ch, al ; ch=hi
    add dx, 2
    in  al, dx ; al=status

    ; Проверка на устройство
    cmp cx, 0xEB14
    je .is_PATAPI

    cmp cx, 0x6996
    je .is_SATAPI

    cmp cx, 0xC33C
    je .is_SATA

    ; Ожидание освобождения устройства или ошибки
    ; ----
    test al, 0x80 ; BSY=0 Устройство освободилось 
    je .free

    test al, 0x08
    jne .free    ; DRQ=1 Устройство готово принять данные)

    test al, 0x01
    jne .drive_err ; ERR=1 Ошибка

    dec si
    jne .poll

    ; Устройство так и не освободилось
    jmp .drive_err

.free:

    ; Если устройство либо освободилось, либо готово DRQ, и CX = 0, это PATA
    cmp cx, 0
    je  .is_PATA 

    ; Иначе ошибка драйва
    jmp .drive_err

; --- типы 
.is_PATAPI:

    mov eax, ATADEV_PATAPI
    jmp .exit

.is_PATA:

    mov eax, ATADEV_PATA
    jmp .exit

.is_SATAPI:

    mov eax, ATADEV_SATAPI
    jmp .exit

.is_SATA:

    mov eax, ATADEV_SATA
    jmp .exit

.drive_err:

    mov eax, ATADEV_UNKNOWN
    leave
    ret

; --- "хороший" выход
.exit:

    mov dx, [par1]
    mov cx, 256
    rep insw ; только INSW

    ; Записать тип ATA
    mov edi, [par3]
    mov [ATA_PORTS + 8*edi + 4], ax

    ; Работает только для ATA 
    cmp eax, ATADEV_PATA
    jne .fin

    ; Скачать сектор 0, если можно и проверить, можно ли?   
    ; ----
    mov eax, [par3]
    shl eax, 11
    add eax, ata_boot
    
    ;               drive   lba sectors куда писать
    invk4 ATA_read, [par3], 0,  1,      eax

    ; сектор 0 прочелся успешно
    and eax, eax
    je  .fin    

    ; Записываем, что старт начинается с 1-го сектора
    mov [ATA_PORTS + 8*edi + 6], byte 1

    ; Новый расчет адреса
    mov eax, [par3]
    shl eax, 11
    add eax, ata_boot

    ; С 1-го сектора, 1 сектор 
    invk4 ATA_read, [par3], 1, 1, eax

.fin:    
    leave
    ret

; Чтение сектора с диска PAR1, сектор номер PAR2 (lba=0..n-1), секторов PAR3 (1..m), PAR4 [edi]
; ----------------------------------------------------------------------------------------------------------
ATA_read:

    create_frame 0

    push edi    
    mov  esi, [par1]

    ; номер порта
    mov dx, [ATA_PORTS + esi*8] ; base io addr

    ; --- записать количество секторов и адрес ---
    mov al, [par3 + 1] ; sector_count = 0xff00
    add dx, 2
    out dx, al 

    inc dx
    mov al, [par2 + 3] ; lba4 24..31
    out dx, al

    inc dx
    mov al, 0
    out dx, al ; lba5 = 0
    inc dx
    out dx, al ; lba6 = 0

    sub dx, 3
    mov al, [par3]
    out dx, al ; sectors_count = 0x00ff

    inc dx
    mov al, [par2]
    out dx, al ; lba1

    inc dx
    mov al, [par2 + 1]
    out dx, al ; lba2

    inc dx
    mov al, [par2 + 2]
    out dx, al ; lba3
    inc dx

    ; ---- команда чтения сектора    
    mov al, [ATA_PORTS + esi*8 + 2] ; slave_bit
    shl al, 4
    or  al, 0xA0 ; 0xA0 | (slave_bit << 4)
    out dx, al

    inc dx
    mov al, 0x24
    out dx, al ; Сигнал на ЧТЕНИЕ

    ; --- проверка статуса
    mov cx, 65535
    
    ; опрос ожидания в цикле
.poll:

    in al, dx
    test al, 0x01
    jne .ERR ; ERR=1 (ошибка?)
    test al, 0x80
    je .OK ; BUSY=0 (освободился?)
    test al, 0x08
    jne .OK ; DRQ=1 (готовность принять данные?)
    loop .poll

    ; При чтении возникла ошибка   
.ERR: ; ------

    mov eax, 1 ; Ошибка первоначального чтения
    jmp .leave   

     ; Чтение успешно    
.OK: ; ------

    in al, dx
    test al, 0x08
    je .BROKE

    ; ... чтение сектора ...
    sub dx, 7
    mov edi, [par4]
    mov ecx, 256    
    rep insw ; только INSW
    add dx, 7

    ; К след. сектору
    dec dword [par3]
    jne .OK

    xor eax, eax
    jmp .leave

    ; Команда оборвана
.BROKE: ; ------

    mov eax, 2

.leave:

    pop edi
    leave
    ret