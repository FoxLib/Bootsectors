;
; Это - основной графический интерфейс NanoX для NanoDOS
; ----------------------------------------------------------------------
; В 2003-м году, в декабре, я написал собственную ОС в реальном режиме
; с тех пор, я так и не смог побить собственный рекорд и написать что-то
; лучше. У меня появилась идея создать сначала NanoDOS (Int 21h), чтобы
; написать для него оболочку. Идти от малого - к большому, вот моя цель.
; ----------------------------------------------------------------------
; Эта оболочка инициализирует мышь, кодовую страницу CP866 для программ,
; управляет "многозадачностью", и обрабатывает графический режим VGA.
; ----------------------------------------------------------------------

; http://wiki.osdev.org/CMOS#Accessing_CMOS_Registers

        macro   brk { xchg bx, bx }
        org     100h

        cli
        mov     sp, 0100h

        ; Инициализировать мышь до установки видеорежима
        call    PS2Mouse.Init
        
        ; Загрузить иконки (мой компьютер, мои документы, корзина)
        call    desktop.Images
        call    desktop.LoadIcons
        call    desktop.Tahoma.Load

        ; Видеорежим VGA 640x480
        call    [SetDefaultVideoMode]
        call    [Desktop.Repaint]
        call    PS2Mouse.Show
        sti

; ----------------------------------------------------------------------
.osloop:; Главный цикл системы
        
        ; Второй клик не учитывать, ждать        
        call    desktop.UpdateIcons
        call    desktop.ProgramStart

        jmp     .osloop

testp   db 'demo/tube.com', 0

; ----------------------------------------------------------------------
; Библиотеки
; ----------------------------------------------------------------------

        include "param.asm"
        include "xms.asm"
        include "desktop/images.asm"
        include "desktop/repaint.asm"
        include "desktop/tahoma.asm"
        include "desktop/program_start.asm"

        include "gdi/button.asm"
        include "gdi/load_bmp.asm"
        include "gdi/draw_bitmap.asm"

        include "vgalib.asm"
        include "ps2mouse.asm"
        include "reloc.asm"

tmpdisk: ; Временные данные чтения с диска
