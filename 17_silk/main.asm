; ----------------------------------------------------------------------
; SILK Operation System for Education Purposes
; ----------------------------------------------------------------------
;
; Это операционная система защищенного режима. Она
; создается для i386 (32-х битного режима). Разрабатывается в учебных
; целях, в первую очередь, изучения архитектуры компьютера на уровне
; системного программирования.
;
; Эта операционная система совершенно свободная, ибо нечего скрывать.
;
; **********************************************************************
; COMPILE AS: sh make.sh
; RUNNING AT: [0000:0800]
; **********************************************************************

    org     0x0800

    cli
    include "core/macros.asm"
    include "core/system_constant.asm"
    
    ; Включение универсального стартового видеорежима    
    mov     ax, 0x0012
    int     0x10
    
    include "core/enter_to_protected.asm"
    use32
    
; Системные библиотеки и функции
; **********************************************************************

    include "core/system_data.asm"
    include "core/system_string.asm"
    include "core/invoke_list.asm"
    
    ; Алгоритмы распаковки и упаковки данных
    include "core/deflate/deflate.asm"    
    include "core/deflate/lz77.asm"    

    ; Инициализация драйверов для обработки файловых систем
    include "core/fs/drivers.asm"

    ; Библиотеки для работы с видео и терминалом
    include "core/display/vga.asm"
    
; **********************************************************************
start_protected_mode:
    
    ; Загрузка ссылки на главную задачу ядра (0-й RING)
    mov     ax,  DESCRIPTOR_MAIN_TSS
    ltr     ax

    ; Загрузка сегментов для защищенного режима
    mov     ax,  DESCRIPTOR_DATA_RING0
    mov     es,  ax
    mov     ds,  ax
    mov     ss,  ax
    mov     esp, 0x101000 ; новый стек на 2-м мегабайте

    ; Установка системного таймера на 100 Гц
    mov     al, 0x34
    out     0x43, al
    mov     ax, 0x2E9B
    out     0x40, al ; lsb
    mov     al, ah
    out     0x40, al ; msb    

    ; Инициализация функции
    call display_vga_init
    
    ; Выполнение IRQ-редиректов для новой таблицы IDT
    include "core/irq_redirect_pic.asm"

    ; Определить максимальный размер физической памяти
    include "core/mm/memory_size.asm"

    ; Инициализация таблицы прерываний и обработчиков
    include "core/interrupts.asm"

    ; Включение страничного механизма
    include "core/mm/paging_enable.asm"

;---
    call    fs_drivers_init
    call    fs_rootdisk_unpack

    ; invoke ikernel.kmalloc, 
    invoke  iterm.print_sz, str_kernel.greetings, 7, 0

    sti

    ; Оставляем пока что до лучших времен. Надо написать менеджер FAT16/32.
    jmp     $

; ----------------------------------------------------------------------
silk_eof:

    ; -------------------------------------------
    ; Далее находятся двоичные упакованные данные
    ; Они будут распакованы в область RAM-диска
    ; -------------------------------------------
