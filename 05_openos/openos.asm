; Ассемблирование. Запись на виртуальный диск. Запуск эмулятора.
; fasm openos.asm && ./install/fat32/diskfat32 c.img u "openos.bin" openos.bin && bochs -f openos.bxrc -q
; -----------------------------------------------------------------------------------------------------------------
        
        ; Отладочный макрос
        macro brk { xchg bx, bx }

        org 0xc000
        call installer

        ; 1 Вход в защищенный режим
        jmp enter_pm ; [system/pm.asm]

; С этого момента стартует операционная система в защищенном режиме
; -----------------------------------------------------------------------------------------------------------------

        include "system/pm.asm"
        include "install/install.asm"

        use32        
        include "system/pm.general.asm"             ; общие функций для управления защищенным режимом
        include "system/keyboard/keyb.asm"          ; доступ к VGA     
        include "system/vga/vga.asm"                ; работа с клавиатурой
        include "system/interrupts.asm"             ; список с системными прерываниями
        include "system/mem/memory.asm"             ; работа с памятью
        include "system/stdlib.asm"                 ; различные конвертации

        include "system/ata/ide.asm"                ; системные процедуры для работы с дисками
        include "system/fs/fat32.asm"               ; файловая система fat32

        include "system/debug/main.asm"             ; отладочные модули
        
start_operation_system:

        ; Загружаем в TR сегмент TSS
        ; По сути это указание процессору, откуда брать данные при различного рода
        ; операциях в мультизадачном режиме

        mov ax,  18h
        ltr ax

        ; Загрузка сегментов для защищенного режима
        mov ax,  10h
        mov es,  ax
        mov ds,  ax
        mov ss,  ax
        mov esp, 0x200000 ; новый стек на 2-м мегабайте

        ; Очистить память
        xor eax, eax
        mov edi, 0
        mov ecx, 0x8000 / 4
        rep stosd

        ; Определение битовой маски и перенос IRQ на [0x20-0x27], [0x28-0x2F]
        mov  bx, 1110111111111000b
        call irq_redirect                 ; [system/pm.general.asm] Битовая маска на irq
        call timer_set                    ; [system/pm.general.asm] 100 Hz системный таймер
        call set_interrupt_list           ; [system/interrupts.asm] Установка шлюзов прерываний
        call enable_paging                ; [system/mem/memory.asm] Включение механизма страничной адресации
        call vga_320x200                  ; [system/vga/vgamodes.asm] Установить минимальное разрешение экрана

        call global_disk_identity         ; [system/ide.asm] Проверка дисков
        call search_filesystems           ; [system/fs/fat32.sam] Поиск файловых систем

        ; Закрасить рабочий стол в черный цвет
        mov edi, 0xa0000
        mov al,  0x00
        mov ecx, 320*200   
        rep stosb

        ; -----------------------------------------------------------------------
        ; Рабочий режим ОС
        ; -----------------------------------------------------------------------

        sti

        ; режим клавиш
        mov [keyb_query], byte 0 ; вкл/выкл буфера
       
;brk
        mov bx, 0x0001
        mov ax, 0x0700

        mov esi, const_FS_LIST 
        mov ecx, 200

.aa:
        push ecx

        lodsb
        call dbg_print_hex
        mov al, ' '
        call put_char_low
        mov al, ' '
        call put_char_low
        mov al, ' '
        call put_char_low

        pop ecx

        loop .aa
        

        ; сделать встроенный дизассемблер, чтобы отлаживать прямо из системы

        jmp $
       
t:      db "Нужно чтобы операционная система", 0
t1:     db "Загрузка операционной системы в мозг", 0
