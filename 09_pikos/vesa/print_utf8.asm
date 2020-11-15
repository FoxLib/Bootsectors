;
; Печать UTF-8 строки
;

; ----------------------------------------------------------------------
; esi - источник
; информация о x | y | color находится в:
;
; dw vesa.systerm_x
; dw vesa.systerm_y
; dw vesa.color

vesa.PrintUTF8:

        ret

; ----------------------------------------------------------------------
; Печать символа на экране
; al - Символ, edi - стартовая точка (0...кол-во пикселей - 1)
; ch = 8, cl = 8 Строк x Столбцов на символ

vesa.PrintChar:
        
        pusha        
        mov     ebx, [vesa.linear]
        and     eax, 00FFh
        lea     esi, [sysfont + 8*eax]        
        xor     ecx, ecx
        mov     dx, [vesa.color]        
        mov     ch, 8
.h:     mov     cl, 8
        lodsb
        push    edi
.w:     test    al, 80h
        je      .s
        ; + тестирование лимитов
        mov     [ebx + 2*edi], dx
.s:     shl     al, 1
        inc     edi
        dec     cl
        jne     .w
        pop     edi
        mov     eax, [vesa.width]
        add     edi, eax
        dec     ch
        jne     .h
        popa
        ret        
