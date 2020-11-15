
        org     8000h

        define  BX_DBG 0
        include "core/defines.asm"

; ----------------------------------------------------------------------
; PIKOS: ОТ АВТОРА. 15 ноября 2017
;
;       Не является операционной системой в глобальном смысле. Это
;       игрушечная ОС, которая предназначена для изучения компьютера и
;       просто эксплуатируется в учебных целях и навыке владения
;       ассемблером, а также для того, чтобы поддерживать интеллект в
;       состоянии повышенной готовности к написанию кода. Я начал этот
;       проект: >> 15 ноября 2017 << а значит, через ровно 7 дней я его
;       закончу. Такие вот у меня новости. Счастливого пользования!
;
;       ОПЕРАЦИОННАЯ СИСТЕМА ЯВЛЯЕТСЯ УЧЕБНОЙ!
; ----------------------------------------------------------------------

        cli
        cld
        mov     ax, 0
        mov     ss, ax
        mov     ds, ax
        mov     es, ax
        mov     sp, 7C00h

        ; Установка видеоразрешения
        call    vesa.SetMaximalMode

        ; Переключение Real -> Protected режим
        lgdt    [cs: GDTR]
        lidt    [cs: IDTR]
        mov     [cs: TSS + 64h], word 104  ; IOPB offset
        mov     eax, cr0
        or      al, 1
        mov     cr0, eax    
        jmp     0010h : SwitchProtectedMode

; ----------------------------------------------------------------------

        include "vesa/vesa.asm"

; ----------------------------------------------------------------------

GDTR:   ; Регистр глобальной дескрипторной таблицы
        dw 4*8 - 1          ; Лимит GDT (размер - 1)
        dd GDT              ; Линейный адрес GDT

IDTR:   ; Регистр глобальной таблицы прерываний
        dw 256*8 - 1        ; Лимит IDT (размер - 1)
        dd 0                ; Линейный адрес IDT

; Дескрипторная таблица
GDT:    dw 0,      0,     0,     0      ; 00 NULL-дескриптор
        dw 0FFFFh, 0,     9200h, 00CFh  ; 08 32-битный дескриптор данных
        dw 0FFFFh, 0,     9A00h, 00CFh  ; 10 32-bit код
        dw 103h,   TSS,   8900h, 0040h  ; 18 TSS

; ----------------------------------------------------------------------

        use32

        ; Ядро
        include     "core/pic_init.asm"
        include     "core/isr_make.asm"
        include     "core/set_timer_100.asm"

        ; Память
        include     "mm/mem_size.asm"
        include     "mm/paging_init.asm"
        include     "mm/calloc.asm"

        ; Устройства
        include     "dev/isr_keyboard.asm"            
        include     "dev/pio/io_prepare.asm"
        include     "dev/pio/drive_detection.asm"
        include     "dev/pio/drive_identify.asm"
        include     "dev/pio/rw.asm"
        
        ; Файловая система
        include     "fs/pio/disk_map.asm"

        ; Vesa
        include     "vesa/common.asm"
        include     "vesa/circle.asm"
        include     "vesa/print_utf8.asm"

SwitchProtectedMode:

        mov     ax, 0008h           ; Установить DATA Ring-0 сегменты
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     fs, ax
        mov     gs, ax
        mov     esp, 400000h
        mov     ax, 18h             ; Загрузить в TR -> TSS
        ltr     ax        

        mov     bx, IRQ_KEYBOARD
        call    core.PicInit
        call    core.ISRMake        ; Создание таблиц прерываний
        call    core.SetTimer100
        call    mm.MemSize          ; Определение размера памяти
        call    mm.PagingInit       ; Заполнить страницы

        mov     ax, [vesa.bgcolor]
        call    vesa.Clear          ; Очистить экран в стандартный цвет

        brk
        call    fs.pio.DiskMap     ; Поиск файловых систем на дисках

mov     eax, 0
mov     edx, 0
mov     edi, DISK_SECTOR
call    dev.pio.Read
                

        ;xor     eax, eax
        ;mov     eax, 0
        ;call    dev.pio.DriveDetection


        ; Просмотреть информацию о дисках
        ;

        ;
        ; call      mm.Calloc
        ; mov       [vesa.sysfont], eax

        ; mov       esi, & "/sys.fnt"
        ; mov       edi, [vesa.sysfont]
        ; call      fs.pio.LoadFile

        sti

        jmp     $

; ----------------------------------------------------------------------
; BINARY DATA
; ----------------------------------------------------------------------

sysfont: file "vesa/font8x8.bin"
