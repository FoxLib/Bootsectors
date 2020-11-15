
        org     7C00h
        macro   brk { xchg bx, bx }        
        
        cli
        cld
        
        ; Stack Pointer должен быть установлен верно (под область boot-сектора)
        xor     ax, ax
        mov     ss, ax
        mov     ds, ax
        mov     sp, 7C00h
        
        ; Номер диска
        mov     [0000h], dl
                
        ; Вызов на INT 13h, проверка на поддержку режима DAP
        mov     ah, 41h
        mov     bx, 55AAh
        int     13h
        mov     si, sz_boot_np
        jc      boot_error
        
        ; Загрузить сектор в память
        mov     ah, 42h
        mov     si, DAP
        int     13h
        mov     si, sz_errload
        jc      boot_error

        ; И перейти к программе
        jmp     0 : 8000h

; ОШИБКИ ЗАГРУЗКИ
; ----------------------------------------------------------------------

sz_boot_np      db "DAP BIOS extension not present", 0
sz_errload      db "DAP can't load 32 kb program", 0

; Выдача в терминал ошибок при загрузке
boot_error:

        lodsb
        and     al, al
        je      stop
        mov     ah, 0Eh
        int     10h
        jmp     boot_error        
stop:   jmp   $

; ЧИТАТЬ ИЗ DAP
; ----------------------------------------------------------------------

DAP:

        dw 0010h  ; 0 | размер DAP = 16
        dw 0040h  ; 2 | читать 64 сектора (32 кб)
        dw 0000h  ; 4 | смещение (=0)
        dw 0800h  ; 6 | сегмент  (=800h) * 10h = 0000:8000
        dq 1      ; 8 | номер сектора от 0 до N-1 (1 = второй сектор)

        ; Заполнить нулями
        times 7c00h + (512 - 2 - 64) - $ db 0

        ; Информация о 4 разделах
        times 64 db $FF

        ; Сигнатура
        dw 0xAA55
