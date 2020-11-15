;
; ----------------------------------------------------------------------
; Чтение данных с диска
; ----------------------------------------------------------------------
;
; eax - номер сектора [0..n]
;  dl - номер диска [0..3]
; edi - адрес записи
;
; @return  0 SUCCESS
;         -1 FAILED

dev.pio.Read:

        push    edx
        mov     cl, 24h
        call    dev.pio.IOPrepare
        pop     edx
        and     al, al
        jnz     .err
        
        ; PRI=1F0h | SEC=170h
        ; ioaddr_data = 0x170 + PIO_DATA_PORT + ((id & 2) ? 0 : 0x80)
        
        mov     bx, 80h
        test    dl, 2
        jz      @f
        mov     bx, 00h
@@:     or      bx, 170h
        mov     dx, bx
        
        ; Чтение данных
        mov     ecx, 256
        rep     insw
        xor     eax, eax   
.err:   ret
