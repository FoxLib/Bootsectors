
dev.pio.ioaddr1         dw 0
dev.pio.ioaddr2         dw 0
dev.pio.slave           dw 0
dev.pio.pio2_devsel     dw 0
dev.pio.sector_count    db 1
dev.pio.current_lba     dd 0

; ----------------------------------------------------------------------
; Установка окружения (IoAddr1/2) для запросов 
; EAX = [0,..,3] Номер канала
; ----------------------------------------------------------------------

dev.pio.SetIOAddr:

        ; PRI (1F0h) SEC (170h)
        ; PRI (3F0h) SEC (370h)

        push    ebx
        
        ; ioaddr1 = 0x170 + ((id & 2) ? 0 : 0x80)        
        mov     ebx, eax
        and     bl, 2
        xor     bl, 2
        shl     bl, 6
        add     bx, 170h
        mov     [dev.pio.ioaddr1], bx        
        
        ; ioaddr2 = ioaddr1 | 0x200          
        or      bx, 200h
        mov     [dev.pio.ioaddr2], bx
        
        ; pio2_devsel = ioaddr2 + PIO_DEVSEL
        add     bx, PIO_DEVSEL
        mov     [dev.pio.pio2_devsel], bx
        
        ; slave = id & 1
        mov     bx, ax
        and     bx, 1
        mov     [dev.pio.slave], bx
        pop     ebx
        ret

; ----------------------------------------------------------------------
; Подготовка перед чтением или записью
; EAX - LBA (0..x)
; EDX - Device (0..3)
;  CL - 24h READ
;       34H WRITE
; ----------------------------------------------------------------------

dev.pio.IOPrepare:
        
        mov     [dev.pio.current_lba], eax
        xchg    eax, edx
        and     eax, 3
        call    dev.pio.SetIOAddr
        mov     bx, [dev.pio.ioaddr1]
        
        ; Send 0x40 for the "master" or 0x50 for the "slave"
        mov     ax, [dev.pio.slave]
        shl     al, 4
        or      al, 40h        
        lea     dx, [bx + PIO_DEVSEL]
        out     dx, al
        
        ; IoWrite8(ioaddr1 + PIO_SECTORS, 0xff & (num >> 8))
        mov     al, 0
        lea     dx, [bx + PIO_SECTORS]
        out     dx, al
        
        ; IoWrite8(ioaddr1 + PIO_LBA_LO, 0xff & (lba >> 24))
        mov     al, byte [dev.pio.current_lba + 3]
        lea     dx, [bx + PIO_LBA_LO]       ; 31..24
        out     dx, al
        
        ; IoWrite8(ioaddr1 + PIO_LBA_MID, 0xff & (lba >> 32))
        mov     al, 0
        lea     dx, [bx + PIO_LBA_MID]      ; 39..32
        out     dx, al
        
        ; IoWrite8(ioaddr1 + PIO_LBA_HI, 0xff & (lba >> 40))
        lea     dx, [bx + PIO_LBA_HI]       ; 47..40
        out     dx, al
        
        ; IoWrite8(ioaddr1 + PIO_SECTORS, 0xff & num)
        mov     al, [dev.pio.sector_count] 
        lea     dx, [bx + PIO_SECTORS]
        out     dx, al
        
        ; IoWrite8(ioaddr1 + PIO_LBA_LO,  0xff & (lba))
        mov     al, byte [dev.pio.current_lba + 0]
        lea     dx, [bx + PIO_LBA_LO]       ; 7..0
        out     dx, al
        
        ; IoWrite8(ioaddr1 + PIO_LBA_MID, 0xff & (lba >> 8))
        mov     al, byte [dev.pio.current_lba + 1]
        lea     dx, [bx + PIO_LBA_MID]      ; 15..8
        out     dx, al
        
        ; IoWrite8(ioaddr1 + PIO_LBA_HI,  0xff & (lba >> 16))
        mov     al, byte [dev.pio.current_lba + 2]
        lea     dx, [bx + PIO_LBA_HI]       ; 23..16
        out     dx, al

        ; 24h = READ SECTORS EXT
        ; 34h = WRITE SECTORS EXT
        mov     al, cl
        lea     dx, [bx + PIO_CMD]
        out     dx, al
        
        ; Попытка чтения с 1-го раза
        ; BSY=0, DRQ=0? 
        mov     ecx, 4
@@:     in      al, dx
        and     al, 0x88
        loopnz  @b
        jz      .good
        
        ; Устройство ещё занято, ждём
        ; Подождать, пока не будет BSY=0
@@:     in      al, dx
        and     al, 80h
        jnz     @b
        
        ; ERR=0 и DF=0 ? Это хорошо
        in      al, dx
        and     al, 21h
        je      .good
        
        ; Ошибка!
        xor     eax, eax
        dec     eax
        ret
        
.good:  xor     eax, eax
        ret

