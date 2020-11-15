; Список процедур и функции
;
; vesa.Clear()
; vesa.Pixel(ESI x, EDI y, AX color)
; vesa.Block(ESI x1, EDI y1, ECX x2, EBX y2, AX color)
; vesa.RGB(EAX rgb)

; ----------------------------------------------------------------------
; Очистить весь экран в цвет vesa.clear_color

vesa.Clear:

        movzx   ebx, word [vesa.width]
        movzx   ecx, word [vesa.height]
        imul    ecx, ebx
        mov     edi, [vesa.linear]
        rep     stosw
        ret        

; ----------------------------------------------------------------------
; Нарисовать пиксель в точке esi (x) / edi (y), цвет в ax

vesa.Pixel:

        push    ebx
        mov     ebx, [vesa.height]
        cmp     edi, ebx            ; y >= 0 && y < height
        jnb     .not
        mov     ebx, [vesa.width]
        cmp     esi, ebx            ; x >= 0 && x < width
        jnb     .not
        imul    ebx, edi
        add     ebx, esi
        add     ebx, ebx
        add     ebx, [vesa.linear]
        mov     [ebx], ax
.not:   pop     ebx
        ret

; ----------------------------------------------------------------------
; Рисование независимого блока
; esi(x1), edi(y1) - ecx(x2), edx(y2) : ax(color)

vesa.Block:

        ret

; ----------------------------------------------------------------------
; Конвертация 24-х битного цвета в 16-битный
; (EAX) A8.R8.G8.B8 => (AX) R5:G6:B5

vesa.RGB:

        mov     cl, ah      ; Установка G
        shl     cx, 3
        and     cx, 07E0h
        shr     al, 3       ; Установка B
        and     ax, 001Fh
        or      cx, ax      ; Объединить G & B 
        shr     eax, 8      ; Установка R
        and     ah, 0F8h
        or      ah, ch
        mov     al, cl
        ret

