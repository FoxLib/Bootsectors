; Light Midnight Commander

include "video/palette.asm"
include "const.asm"

; Главное приложение 
main_application:

    ; Установка видеорежима 640x480x16
    call vga_12
    
	; Установка палитры
    call set_palette_16
    
    ;; ++ шрифты 4x8 добавить
    
	; 320x200
    ;mov edi, 0xa0000
    ;mov al,  0x1
    ;mov ecx, 320*200
    ;rep stosb

    ; Просто выдача
	invk5 vga_rectangle,0,0,639,479,1
    invk4 vga_print_mono,1,8,const_mc.sz1,15

    ; Создание в памяти виртуального диска с виртуальной FS
    ; Показать 2 панели
    ; Навигация
    ; Создание, открытие и редактирование файлов
    ; Дизассемблирование
    ; Ассемблирование
    ; Работа с виртуальной файловой системой FAT16
    ; Реальная файловая система
    
    sti

    jmp $


