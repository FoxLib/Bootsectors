; ----------------------------------------------------------------------
        include "headers.asm"
; ----------------------------------------------------------------------

        org     8000h
        macro   brk { xchg bx, bx }

        use16

        cli
        mov     ax, 0003h           ; text 80x25; vga 640x480
        int     10h
        lgdt    [GDTR]              ; Установка GDT
        lidt    [IDTR]              ; Установка IDT
        mov     eax, cr0            ; Переход в защищенный режим
        or      al, 1
        mov     cr0, eax
        jmp     10h : pm

; ----------------------------------------------------------------------
GDTR:   dw      3*8-1
        dd      GDT
IDTR:   dw      256*8-1
        dd      0
GDT:    dw      0,      0,      0,      0
        dw      0FFFFh, 0,  9200h,  00CFh      ; 32bit data
        dw      0FFFFh, 0,  9A00h,  00CFh      ; 32bit code
; ----------------------------------------------------------------------

        use32

pm:     mov     ax, 08h
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     fs, ax
        mov     gs, ax

        mov     al, [$0000]
        mov     [bios_disk_boot], al        ; Disk Boot BIOS
        mov     [dynamic], sysdynamic       ; Обозначить границу памяти

        ; Инициализация экрана
        call    term_init
        mov     al, $07
        call    term_cls
        mov     esi, s_welcome_string
        call    term_print

        call    irq_init                    ; Инициализация IRQ
        call    ivt_init                    ; Инициализация IVT

        mov     esi, s_ps2_init_alert
        call    term_print
        call    ps2_init                    ; Инициализация PS/2
        call    fdc_init                    ; Инициализация FDC

        mov     esi, s_complete_config
        call    term_print

        sti
        jmp     $

; ----------------------------------------------------------------------
; Подключение модулей
; ----------------------------------------------------------------------

include "irq.asm"
include "fdc.asm"
include "ps2.asm"
include "term.asm"
include "strings.asm"
include "data.asm"

sysdynamic:
