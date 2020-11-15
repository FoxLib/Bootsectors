dt_spaces db '   ', 0 ; тупо пробелы

MEMORY_size dd 0 ; Размер памяти

; ATA PORTS
; ------------------------

ATA_PORTS:

    ;  port   slave  type   start
    ;  0      2      4      6
    dw 0x1F0, 0,     0,     0
    dw 0x1F0, 1,     0,     0
    dw 0x170, 0,     0,     0
    dw 0x170, 1,     0,     0
    dw 0x1E0, 0,     0,     0
    dw 0x1E0, 1,     0,     0
    dw 0x160, 0,     0,     0
    dw 0x160, 1,     0,     0
