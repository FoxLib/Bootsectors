include 'bootstrap.asm'          ; Базовый код ядра
include 'interrupts.asm'         ; Обработчики прерываний
include 'irq.asm'                ; Обработчики IRQ
include 'memory.asm'             ; Работа с памятью
include 'formatext.asm'          ; Системные функции для вывода форматированного текста

include 'mouse/ps2.asm'          ; PS/2 мышь
include 'fs/ata.asm'             ; ATA-драйвер
include 'video/vga.asm'          ; Драйвер VGA

include 'fpu.asm'                ; Набор операциии с FPU
