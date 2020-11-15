;
; Рисовать кнопку на экране
; (si, di) - (cx, dx)
; 
; AL=0 Не нажатая кнопка
; AL=1 Нажатая
; AL=2 Не нажая выделенная
; AL=3 Нажатая выделенная

gdi.Button:

        ; Верхняя
        push    dx
        mov     al, 15
        mov     dx, di
        call    [FillRectangle]
        pop     dx
        
        ; Левая
        push    cx
        mov     cx, si
        call    [FillRectangle]
        pop     cx
        
        ; Нижняя
        push    di
        mov     di, dx
        mov     al, 0
        call    [FillRectangle]
        pop     di
        
        ; Правая
        push    si
        mov     si, cx
        call    [FillRectangle]
        pop     si
        
        dec     cx
        dec     dx
        inc     si
        inc     di
        
        ; Нижняя (темно-серая)
        push    di
        mov     di, dx
        mov     al, 8
        call    [FillRectangle]
        pop     di
        
        ; Правая (темно-серая)
        push    si
        mov     si, cx
        call    [FillRectangle]
        pop     si
        ret
        
