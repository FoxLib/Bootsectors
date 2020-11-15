
;
; Получение Identify-информации о диске [EAX]
; данная информация пишется по адресу [DISK_SECTOR]
;

dev.pio.DriveIdentify:

        call    dev.pio.SetIOAddr                
        
        ; Отправка 0xA0 for the "master" or 0xB0 for the "slave"
        ; IoWrite8(ioaddr1 + PIO_DEVSEL,  0x40 | (slave << 4))
        
        mov     bx, [dev.pio.ioaddr1]
        lea     dx, [bx + PIO_DEVSEL]
        mov     ax, [dev.pio.slave]
        shl     al, 4
        or      al, 0A0h
        out     dx, al
        
        ; IoWrite8(ioaddr1 + PIO_SECTORS,  0x00)
        ; IoWrite8(ioaddr1 + PIO_LBA_LO,   0x00)
        ; IoWrite8(ioaddr1 + PIO_LBA_MID,  0x00)
        ; IoWrite8(ioaddr1 + PIO_LBA_HI,   0x00)
        
        lea     dx, [bx + PIO_SECTORS]
        mov     al, 0
        out     dx, al
        inc     edx
        out     dx, al
        inc     edx
        out     dx, al
        inc     edx
        out     dx, al
        inc     edx
        inc     edx

        ; Identify Command
        mov     al, 0xEC
        out     dx, al
        
        ; Статус устройства        
        in      al, dx
        and     al, al
        je      .device_not_present
        test    al, 1
        jne     .is_sata            

        ; Ждать пока будет BSY=0
        mov     ecx, 2048
@@:     in      al, dx
        and     al, 0x80
        loopnz  @b
        jnz     .bsy_fail
        
        ; DRQ=0x08 или ERR=0x01
        mov     ecx, 2048
@@:     in      al, dx
        and     al, 09h
        loopz   @b
        jz      .err_fail

        ; Читать 
        lea     dx, [bx + PIO_DATA_PORT]
        mov     edi, DISK_SECTOR
        mov     ecx, 256
        rep     insw
        xor     eax, eax
        ret

; ----------- ОШИБКИ --------------

.device_not_present:
.is_sata:        
.bsy_fail:        
.err_fail:
    
        xor     eax, eax
        dec     eax
        ret
