; ---------------------------------------------
; Работа с жестким диском
; ---------------------------------------------

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

; Инициализация устройств ATA и регистрация их в системе
; +0 Base - базовый порт
; +2 S    - слейв (0/1)
; +4 T    - тип диска (ATADEV_PATA, ATADEV_SATA...)
; +6 F    - первый сектор начинается с 0 или 1

ata_reg_devices:

        ;  BASE   S  T  F
        dw 0x1F0, 0, 0, 0 ; ATA-0
        dw 0x1F0, 1, 0, 0 ; ATA-1
        dw 0x170, 0, 0, 0 ; ATA-2
        dw 0x170, 1, 0, 0 ; ATA-3
        dw 0x1E0, 0, 0, 0 ; ATA-4
        dw 0x1E0, 1, 0, 0 ; ATA-5
        dw 0x160, 0, 0, 0 ; ATA-6
        dw 0x160, 1, 0, 0 ; ATA-7    

; Количество секторов для считывания или записи
sector_number db 1

; Куда читать или откуда писать данные
rw_into       dd 0x8FE00

; ----------------------------------------------------------------------------------------------------------
; void () Идентификация дисков (всех 8 вариантов)
; ----------------------------------------------------------------------------------------------------------

global_disk_identity:

        xor  esi, esi
        mov  ecx, 8
@@:     push ecx
        call ata_identify
        inc  esi
        pop  ecx
        loop @b
        ret

; ----------------------------------------------------------------------------------------------------------
; RESET 
; ----------------------------------------------------------------------------------------------------------
srst_ata_st:

        push eax
        ;add  dx, ATA_DRIVE
        mov  al, 4
        out  dx, al                        ; do a "software reset" on the bus
        xor  eax, eax
        out  dx, al                        ; reset the bus to normal operation
        in   al, dx                        ; it might take 4 tries for status bits to reset
        in   al, dx                        ; ie. do a 400ns delay
        in   al, dx
        in   al, dx
.rdylp:
        in  al, dx
        and al, 0xc0                        ; check BSY and RDY
        cmp al, 0x40                        ; want BSY clear and RDY set
        jne short .rdylp
        pop eax
        ret

; ----------------------------------------------------------------------------------------------------------
; int (esi: devid) определение типа устройства и данных по доступу к диску
; ----------------------------------------------------------------------------------------------------------

ata_identify:

        push esi

        ; Получение базового адреса base
        mov  dx, [ata_reg_devices + 8*esi] ; BASE-IO
        add  dx, ATA_DRIVE

        ; slave bit al = 0xA0 | (slavebit << 4)
        mov  al, [ata_reg_devices + 8*esi + 2] 
        shl  al, 4
        or   al, 0xA0
        out  dx, al   ; +0

        ; Отсылка команды <IDENTIFY>
        mov  al, 0
        mov  dx, [ata_reg_devices + 8*esi] ; BASE-IO
        add  dx, ATA_SECT_COUNT

        out  dx, al   ; +2 sect_count = 0
        inc  dx
        out  dx, al   ; +3 lo = 0
        inc  dx
        out  dx, al   ; +4 mid = 0
        inc  dx
        out  dx, al   ; +5 hi = 0
        add  dx, 2

        mov  al, 0xEC ; +7 IDENTIFY
        out  dx, al

        ; Проверка на сущестование драйва
        in   al, dx
        and  al, al
        je  .drive_err

        ; -----
        mov  bx, 49152

.poll:  ; Чтение CH и CL (идентификаторы)    
        mov  dx, [ata_reg_devices + 8*esi] ; BASE-IO
        add  dx, ATA_LBA_MID

        ; cl=mid
        in   al, dx
        mov  cl, al 

        ; ch=hi
        inc  dx
        in   al, dx
        mov  ch, al 

        ; al=status
        add  dx, 2
        in   al, dx
        in   al, dx
        in   al, dx
        in   al, dx ; 400ns задержка
        in   al, dx        

        ; Проверка на тип устройства
        ; ---------------------------
        cmp  cx, 0xEB14
        je  .is_PATAPI

        cmp  cx, 0x6996
        je  .is_SATAPI

        cmp  cx, 0xC33C
        je  .is_SATA

        ; Ожидание освобождения устройства или ошибки
        ; ---------------------------

        test al, 0x01
        jne  .drive_err ; ERR=1 Если ошибка устройства, то пропуск

        test al, 0x80  ; BSY=0 Устройство освободилось? Если 0 - то продолжим тест
        jne  .thenpoll ; если bsy=1, то продолжить polling

        test al, 0x08
        jne  .free     ; DRQ=1 Устройство готово принять данные) 

.thenpoll:

        dec  bx
        jne .poll

        ; Устройство так и не освободилось
        jmp .drive_err

.free:  ; Если устройство либо освободилось, либо готово DRQ, и CX = 0, это PATA
        cmp  cx, 0
        je  .is_PATA 

        ; Иначе ошибка драйва
        jmp .drive_err

