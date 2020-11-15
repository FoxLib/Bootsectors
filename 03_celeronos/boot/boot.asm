; ----------------------------------------------------------------------
; ЧАСТЬ 1. Загрузочный сектор
; 
; Загружается 64 сектора в 0:0800h, начиная со 2-го (32 кб)
; ----------------------------------------------------------------------

    org 0x0010      
    
    ; Отключение interrupts
    cli
    cld

    ; Выгрузка boot-сектора в hi-mem
    mov     si, 0x7C00
    mov     di, 0x0010
    mov     ax, 0x0000
    mov     ds, ax
    mov     [0x03FF], dl        ; Сохранить номер запускного диска
    dec     ax
    mov     es, ax    
    mov     cx, 256
    rep     movsw
    jmp     0xffff : himem
    
himem:

    ; Новые сегменты в real-mode
    mov     ds, ax
    mov     ss, ax
    mov     sp, 0x8000

    ; Проверка на поддержку DAP
    mov     ah, 0x41
    mov     bx, 0x55AA
    int     0x13
    mov     si, sz_boot_np
    jc      boot_error
    
    ; Загрузить сектор в память
    mov     ah, 0x42
    mov     si, DAP
    int     0x13
    mov     si, sz_errload
    jc      boot_error

    ; И перейти к программе
    jmp     0x0000 : 0x0800

; Boot errors
; ----------------------------------------------------------------------

sz_boot_np db "DAP BIOS extension not present", 0
sz_errload db "DAP can't load 32 kb program", 0

boot_error:

    lodsb
    and     al, al
    je      stop
    mov     ah, 0x0E
    int     0x10
    jmp     boot_error
    
stop: jmp   $

; ЧИТАТЬ ИЗ DAP
; ----------------------------------------------------------------------

DAP:

    dw 0x0010  ; 0 | размер DAP = 16
    dw 0x0040  ; 2 | читать 64 сектора (32 кб)
    dw 0x0000  ; 4 | смещение (=0)
    dw 0x0080  ; 6 | сегмент  (=80h) * 10h = 0000:0800)
    dq 1       ; 8 | номер сектора от 0 до N-1 (1=второй сектор)

    ; Заполнить нулями
    times 7c00h + (512 - 2 - 64) - $ db 0

    ; Информация о 4 разделах
    times 64 db 0

    ; Сигнатура
    dw 0xAA55
