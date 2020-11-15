
        org     0
        macro   brk {  xchg    bx, bx }
        
        ; -------------------
        
        ; Очистить экран
        call    text.cls
        
        ; Нарисовать фрейм
        mov     ax, 0x050F
        mov     bx, 0x1441
        call    text.frame

        ; Выдать сообщение наверху
        mov     ax, 0x0510
        mov     si, message.title
        call    text.print

        ; Подсветить сообщение
        mov     ax, 0x0510
        mov     cx, 0x0716
        call    text.line
        
        ; -------------------

        mov     si, menu.container        
        mov     bp, 0x0711
@@:     lodsw
        and     ax, ax
        je      @f
        
        push    si
        mov     si, ax
        mov     ax, bp        
        call    text.print
        pop     si
        add     bp, 100h
        jmp     @b
@@:        
        
        ; Подсветка текущего
        mov     ax, 0x0710
        mov     cx, 0x4731
        call    text.line
        
        jmp     $

; ----------------------------------------------------------------------

message.title   db ' FLOPPY DREAM 2000/11 ', 0

menu.container  dw menu.line1
                dw menu.line2
                dw menu.line3
                dw 0
                
menu.line1      db 'README', 0
menu.line2      db 'ZX Spectrum Experience', 0
menu.line3      db 'Homebrew BASIC', 0

; ----------------------------------------------------------------------

include "func/text_cls.asm"
include "func/text_frame.asm"
include "func/text_print.asm"
include "func/text_line.asm"
