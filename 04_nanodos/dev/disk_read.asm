; https://en.wikipedia.org/wiki/INT_13H#INT_13h_AH.3D42h:_Extended_Read_Sectors_From_Drive
; Читать ОДИН сектор (из DL) во временную область [0000:dos.param.tmp_sector]

dev.DiskRead:

        push    ds ax si
        mov     ax, cs
        mov     ds, ax
        mov     ah, 42h        
        mov     si, dev.DiskRead.DAP
        int     13h
        pop     si ax ds
        ret

; Читать сектор EAX 
dev.DiskReadA:

        push    dx
        mov     [cs: dev.DiskRead.DAP + 8], eax
        mov     dl, [cs: dos.param.drive_letter]
        call    dev.DiskRead
        pop     dx
        ret

; Данные для DAP
dev.DiskRead.DAP:

        ; 0 Размер DAP = 16
        dw 00010h 
        
        ; 2 Читать 1 сектор
        dw 00001h  
        
        ; 4 Смещение : 6 Сегмент
        dw dos.param.tmp_sector, 0
        
        ; 8 Номер сектора от 0 до n-1
        dq 0
