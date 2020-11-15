
        org     8000h

        include "core/macro.asm"

; Вход в защищенный режим
; ----------------------------------------------------------------------

        cli
        cld
        mov     ax, $0003
        int     10h                 ; Текстовый видеорежим
        lgdt    [GDTR]              ; Глобальная дескрипторная таблица
        lidt    [IDTR]              ; Таблица прерываний
        mov     eax, cr0
        or      al,  1
        mov     cr0, eax
        jmp     10h : pm            ; Переход в PM

; ----------------------------------------------------------------------
GDTR:   dw 4*8 - 1                  ; Лимит GDT (размер - 1)
        dq GDT                      ; Линейный адрес GDT
IDTR:   dw 256*8 - 1                ; Лимит GDT (размер - 1)
        dq 0                        ; Линейный адрес GDT
; ----------------------------------------------------------------------
GDT:    dw 0,      0,    0,     0   ; 00 NULL-дескриптор
        dw 0FFFFh, 0, 9200h, 00CFh  ; 08 32-битный дескриптор данных
        dw 0FFFFh, 0, 9A00h, 00CFh  ; 10 32-bit код
        dw 103,  tss, 8900h, 0040h  ; 18 Свободный TSS
; ----------------------------------------------------------------------

        use32

        include "core/core.asm"
        include "core/irq.asm"
        include "core/fs.asm"

        include "device/fdc.asm"
        include "device/ata.asm"
        include "device/ps2.asm"
        include "device/vga.asm"

        ; Установка сегментов данных
pm:     mov     ax, $0008
        mov     ds, ax
        mov     es, ax
        mov     ss, ax

        mov     esp, $8000
        call    irq_init            ; Переназначить IRQ
        call    ivt_init            ; Установка прерываний
        call    tss_init            ; Инициализация TSS
        call    ps2_init            ; PS2-мышь
        call    tik_init            ; Таймер
        call    mem_init            ; Включение Paging
        call    gdt_init            ; Новое место GDT
        call    fdc_init            ; Создать кеш fd-диска
        call    ata_init            ; Инициализировать hd
        ; vga_init
        ; api_init
        ; fat_init ; поиск fs
        ; pci_init
        mov     esp, HI_STACK       ; Новый стек

        sti
        jmp     $

; ----------------------------------------------------------------------

        include "core/sysvar.asm"
