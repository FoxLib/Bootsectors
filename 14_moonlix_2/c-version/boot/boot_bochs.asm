; Отладочный код загрузчика под виртуальную дискету
; Код предназначен только для единственной цели - запуск OS в Bochs
; sudo dd if=fdd.img of=/dev/sdf bs=512

    include 'macro.asm'

    org 0x7C00

    ; При загрузке boot-sector, BIOS начинает исполнять код в 0:7C00
    jmp short BootStart
    db  0x90

    ; Макрос, описывающий стандартный FAT12-заголовок
    BPBFAT12

BootStart:    

    xor cx, cx
    mov ss, cx
    mov ds, cx
    xor sp, sp

    ; Инициализация сегментов и стека (0:0)
    mov [0x7FFF], dl

    ; Проверка на существование расширения BIOS
    mov ah, 0x41
    mov bx, 0x55AA    
    int 0x13
    jc  bochs_boots

    xor ax, ax
    mov dl, [0x7FFF]
    int 0x13 ; reset disk drive

    ; Скачать сектора
    mov ah, 0x42
    mov si, DAP
    mov dl, [0x7FFF]
    int 0x13
    jmp far 0:0x8000

; ---------------------- DEBUG ----------------------    
bochs_boots:

    mov ax, 0x0800
    mov es, ax

    ; Скачать 63 сектора, начиная со 2-го (32кб загрузочный код)
    mov ax, 0x023F
    mov cx, 0x0002
    xor bx, bx
    mov dh, 0x00    
    int 0x13

    ; Переход к скачанному коду
    jmp far 0:0x8000

DAP:
    db 0x10, 0 ; размер DAP = 16
    dw 0x3F    ; читать 64 сектора
    dw 0x8000  ; смещение
    dw 0x0     ; сегмент
    dq 1       ; читать первый сектор (после MBR)

    BOOTSIGNATURE