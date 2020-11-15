;
; Определение дисков на IDE шлейфе (до 4 шт)
; http://wiki.osdev.org/ATA_PIO_Mode
;

; ----------------------------------------------------------------------
; Определить тип диска
; EAX = [0..3] Номер канала
; Возврат EAX - тип устройства
; ----------------------------------------------------------------------

dev.pio.DriveDetection:
        
        call    dev.pio.SetIOAddr

        ; 1. "Software Reset" сброс шины для нормальной операции
        mov     dx, [dev.pio.pio2_devsel]
        mov     al, 4
        out     dx, al
        mov     al, 0
        out     dx, al
        in      al, dx
        in      al, dx
        in      al, dx
        in      al, dx
                
        ; 2. Проверить 7=BSY(0) и 6=RDY(1)
        ; Тестировать 1024 раз, если так и не получилось, то ATADEV_FAILED
        
        mov     ecx, 1024
@@:     in      al, dx
        and     al, 0xC0
        cmp     al, 0x40
        loopnz  @b
        mov     ax, ATADEV_FAILED
        jnz     .exit

        ; 3. Шлем команду на определение девайса
        mov     ax, [dev.pio.slave]
        shl     al, 4
        or      al, 0xA0
        mov     dx, [dev.pio.ioaddr1]
        add     dx, PIO_DEVSEL
        out     dx, al
        
        ; Ждать 4Т
        mov     dx, [dev.pio.pio2_devsel]
        in      al, dx
        in      al, dx
        in      al, dx
        in      al, dx

        ; 4. Чтение Signature в регистр CX
        mov     dx, [dev.pio.ioaddr1]
        add     dx, PIO_LBA_MID
        in      al, dx
        mov     cl, al
        inc     dx
        in      al, dx
        mov     ch, al
                
        ; $0000 ATA
        mov     eax, ATADEV_PATA
        cmp     cx, $0000
        je      .exit       
              
        ; $EB14 ATAPI
        mov     eax, ATADEV_PATAPI
        cmp     cx, $EB14
        je      .exit    
            
        ; $9669 SATAPI
        mov     eax, ATADEV_SATAPI
        cmp     cx, $9669
        je      .exit        
        
        ; $C33C SATA
        mov     eax, ATADEV_SATA
        cmp     cx, $C33C
        je      .exit

        mov     eax, ATADEV_UNKNOWN
.exit:  ret
        
