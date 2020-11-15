
        include "macro.asm"
        include "strings.asm"
        include "paint.asm"
        include "controls.asm"

; ------------------------------------
; Встроенный в ОС файловый менеджер
; ------------------------------------

commander_data:

.menu_select db 0, 0, 2 ; начальная позиция, старт, конец

        ; == загрузка всех данных из папки boot/ на флешке в виртуальную память ==       

commander_main:

        ; Рисование начального экрана
        ivk3 paint_box, 0x0000, 0x174F, 0x1720
        ivk3 paint_box, 0x1800, 0x184F, 0x3020        
        ivk2 paint_text, 0x1801, strmain.menu

        ; Вывод текста
        ivk2 paint_text, 0x0101, strmain.welcome1
        ivk2 paint_text, 0x0201, strmain.welcome0
        ivk2 paint_text, 0x0301, strmain.welcome1
        ivk2 paint_text, 0x0501, strmain.welcome2
        ivk2 paint_text, 0x0601, strmain.welcome3

.menu_redraw:

        ; Рисование окна
        ivk3 paint_box, 0x080C, 0x0F42, 0x7020  ; Подложка

        ; Выбор области подсветки
        mov ax, 0x0D19
        mov bx, 0x0D1C
        cmp [commander_data.menu_select], byte 0
        je .show_menu

        mov ax, 0x0D22
        mov bx, 0x0D27
        cmp [commander_data.menu_select], byte 1
        je .show_menu

        mov ax, 0x0D2D
        mov bx, 0x0D33

.show_menu:

        ; Высветить меню
        ivk3 paint_box, ax, bx, 0x4720  

        ivk2 paint_frame, 0x080C, 0x0942       
        ivk2 paint_text, 0x080E, strmain.frame1
        ivk2 paint_text, 0x0A0E, strmain.frame2
        ivk2 paint_text, 0x0D18, strmain.frame3

        ; Ожидание нажатия клавиш
        mov si, commander_data.menu_select
        call key_interaction

        jmp .menu_redraw