; --- типы 
.is_PATAPI:

        mov  eax, ATADEV_PATAPI
        jmp .exit

.is_PATA:

        mov  eax, ATADEV_PATA
        jmp .exit

.is_SATAPI:

        mov  eax, ATADEV_SATAPI
        jmp .exit

.is_SATA:

        mov  eax, ATADEV_SATA
        jmp .exit

.drive_err:

        mov  eax, ATADEV_UNKNOWN
        jmp .fin

.exit:  ; --- "хороший" выход ---

        ; Записать тип диска (0,1=ATA,...)
        mov [ata_reg_devices + 8*esi + 4], ax

        ; Вычисление адреса, куда будет записана информация об IDE
        ; (см. documents/memory.txt), esi = 0..7
        mov  edi, esi
        shl  edi, 9
        add  edi, const_IDE_VENDOR   ; edi = const_IDE_VENDOR + 512*disk_id

        ; Получение данных об устройстве. Только INSW! никак иначе
        mov  dx, [ata_reg_devices + 8*esi]
        mov  ecx, 256
        rep  insw

        ; Если это не pATA, то пропуск инициализации проверки на первый сектор (0 или 1)
        cmp  eax, ATADEV_PATA
        jne .fin

        ; Скачать сектор 0, если можно и проверить, можно ли?   
        call2 read_sector, esi, 0
        and  eax, eax
        je  .fin    

        ; В случае, если сектор 0 не прочелся, то тогда начинается с 1-го сектора 
        mov [ata_reg_devices + 8*esi + 6], byte 1

.fin:   pop esi
        ret

; ----------------------------------------------------------------------------------------------------------
; int (uint drive_id, uint lba) Чтение сектора с диска | drive_id = 0..7 | lba = 0..n
; В случае если ответ = 0, то чтение успешно
; ----------------------------------------------------------------------------------------------------------

read_sector:

        enter 0, 0

        push edi ebx  
        mov  esi, [par1]
        
        ; Определение стартового LBA
        movzx eax, word [ata_reg_devices + 8*esi + 6] 
        add [par2], eax
        
        ; номер порта
        mov  dx, [ata_reg_devices + 8*esi] ; base io addr

        ; ---- команда чтения сектора    
        add  dx, 6
        mov  al, [ata_reg_devices + 8*esi + 2] ; slave_bit
        shl  al, 4
        or   al, 0x40        ; 0x40 | (slave_bit << 4)
        out  dx, al
        sub dx, 4

        ; --- записать количество секторов и адрес ---
        mov  al, 0x00        ; hi sector_count (0xff00)
        out  dx, al 

        inc  dx
        mov  al, [par2 + 3] ; lba4 24..31
        out  dx, al

        inc  dx
        mov  al, 0
        out  dx, al ; lba5 = 0
        inc  dx
        out  dx, al ; lba6 = 0

        sub  dx, 3
        mov  al, [sector_number] ; по умолчанию 1
        out  dx, al              ; sectors_count = 0x00ff

        inc  dx
        mov  al, [par2]
        out  dx, al ; lba1

        inc  dx
        mov  al, [par2 + 1]
        out  dx, al ; lba2

        inc  dx
        mov  al, [par2 + 2]
        out  dx, al ; lba3
        inc  dx
        inc  dx

        mov  al, 0x24
        out  dx, al   ; Сигнал на ЧТЕНИЕ

        ; --- проверка статуса
        mov  bx, 49152
    
        ; опрос ожидания в цикле
.poll:  in   al, dx
        test al, 0x01
        jne .err ; ERR=1 (ошибка?)
        test al, 0x80
        je .ok ; BUSY=0 (освободился?)
        test al, 0x08
        jne .ok ; DRQ=1 (готовность принять данные?)
        dec  bx
        jne .poll

        ; При чтении возникла ошибка   
.err:   mov eax, 1 ; Ошибка первоначального чтения
        jmp .leave   

        ; Прочитать сектор
        ; --------
.ok:    movzx bx, byte [sector_number]
.read:  in   al, dx
        test al, 0x08
        je  .brk

        ; ... чтение сектора ...
        sub  dx, 7
        mov  edi, [rw_into]
        mov  ecx, 256    
        rep  insw ; только INSW
        add  dx, 7

        ; К след. сектору
        dec  bx
        jne .read

        ; Чтение прошло успешно
        xor  eax, eax
        jmp .leave

        ; Команда оборвана
.brk:   mov  eax, 1
.leave: pop  ebx edi
        leave
        ret  8

; --------------------------------------------------------------------------
; Чтение сектора, упрощенно
; eax (номер сектора 0..n)
; ebx (номер диска 0..7)
; --------------------------------------------------------------------------

disk_read_sector:

        pusha
        and   ebx, 0x0F ; номер диска      
        call2 read_sector, ebx, eax
        popa
        ret